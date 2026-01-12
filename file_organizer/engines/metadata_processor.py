"""Engine for metadata extraction and label generation."""
from __future__ import annotations

import logging
import mimetypes
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from file_organizer.core.learning import LearningStore
from file_organizer.core.models import FileObject

try:
    import magic
except ImportError:  # pragma: no cover - optional dependency
    magic = None

try:
    from tika import parser
except ImportError:  # pragma: no cover - optional dependency
    parser = None

try:
    from sklearn.feature_extraction.text import TfidfVectorizer
except ImportError:  # pragma: no cover - optional dependency
    TfidfVectorizer = None


ESSENTIAL_METADATA_KEYS = ("title", "author", "created")


@dataclass
class MetadataResult:
    """Result container for metadata extraction."""

    metadata: Dict[str, str]
    content: str


class MetadataStrategy:
    """Base strategy for metadata extraction."""

    def extract(self, file_path: Path) -> MetadataResult:
        """Extract metadata and content from a file.

        Args:
            file_path: Path to the file.

        Returns:
            MetadataResult with metadata and content.
        """

        raise NotImplementedError


class DefaultStrategy(MetadataStrategy):
    """Fallback strategy using simple file reads and tika if available."""

    def extract(self, file_path: Path) -> MetadataResult:
        metadata: Dict[str, str] = {}
        content = ""
        if parser is not None:
            parsed = parser.from_file(str(file_path))
            metadata = {
                key.lower(): str(value)
                for key, value in (parsed.get("metadata") or {}).items()
                if value
            }
            content = parsed.get("content") or ""
        else:
            try:
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                content = ""
        return MetadataResult(metadata=metadata, content=content)


class MetadataProcessor:
    """Handles metadata extraction, validation, and labeling."""

    def __init__(self, logger: logging.Logger, learning_store: LearningStore | None = None) -> None:
        """Initialize the metadata processor.

        Args:
            logger: Logger instance.
        """

        self.logger = logger
        self.default_strategy = DefaultStrategy()
        self.learning_store = learning_store

    def detect_mime_type(self, file_path: Path) -> str:
        """Detect MIME type for a file.

        Args:
            file_path: Path to the file.

        Returns:
            MIME type string.
        """

        if magic is not None:
            detector = magic.Magic(mime=True)
            return detector.from_file(str(file_path))
        mime_type, _ = mimetypes.guess_type(file_path.name)
        return mime_type or "application/octet-stream"

    def extract_metadata(self, file_path: Path) -> MetadataResult:
        """Extract metadata and content using the default strategy.

        Args:
            file_path: Path to the file.

        Returns:
            MetadataResult from strategy.
        """

        return self.default_strategy.extract(file_path)

    def validate_filename(self, file_path: Path, metadata: Dict[str, str]) -> bool:
        """Validate filename against metadata title.

        Args:
            file_path: Path to the file.
            metadata: Extracted metadata.

        Returns:
            True if consistent or no title metadata.
        """

        title = metadata.get("title")
        if not title:
            return True
        expected = file_path.stem.lower().strip()
        actual = title.lower().strip()
        return expected == actual

    def generate_labels(self, content: str, metadata: Dict[str, str]) -> Tuple[List[str], float]:
        """Generate content-based labels and confidence score.

        Args:
            content: Extracted content.
            metadata: Extracted metadata.

        Returns:
            Tuple of labels and confidence score.
        """

        labels: List[str] = []
        confidence = 0.0

        metadata_labels = [
            value.lower()
            for key, value in metadata.items()
            if key in ESSENTIAL_METADATA_KEYS and value
        ]
        if metadata_labels:
            labels = metadata_labels[:5]
            confidence = 90.0
            return labels, confidence

        sample_text = " ".join(content.split())[:2000]
        if not sample_text:
            return labels, confidence

        if TfidfVectorizer is not None:
            vectorizer = TfidfVectorizer(stop_words="english", max_features=5)
            matrix = vectorizer.fit_transform([sample_text])
            labels = vectorizer.get_feature_names_out().tolist()
            weights = matrix.toarray()[0]
            confidence = min(100.0, float(weights.mean()) * 1000)
        else:
            words = [word.strip(".,!?:;()[]{}").lower() for word in sample_text.split()]
            words = [word for word in words if len(word) > 3]
            frequency: Dict[str, int] = {}
            for word in words:
                frequency[word] = frequency.get(word, 0) + 1
            labels = sorted(frequency, key=frequency.get, reverse=True)[:5]
            if labels:
                confidence = min(100.0, 50.0 + len(labels) * 10.0)
        return labels, confidence

    def process_file(self, file_path: Path) -> FileObject:
        """Process a file and produce a FileObject.

        Args:
            file_path: Path to the file.

        Returns:
            FileObject with metadata and labels.
        """

        mime_type = self.detect_mime_type(file_path)
        file_object = FileObject(path=file_path, mime_type=mime_type)
        try:
            result = self.extract_metadata(file_path)
            file_object.metadata = result.metadata
            file_object.is_consistent = self.validate_filename(file_path, result.metadata)
            if not file_object.is_consistent:
                self.logger.info(
                    "FILENAME MISMATCH: %s metadata title=%s",
                    file_path,
                    result.metadata.get("title"),
                )
            labels, confidence = self.generate_labels(result.content[:500], result.metadata)
            image_extensions = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"}
            if file_object.mime_type.startswith("image/") or file_path.suffix.lower() in image_extensions:
                if not labels:
                    labels = ["photo"]
                confidence = max(confidence, 85.0)
            if not labels and file_object.mime_type.startswith("video/"):
                labels = ["video"]
                confidence = 85.0
            if not labels and file_object.mime_type.startswith("audio/"):
                labels = ["audio"]
                confidence = 85.0
            if self.learning_store is not None:
                suggested, boost = self.learning_store.suggest_labels(file_object)
                if suggested:
                    if not labels or labels in (["photo"], ["video"], ["audio"]):
                        labels = suggested
                    confidence = min(100.0, confidence + boost)
                    self.logger.info(
                        "LEARNING SUGGESTION: %s -> %s (+%s)",
                        file_path,
                        suggested,
                        boost,
                    )

            file_object.labels = labels
            file_object.confidence_score = confidence
        except PermissionError as exc:
            file_object.errors.append(str(exc))
            self.logger.warning("PERMISSION ERROR reading %s: %s", file_path, exc)
        except Exception as exc:  # pragma: no cover - safety net
            file_object.errors.append(str(exc))
            self.logger.error("METADATA ERROR %s: %s", file_path, exc)
        return file_object
