"""File scanning utility for directory traversal."""
from __future__ import annotations

from pathlib import Path
from typing import Iterable, List


class FileScanner:
    """Handles directory traversal and file listing."""

    def scan(self, root: Path, exclude_dirs: Iterable[Path]) -> List[Path]:
        """Scan for files under root.

        Args:
            root: Root directory to scan.
            exclude_dirs: Directories to exclude from scanning.

        Returns:
            List of file paths found.
        """

        excluded = {path.resolve() for path in exclude_dirs}
        files: List[Path] = []
        for path in root.rglob("*"):
            if path.is_dir():
                continue
            if any(parent.resolve() in excluded for parent in path.parents):
                continue
            if path.name.startswith("cleanup_report_") and path.suffix == ".log":
                continue
            if path.name == ".file_organizer_learning.json":
                continue
            files.append(path)
        return files
