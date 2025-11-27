"""Scrapy spider for eBay Buy-It-Now and Ending-Soonest listings."""

from __future__ import annotations

import urllib.parse
from datetime import datetime
from typing import Iterable, List

import scrapy
from bs4 import BeautifulSoup


class MarketplaceSpider(scrapy.Spider):
    """Abstract helper for marketplace spiders to share utilities."""

    marketplace_name: str = ""

    def sanitize_text(self, text: str) -> str:
        return (text or "").strip()


class EbaySpider(MarketplaceSpider):
    name = "ebay_koopjesjager"
    marketplace_name = "eBay"
    allowed_domains = ["www.ebay.com", "ebay.com"]

    custom_settings = {
        "ROBOTSTXT_OBEY": True,
        "DOWNLOAD_DELAY": 1.0,
        "CONCURRENT_REQUESTS": 8,
        "USER_AGENT": "Koopjesjager/1.0 (+https://example.com)",
        "PLAYWRIGHT_BROWSER_TYPE": "chromium",
        "PLAYWRIGHT_DEFAULT_NAVIGATION_TIMEOUT": 30_000,
    }

    def __init__(self, keywords: Iterable[str], pages: int = 1, sort: str = "best_deals", *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.keywords: List[str] = list(keywords)
        self.pages = int(pages)
        self.sort = sort

    def start_requests(self):
        for keyword in self.keywords:
            for page in range(1, self.pages + 1):
                params = {
                    "_nkw": keyword,
                    "_sop": "1" if self.sort == "ending_soonest" else "15",
                    "rt": "nc",
                    "LH_BIN": 1,
                    "_pgn": page,
                }
                url = "https://www.ebay.com/sch/i.html?" + urllib.parse.urlencode(params)
                yield scrapy.Request(
                    url,
                    callback=self.parse_search,
                    cb_kwargs={"keyword": keyword},
                    meta={"playwright": True},
                )

    def parse_search(self, response: scrapy.http.Response, keyword: str):
        soup = BeautifulSoup(response.text, "html.parser")
        for card in soup.select("li.s-item"):
            title_el = card.select_one("h3.s-item__title")
            price_el = card.select_one("span.s-item__price")
            url_el = card.select_one("a.s-item__link")
            if not (title_el and price_el and url_el):
                continue

            listing_id = url_el.get("href", "").split("/")[-1].split("?")[0]
            price_text = price_el.get_text(strip=True)
            price_value = price_text.replace("US $", "").replace("$", "").split(" ")[0]

            yield {
                "listing_id": listing_id,
                "platform": "eBay",
                "title": title_el.get_text(strip=True),
                "description_snippet": (card.select_one("div.s-item__subtitle") or {}).get_text(strip=True)
                if card.select_one("div.s-item__subtitle")
                else "",
                "price_currency": "USD",
                "price_value": price_value,
                "condition": (card.select_one("span.SECONDARY_INFO") or {}).get_text(strip=True)
                if card.select_one("span.SECONDARY_INFO")
                else "Unknown",
                "location": (card.select_one("span.s-item__location") or {}).get_text(strip=True)
                if card.select_one("span.s-item__location")
                else "",
                "post_date": datetime.utcnow().isoformat(),
                "url": url_el.get("href"),
                "keyword": keyword,
            }
