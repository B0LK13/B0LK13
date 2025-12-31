"""Data models for the file organization utility."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional


@dataclass
class FileObject:
    """Represents a file undergoing processing.

    Attributes:
        path: Original path to the file.
        mime_type: Detected MIME type string.
        metadata: Extracted metadata values.
        labels: Generated labels for organization.
        confidence_score: Confidence score for labels.
        is_consistent: Flag indicating filename and title consistency.
        target_path: Computed destination path.
        errors: List of errors encountered while processing.
    """

    path: Path
    mime_type: str
    metadata: Dict[str, str] = field(default_factory=dict)
    labels: List[str] = field(default_factory=list)
    confidence_score: float = 0.0
    is_consistent: bool = True
    target_path: Optional[Path] = None
    errors: List[str] = field(default_factory=list)
