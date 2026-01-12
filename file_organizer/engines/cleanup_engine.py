"""Engine for removing empty directories."""
from __future__ import annotations

from pathlib import Path
import logging


class CleanupEngine:
    """Removes empty directories within a root path."""

    def __init__(self, logger: logging.Logger) -> None:
        """Initialize the cleanup engine.

        Args:
            logger: Logger instance for reporting.
        """

        self.logger = logger

    def remove_empty_directories(self, root: Path) -> int:
        """Remove empty directories under root.

        Args:
            root: Root directory to clean.

        Returns:
            Number of directories removed.
        """

        removed_count = 0
        directories = sorted(
            [path for path in root.rglob("*") if path.is_dir()],
            key=lambda p: len(p.parts),
            reverse=True,
        )

        for directory in directories:
            try:
                if not any(directory.iterdir()):
                    directory.rmdir()
                    removed_count += 1
                    self.logger.info("REMOVED EMPTY DIR: %s", directory)
            except PermissionError as exc:
                self.logger.warning("PERMISSION ERROR removing %s: %s", directory, exc)
        return removed_count
