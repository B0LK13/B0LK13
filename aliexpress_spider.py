"""Scrapy spider for AliExpress keyword searches."""

from __future__ import annotations

import urllib.parse
from datetime import datetime
from typing import Iterable, List

import scrapy
from bs4 import BeautifulSoup

from ebay_spider import MarketplaceSpider


class AliExpressSpider(MarketplaceSpider):
    name = "aliexpress_koopjesjager"
    marketplace_name = "AliExpress"
    allowed_domains = ["www.aliexpress.com", "aliexpress.com"]

    custom_settings = {
        "ROBOTSTXT_OBEY": True,
        "DOWNLOAD_DELAY": 1.2,
        "CONCURRENT_REQUESTS": 6,
        "USER_AGENT": "Koopjesjager/1.0 (+https://example.com)",
        "PLAYWRIGHT_BROWSER_TYPE": "chromium",
        "PLAYWRIGHT_DEFAULT_NAVIGATION_TIMEOUT": 40_000,
    }

    def __init__(self, keywords: Iterable[str], pages: int = 1, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.keywords: List[str] = list(keywords)
        self.pages = int(pages)

    def start_requests(self):
        for keyword in self.keywords:
            slug = keyword.replace(" ", "-")
            for page in range(1, self.pages + 1):
                params = {"g": "y", "SearchText": keyword}
                if page > 1:
                    params["page"] = page
                url = (
                    f"https://www.aliexpress.com/w/wholesale-{urllib.parse.quote(slug)}.html?"
                    + urllib.parse.urlencode(params)
                )
                yield scrapy.Request(
                    url,
                    callback=self.parse_search,
                    cb_kwargs={"keyword": keyword},
                    meta={"playwright": True},
                )

    def parse_search(self, response: scrapy.http.Response, keyword: str):
        soup = BeautifulSoup(response.text, "html.parser")
        seen: set[str] = set()

        for card in soup.select("a[data-product-id]"):
            listing_id = card.get("data-product-id")
            if not listing_id or listing_id in seen:
                continue
            seen.add(listing_id)

            title_el = card.select_one(".multi--titleText--nXeOvyr, .card--title--3jwA8mB") or card
            price_el = card.select_one(
                ".multi--price-sale--U-S0jtj, .cards--price-final--2J6c1HL, .search-card-item-price"
            )

            title = self.sanitize_text(title_el.get_text())
            raw_price = self.sanitize_text(price_el.get_text()) if price_el else ""
            if not raw_price:
                continue
            price_value = raw_price.replace("US $", "").replace("$", "").replace(",", "")

            href = card.get("href", "")
            url = href
            if href.startswith("//"):
                url = "https:" + href
            elif href.startswith("/"):
                url = "https://www.aliexpress.com" + href

            yield {
                "listing_id": listing_id,
                "platform": self.marketplace_name,
                "title": title,
                "description_snippet": "",
                "price_currency": "USD" if "$" in raw_price else "EUR",
                "price_value": price_value,
                "condition": "New",
                "location": "International",
                "post_date": datetime.utcnow().isoformat(),
                "url": url,
                "keyword": keyword,
            }
