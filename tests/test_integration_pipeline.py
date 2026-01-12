"""Integration test for full pipeline."""
from __future__ import annotations

import os
from pathlib import Path

from file_organizer.main import run_pipeline


def test_full_pipeline(tmp_path: Path) -> None:
    """Run the pipeline and verify files moved."""

    (tmp_path / "empty_dir").mkdir()
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    text_file = docs_dir / "notes.txt"
    text_file.write_text("Project notes about quarterly planning and finance.")

    image_dir = tmp_path / "images"
    image_dir.mkdir()
    image_file = image_dir / "photo.jpg"
    image_file.write_bytes(b"\xff\xd8\xff\xe0" + b"0" * 10)

    bad_file = tmp_path / "mystery.bin"
    bad_file.write_bytes(b"")

    run_pipeline(
        tmp_path,
        confidence_threshold=70.0,
        staging_dir_name="_UNKNOWN_NEEDS_REVIEW",
        log_dir=tmp_path,
        learning_state_path=tmp_path / ".file_organizer_learning.json",
    )

    staging_dir = tmp_path / "_UNKNOWN_NEEDS_REVIEW"
    assert staging_dir.exists()
    assert any(path.name == "mystery.bin" for path in staging_dir.glob("*"))

    media_dir = tmp_path / "Media" / "Photos"
    docs_target = tmp_path / "Documents" / "Text"
    assert media_dir.exists()
    assert docs_target.exists()
    assert any(path.name == "photo.jpg" for path in media_dir.glob("*"))
    assert any(path.name == "notes.txt" for path in docs_target.glob("*"))
