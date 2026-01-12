"""Engine for determining structure and moving files."""
from __future__ import annotations

import logging
import shutil
from pathlib import Path
from typing import Dict, Iterable, List

from file_organizer.core.models import FileObject


class OrganizationEngine:
    """Determines target structure and moves files."""

    def __init__(
        self,
        logger: logging.Logger,
        confidence_threshold: float,
        staging_dir_name: str,
    ) -> None:
        """Initialize the organization engine.

        Args:
            logger: Logger instance.
            confidence_threshold: Threshold below which files are staged.
            staging_dir_name: Name for staging directory.
        """

        self.logger = logger
        self.confidence_threshold = confidence_threshold
        self.staging_dir_name = staging_dir_name

    def determine_category(self, file_object: FileObject) -> Path:
        """Determine category path based on metadata and labels.

        Args:
            file_object: FileObject to categorize.

        Returns:
            Relative path for destination.
        """

        mime_type = file_object.mime_type
        label = file_object.labels[0] if file_object.labels else "uncategorized"
        extension = file_object.path.suffix.lower()

        if mime_type.startswith("image/"):
            return Path("Media") / "Photos"
        if mime_type.startswith("video/"):
            return Path("Media") / "Videos"
        if mime_type.startswith("audio/"):
            return Path("Media") / "Audio"
        if mime_type in {"application/pdf"}:
            return Path("Documents") / "PDFs"
        if extension in {".py", ".js", ".ts", ".java", ".go", ".rb"}:
            return Path("Code") / "Scripts"
        if mime_type.startswith("text/"):
            return Path("Documents") / "Text"
        return Path("Documents") / label.title()

    def organize_files(self, root: Path, files: Iterable[FileObject]) -> Dict[str, int]:
        """Move files into the determined structure.

        Args:
            root: Root directory for organization.
            files: Iterable of FileObject instances.

        Returns:
            Summary counts for moved and staged files.
        """

        summary = {"moved": 0, "staged": 0}
        staging_root = root / self.staging_dir_name
        staging_root.mkdir(parents=True, exist_ok=True)

        for file_object in files:
            if file_object.errors or file_object.confidence_score < self.confidence_threshold:
                destination_dir = staging_root
                summary["staged"] += 1
                reason = "errors" if file_object.errors else "low_confidence"
                self.logger.info("STAGING (%s): %s", reason, file_object.path)
            else:
                destination_dir = root / self.determine_category(file_object)
                summary["moved"] += 1

            destination_dir.mkdir(parents=True, exist_ok=True)
            destination = destination_dir / file_object.path.name
            if destination == file_object.path:
                self.logger.info("SKIP MOVE (already placed): %s", destination)
                continue
            try:
                shutil.move(str(file_object.path), str(destination))
                file_object.target_path = destination
                self.logger.info("MOVED: %s -> %s", file_object.path, destination)
            except PermissionError as exc:
                self.logger.warning("PERMISSION ERROR moving %s: %s", file_object.path, exc)
            except Exception as exc:  # pragma: no cover - safety net
                self.logger.error("MOVE ERROR %s: %s", file_object.path, exc)
        return summary
