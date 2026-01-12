"""Tests for MetadataProcessor."""
from __future__ import annotations

import logging
from pathlib import Path

from file_organizer.core.learning import LearningStore
from file_organizer.engines.metadata_processor import MetadataProcessor


def test_generate_labels_from_content(tmp_path: Path) -> None:
    """Ensure labels and confidence are generated when metadata is missing."""

    file_path = tmp_path / "example.txt"
    file_path.write_text("This document talks about finance budgets and forecasts.")

    logger = logging.getLogger("metadata_test")
    processor = MetadataProcessor(logger)

    file_object = processor.process_file(file_path)

    assert file_object.labels
    assert file_object.confidence_score > 0


def test_validate_filename_consistency(tmp_path: Path) -> None:
    """Ensure filename consistency check works."""

    file_path = tmp_path / "report.txt"
    file_path.write_text("Report content")

    logger = logging.getLogger("metadata_consistency")
    processor = MetadataProcessor(logger)

    result = processor.validate_filename(file_path, {"title": "report"})

    assert result is True


def test_learning_store_suggestions(tmp_path: Path) -> None:
    """Ensure learned labels boost confidence and fill missing labels."""

    file_path = tmp_path / "diagram.png"
    file_path.write_bytes(b"\x89PNG\r\n\x1a\n")

    learning_store = LearningStore(
        extension_labels={".png": {"design": 3}},
        mime_labels={},
    )

    logger = logging.getLogger("metadata_learning")
    processor = MetadataProcessor(logger, learning_store=learning_store)

    file_object = processor.process_file(file_path)

    assert "design" in file_object.labels
    assert file_object.confidence_score >= 70.0
