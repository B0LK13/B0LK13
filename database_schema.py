"""SQLAlchemy models for Koopjesjager listings."""

from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, Text, Index
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Listing(Base):
    __tablename__ = "listings"

    listing_id = Column(String, primary_key=True)
    platform = Column(String(50), nullable=False)
    title = Column(String(255), nullable=False)
    description_snippet = Column(Text)
    price_currency = Column(String(3), nullable=False)
    price_value = Column(Float, nullable=False)
    condition = Column(String(50), nullable=False)
    location = Column(String(255))
    post_date = Column(DateTime, default=datetime.utcnow, nullable=False)
    url = Column(String(500), nullable=False, unique=True)

    __table_args__ = (
        Index("idx_platform_title", "platform", "title"),
        Index("idx_platform_postdate", "platform", "post_date"),
    )

    def __repr__(self) -> str:  # pragma: no cover - debugging helper
        return f"<Listing {self.platform}:{self.listing_id} {self.title[:20]!r}>"
