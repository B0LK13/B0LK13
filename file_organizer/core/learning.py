"""Self-healing learning store for label suggestions."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Tuple

from file_organizer.core.models import FileObject


@dataclass
class LearningStore:
    """Persisted label frequency store for self-healing suggestions."""

    extension_labels: Dict[str, Dict[str, int]] = field(default_factory=dict)
    mime_labels: Dict[str, Dict[str, int]] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "LearningStore":
        """Load a learning store from disk.

        Args:
            path: Path to the learning store JSON file.

        Returns:
            LearningStore instance.
        """

        if not path.exists():
            return cls()
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls(
            extension_labels=data.get("extension_labels", {}),
            mime_labels=data.get("mime_labels", {}),
        )

    def save(self, path: Path) -> None:
        """Save the learning store to disk.

        Args:
            path: Path to the learning store JSON file.
        """

        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "extension_labels": self.extension_labels,
            "mime_labels": self.mime_labels,
        }
        path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def suggest_labels(self, file_object: FileObject, limit: int = 3) -> Tuple[List[str], float]:
        """Suggest labels based on learned frequencies.

        Args:
            file_object: FileObject to suggest labels for.
            limit: Maximum number of labels to return.

        Returns:
            Tuple of label suggestions and confidence boost.
        """

        candidates: Dict[str, int] = {}
        extension = file_object.path.suffix.lower()
        mime_type = file_object.mime_type
        for label, count in self.extension_labels.get(extension, {}).items():
            candidates[label] = candidates.get(label, 0) + count
        for label, count in self.mime_labels.get(mime_type, {}).items():
            candidates[label] = candidates.get(label, 0) + count

        if not candidates:
            return [], 0.0

        sorted_labels = sorted(candidates, key=candidates.get, reverse=True)
        confidence_boost = min(20.0, float(candidates[sorted_labels[0]]) * 2.0)
        return sorted_labels[:limit], confidence_boost

    def update(self, file_object: FileObject) -> None:
        """Update store with finalized file labels.

        Args:
            file_object: FileObject with labels to record.
        """

        if not file_object.labels:
            return
        extension = file_object.path.suffix.lower()
        mime_type = file_object.mime_type
        primary_label = file_object.labels[0].lower()

        self.extension_labels.setdefault(extension, {})
        self.extension_labels[extension][primary_label] = (
            self.extension_labels[extension].get(primary_label, 0) + 1
        )

        self.mime_labels.setdefault(mime_type, {})
        self.mime_labels[mime_type][primary_label] = (
            self.mime_labels[mime_type].get(primary_label, 0) + 1
        )
