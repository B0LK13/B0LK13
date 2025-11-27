"""Entrypoint for Koopjesjager scraping, persistence, and reporting."""

from __future__ import annotations

import argparse
import logging
from pathlib import Path
from typing import Any, Dict

import yaml
from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings

from ebay_spider import EbaySpider
from facebook_marketplace_spider import FacebookMarketplaceSpider
from pipelines import DataCleaningPipeline, DatabasePipeline, QualityFilterPipeline, send_email_report

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def load_config(config_path: Path) -> Dict[str, Any]:
    with open(config_path, "r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def build_settings(config: Dict[str, Any], database_url: str) -> Any:
    settings = get_project_settings()
    settings.set("ITEM_PIPELINES", {
        DataCleaningPipeline: 300,
        QualityFilterPipeline: 400,
        DatabasePipeline: 500,
    })
    settings.set("DATABASE_URL", database_url)
    settings.set("SCAM_TERMS", config.get("filters", {}).get("scam_terms", []))
    settings.set("LOW_PRICE_THRESHOLD", config.get("filters", {}).get("low_price_threshold", 0.1))
    price_band = config.get("search", {}).get("price_eur", {})
    settings.set("MIN_PRICE_EUR", price_band.get("min"))
    settings.set("MAX_PRICE_EUR", price_band.get("max"))
    settings.set("DOWNLOAD_HANDLERS", {"https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler"})
    settings.set("TWISTED_REACTOR", "twisted.internet.asyncioreactor.AsyncioSelectorReactor")
    settings.set("PLAYWRIGHT_BROWSER_TYPE", "chromium")
    settings.set("ROBOTSTXT_OBEY", True)
    return settings


def main():
    parser = argparse.ArgumentParser(description="Run Koopjesjager spiders")
    parser.add_argument("--config", default="config.yaml", help="Path to config file")
    parser.add_argument("--database", default="sqlite:///koopjesjager.db", help="Database URL")
    args = parser.parse_args()

    config = load_config(Path(args.config))
    settings = build_settings(config, args.database)

    process = CrawlerProcess(settings)

    search_cfg = config.get("search", {})
    keywords = search_cfg.get("keywords", [])
    pages = config.get("platforms", {}).get("ebay", {}).get("pages", 1)
    sort = config.get("platforms", {}).get("ebay", {}).get("sort", "best_deals")

    platform_cfg = config.get("platforms", {})

    if platform_cfg.get("ebay", {}).get("enabled", True):
        process.crawl(EbaySpider, keywords=keywords, pages=pages, sort=sort)

    fb_cfg = platform_cfg.get("facebook_marketplace", {})
    if fb_cfg.get("enabled"):
        fb_pages = fb_cfg.get("pages", 1)
        fb_location = fb_cfg.get("location_id")
        radius_km = fb_cfg.get("radius_km")
        if fb_location:
            process.crawl(
                FacebookMarketplaceSpider,
                keywords=keywords,
                pages=fb_pages,
                location_id=fb_location,
                radius_km=radius_km,
            )

    process.start()

    smtp_cfg = config.get("notifications", {}).get("email", {})
    send_email_report(args.database, smtp_cfg)


if __name__ == "__main__":
    main()
