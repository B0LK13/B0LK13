"""Item pipelines for Koopjesjager scraping project."""

from __future__ import annotations

import logging
import smtplib
from collections import defaultdict
from datetime import datetime
from email.mime.text import MIMEText
from typing import Any, Dict, Iterable, Optional

import pandas as pd
from dateutil import parser as date_parser
from scrapy.exceptions import DropItem
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

from database_schema import Base, Listing

logger = logging.getLogger(__name__)


class DataCleaningPipeline:
    """Normalize scraped fields for downstream filters and storage."""

    def process_item(self, item: Dict[str, Any], spider):
        item = dict(item)
        item["title"] = item.get("title", "").strip()
        description = item.get("description_snippet", "") or ""
        item["description_snippet"] = description[:100]

        # Normalize price
        currency = item.get("price_currency", "").upper() or "USD"
        try:
            price_value = float(str(item.get("price_value", "")).replace(",", ""))
        except (TypeError, ValueError):
            raise ValueError(f"Unable to parse price for item {item}")
        item["price_currency"] = currency
        item["price_value"] = price_value

        # Parse dates
        post_date_raw = item.get("post_date")
        if isinstance(post_date_raw, str):
            try:
                item["post_date"] = date_parser.parse(post_date_raw)
            except (ValueError, TypeError) as exc:
                logger.warning("Failed to parse post_date %s: %s", post_date_raw, exc)
                item["post_date"] = datetime.utcnow()
        elif not post_date_raw:
            item["post_date"] = datetime.utcnow()

        # Basic condition normalization
        item["condition"] = (item.get("condition") or "Unknown").title()

        return item


class QualityFilterPipeline:
    """Discard obvious scams and unrealistic prices using a rolling median."""

    def __init__(
        self,
        scam_terms: Iterable[str],
        low_price_threshold: float,
        min_price_eur: Optional[float],
        max_price_eur: Optional[float],
    ):
        self.scam_terms = [term.lower() for term in scam_terms]
        self.low_price_threshold = low_price_threshold
        self.price_history: Dict[str, list[float]] = defaultdict(list)
        self.min_price_eur = float(min_price_eur) if min_price_eur is not None else None
        self.max_price_eur = float(max_price_eur) if max_price_eur is not None else None
        self.exchange_rates = {"USD": 0.92, "EUR": 1.0}

    @classmethod
    def from_crawler(cls, crawler):
        scam_terms = crawler.settings.getlist("SCAM_TERMS", [])
        low_threshold = crawler.settings.getfloat("LOW_PRICE_THRESHOLD", 0.1)
        min_price = crawler.settings.get("MIN_PRICE_EUR")
        max_price = crawler.settings.get("MAX_PRICE_EUR")
        return cls(scam_terms, low_threshold, min_price, max_price)

    def process_item(self, item: Dict[str, Any], spider):
        title_lower = item.get("title", "").lower()
        if any(term in title_lower for term in self.scam_terms):
            raise DropItem(f"Filtered scam term in title: {item['title']}")

        # Currency conversion for price band checking
        currency = item.get("price_currency", "EUR").upper()
        rate = self.exchange_rates.get(currency, 1.0)
        price_eur = item.get("price_value", 0.0) * rate
        if self.min_price_eur and price_eur < self.min_price_eur:
            raise DropItem(f"Price {price_eur} EUR below minimum {self.min_price_eur}")
        if self.max_price_eur and price_eur > self.max_price_eur:
            raise DropItem(f"Price {price_eur} EUR above maximum {self.max_price_eur}")

        key = item.get("platform", "generic") + ":" + (item.get("title", "")[:30].lower())
        price_value = item.get("price_value", 0.0)
        history = self.price_history[key]
        if price_value:
            history.append(price_value)

        if len(history) >= 3:
            median_price = float(pd.Series(history).median())
            if price_value < (median_price * self.low_price_threshold):
                raise DropItem(
                    f"Filtered low price {price_value} vs median {median_price} for {key}"
                )

        return item


class DatabasePipeline:
    """Persist validated listings into the configured database."""

    def __init__(self, database_url: str):
        self.database_url = database_url
        self.engine = create_engine(database_url)
        self.SessionLocal: Optional[sessionmaker[Session]] = None

    @classmethod
    def from_crawler(cls, crawler):
        db_url = crawler.settings.get("DATABASE_URL")
        if not db_url:
            raise RuntimeError("DATABASE_URL must be set in Scrapy settings")
        return cls(db_url)

    def open_spider(self, spider):
        Base.metadata.create_all(self.engine)
        self.SessionLocal = sessionmaker(bind=self.engine)

    def close_spider(self, spider):
        if self.engine:
            self.engine.dispose()

    def process_item(self, item: Dict[str, Any], spider):
        if self.SessionLocal is None:
            raise RuntimeError("Database session not initialized")
        session = self.SessionLocal()
        try:
            listing = Listing(**item)
            session.merge(listing)
            session.commit()
        except Exception:
            session.rollback()
            logger.exception("Failed to persist listing %s", item)
            raise
        finally:
            session.close()
        return item


def send_email_report(database_url: str, smtp_config: Dict[str, Any]) -> Optional[str]:
    """Send a Markdown email containing the top bargains.

    Returns the Markdown body for logging or testing convenience.
    """

    if not smtp_config.get("enabled", False):
        logger.info("Email notifications disabled; skipping report.")
        return None

    engine = create_engine(database_url)
    with engine.connect() as conn:
        df = pd.read_sql(select(Listing), conn)

    if df.empty:
        logger.info("No listings available to report.")
        return None

    df["price_ratio"] = df.groupby("title")["price_value"].transform(lambda x: x / x.mean())
    bargains = df.sort_values("price_ratio").head(10)

    markdown_lines = [
        "# Koopjesjager Daily Bargains",
        "",
        "| Platform | Title | Price | Condition | Location | Posted |",
        "| --- | --- | --- | --- | --- | --- |",
    ]

    for _, row in bargains.iterrows():
        markdown_lines.append(
            f"| {row['platform']} | {row['title']} | {row['price_currency']} {row['price_value']:.2f} "
            f"| {row['condition']} | {row.get('location','')} | {row['post_date']} |"
        )

    body = "\n".join(markdown_lines)

    msg = MIMEText(body)
    msg["Subject"] = "Koopjesjager Daily Report"
    msg["From"] = smtp_config["sender"]
    msg["To"] = ", ".join(smtp_config.get("recipients", []))

    with smtplib.SMTP(smtp_config["smtp_host"], smtp_config.get("smtp_port", 25)) as server:
        if smtp_config.get("username") and smtp_config.get("password"):
            server.starttls()
            server.login(smtp_config["username"], smtp_config["password"])
        server.send_message(msg)

    return body
