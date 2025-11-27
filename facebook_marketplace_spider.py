"""Scrapy spider for Facebook Marketplace searches."""

from __future__ import annotations

import urllib.parse
from datetime import datetime
from typing import Iterable, List

import scrapy
from bs4 import BeautifulSoup

from ebay_spider import MarketplaceSpider


class FacebookMarketplaceSpider(MarketplaceSpider):
    name = "facebook_marketplace_koopjesjager"
    marketplace_name = "Facebook Marketplace"
    allowed_domains = ["www.facebook.com", "facebook.com"]

    custom_settings = {
        "ROBOTSTXT_OBEY": True,
        "DOWNLOAD_DELAY": 1.5,
        "CONCURRENT_REQUESTS": 4,
        "USER_AGENT": "Koopjesjager/1.0 (+https://example.com)",
        "PLAYWRIGHT_BROWSER_TYPE": "chromium",
        "PLAYWRIGHT_DEFAULT_NAVIGATION_TIMEOUT": 45_000,
    }

    def __init__(
        self,
        keywords: Iterable[str],
        location_id: str,
        pages: int = 1,
        radius_km: int | None = None,
        *args,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.keywords: List[str] = list(keywords)
        self.location_id = location_id
        self.pages = int(pages)
        self.radius_km = radius_km

    def start_requests(self):
        for keyword in self.keywords:
            params = {"query": keyword}
            if self.radius_km:
                params["radius_km"] = self.radius_km
            for page in range(self.pages):
                if page:
                    params["exact"] = "false"
                    params["referral_code"] = f"page={page}"
                url = (
                    f"https://www.facebook.com/marketplace/{self.location_id}/search?"
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
        for link in soup.select('a[href^="/marketplace/item/"]'):
            href = link.get("href")
            if not href:
                continue
            listing_id = href.rstrip("/").split("/")[-1]
            if listing_id in seen:
                continue
            seen.add(listing_id)

            card = link.find_parent("div") or link
            title_el = card.find("span")
            price_el = card.find("span", string=lambda s: s and any(c.isdigit() for c in s))

            title = self.sanitize_text(title_el.get_text()) if title_el else ""
            price_text = self.sanitize_text(price_el.get_text()) if price_el else ""
            price_value = price_text.replace("€", "").replace("$", "").replace(",", ".")

            yield {
                "listing_id": listing_id,
                "platform": self.marketplace_name,
                "title": title,
                "description_snippet": "",
                "price_currency": "EUR" if "€" in price_text else "USD",
                "price_value": price_value,
                "condition": "Unknown",
                "location": self.location_id,
                "post_date": datetime.utcnow().isoformat(),
                "url": urllib.parse.urljoin("https://www.facebook.com", href),
                "keyword": keyword,
            }
