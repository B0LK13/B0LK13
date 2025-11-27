"""Base class placeholder for future local classifieds integrations."""

from __future__ import annotations

import scrapy


class LocalClassifiedsSpider(scrapy.Spider):
    """Abstract spider for localized marketplaces.

    Implementations should override :meth:`build_search_urls` and
    :meth:`parse_listing` to map platform-specific HTML into the Koopjesjager
    listing schema.
    """

    platform: str = "local"

    def build_search_urls(self):
        raise NotImplementedError

    def parse(self, response):
        raise NotImplementedError
