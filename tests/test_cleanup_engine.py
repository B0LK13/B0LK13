"""Tests for CleanupEngine."""
from __future__ import annotations

import logging
from pathlib import Path

from file_organizer.engines.cleanup_engine import CleanupEngine


def test_remove_empty_directories(tmp_path: Path) -> None:
    """Ensure empty directories are removed."""

    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    nested_empty = tmp_path / "nested" / "empty"
    nested_empty.mkdir(parents=True)

    non_empty_dir = tmp_path / "non_empty"
    non_empty_dir.mkdir()
    (non_empty_dir / "file.txt").write_text("content")

    logger = logging.getLogger("cleanup_test")
    engine = CleanupEngine(logger)

    removed = engine.remove_empty_directories(tmp_path)

    assert removed == 3
    assert not empty_dir.exists()
    assert not nested_empty.exists()
    assert not (tmp_path / "nested").exists()
    assert non_empty_dir.exists()
