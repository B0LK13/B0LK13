"""Logging utilities for the file organization utility."""
from __future__ import annotations

import logging
from pathlib import Path
from datetime import datetime
from typing import Optional


LOG_FORMAT = "%(asctime)s | %(levelname)s | %(name)s | %(funcName)s | %(message)s"


def setup_logger(log_dir: Path, name: str = "file_organizer") -> logging.Logger:
    """Configure and return a logger instance.

    Args:
        log_dir: Directory where the log file should be written.
        name: Logger name.

    Returns:
        Configured logger instance.
    """

    log_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"cleanup_report_{timestamp}.log"

    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    logger.handlers = []

    formatter = logging.Formatter(LOG_FORMAT)

    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    logger.info("Logger initialized. Output file: %s", log_file)
    return logger
