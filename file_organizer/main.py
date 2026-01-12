"""CLI entrypoint for the file organization utility."""
from __future__ import annotations

import argparse
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

from file_organizer.core.learning import LearningStore
from file_organizer.core.logger import setup_logger
from file_organizer.core.models import FileObject
from file_organizer.engines.cleanup_engine import CleanupEngine
from file_organizer.engines.metadata_processor import MetadataProcessor
from file_organizer.engines.organization_engine import OrganizationEngine
from file_organizer.file_scanner import FileScanner


CONFIDENCE_THRESHOLD = 70.0
STAGING_DIR_NAME = "_UNKNOWN_NEEDS_REVIEW"
LEARNING_STATE_FILENAME = ".file_organizer_learning.json"


@dataclass
class CommandContext:
    """Context object shared by commands."""

    root: Path
    logger_dir: Path
    confidence_threshold: float
    staging_dir_name: str
    logger: logging.Logger
    learning_store: LearningStore
    learning_state_path: Path


class Command:
    """Base command in the command pattern."""

    def execute(self, context: CommandContext) -> None:
        """Execute the command.

        Args:
            context: CommandContext with runtime configuration.
        """

        raise NotImplementedError


class CleanupCommand(Command):
    """Command for empty directory cleanup."""

    def execute(self, context: CommandContext) -> None:
        engine = CleanupEngine(context.logger)
        removed = engine.remove_empty_directories(context.root)
        context.logger.info("Cleanup completed. Removed %s empty directories.", removed)


class ScanCommand(Command):
    """Command for scanning files."""

    def __init__(self) -> None:
        self.files: List[Path] = []

    def execute(self, context: CommandContext) -> None:
        scanner = FileScanner()
        staging_dir = context.root / context.staging_dir_name
        self.files = scanner.scan(context.root, exclude_dirs=[staging_dir])
        context.logger.info("Scan completed. Found %s files.", len(self.files))


class ProcessCommand(Command):
    """Command for metadata processing."""

    def __init__(self, files: Iterable[Path]) -> None:
        self.files = list(files)
        self.file_objects: List[FileObject] = []

    def execute(self, context: CommandContext) -> None:
        processor = MetadataProcessor(context.logger, learning_store=context.learning_store)
        for file_path in self.files:
            self.file_objects.append(processor.process_file(file_path))
        context.logger.info("Processing completed for %s files.", len(self.file_objects))


class OrganizeCommand(Command):
    """Command for file organization."""

    def __init__(self, files: Iterable[FileObject]) -> None:
        self.files = list(files)

    def execute(self, context: CommandContext) -> None:
        engine = OrganizationEngine(
            context.logger,
            confidence_threshold=context.confidence_threshold,
            staging_dir_name=context.staging_dir_name,
        )
        summary = engine.organize_files(context.root, self.files)
        for file_object in self.files:
            if file_object.errors:
                continue
            if file_object.confidence_score < context.confidence_threshold:
                continue
            context.learning_store.update(file_object)
        context.learning_store.save(context.learning_state_path)
        context.logger.info("Organization summary: %s", summary)


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments.

    Returns:
        Parsed argparse namespace.
    """

    parser = argparse.ArgumentParser(description="File system cleanup and organization utility")
    parser.add_argument("root", type=Path, help="Root directory to process")
    parser.add_argument(
        "--confidence-threshold",
        type=float,
        default=CONFIDENCE_THRESHOLD,
        help="Minimum confidence score to avoid staging",
    )
    parser.add_argument(
        "--staging-dir-name",
        type=str,
        default=STAGING_DIR_NAME,
        help="Name of staging directory",
    )
    parser.add_argument(
        "--log-dir",
        type=Path,
        default=None,
        help="Directory for log output (defaults to root)",
    )
    parser.add_argument(
        "--learning-state-path",
        type=Path,
        default=None,
        help="Path for self-healing learning state (defaults to root)",
    )
    return parser.parse_args()


def run_pipeline(
    root: Path,
    confidence_threshold: float,
    staging_dir_name: str,
    log_dir: Path,
    learning_state_path: Path,
) -> None:
    """Run the cleanup, scan, process, and organize pipeline.

    Args:
        root: Root directory to process.
        confidence_threshold: Confidence threshold for staging.
        staging_dir_name: Name of staging directory.
        log_dir: Directory where logs are stored.
    """

    logger = setup_logger(log_dir)
    learning_store = LearningStore.load(learning_state_path)
    context = CommandContext(
        root=root,
        logger_dir=log_dir,
        confidence_threshold=confidence_threshold,
        staging_dir_name=staging_dir_name,
        logger=logger,
        learning_store=learning_store,
        learning_state_path=learning_state_path,
    )

    cleanup_command = CleanupCommand()
    cleanup_command.execute(context)

    scan_command = ScanCommand()
    scan_command.execute(context)

    process_command = ProcessCommand(scan_command.files)
    process_command.execute(context)

    organize_command = OrganizeCommand(process_command.file_objects)
    organize_command.execute(context)


def main() -> None:
    """CLI entrypoint."""

    args = parse_args()
    root = args.root.resolve()
    log_dir = args.log_dir or root
    learning_state_path = args.learning_state_path or (root / LEARNING_STATE_FILENAME)
    run_pipeline(
        root,
        args.confidence_threshold,
        args.staging_dir_name,
        log_dir,
        learning_state_path,
    )


if __name__ == "__main__":
    main()
