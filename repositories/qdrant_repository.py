import hashlib
import logging
import os
import uuid
from typing import Any, Optional

from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance,
    PointStruct,
    VectorParams,
)

logger = logging.getLogger(__name__)

_COLLECTION = "repos"
_VECTOR_SIZE = 384


class QdrantRepository:
    def __init__(self) -> None:
        host = os.getenv("QDRANT_HOST", "localhost")
        port = int(os.getenv("QDRANT_PORT", "6333"))
        self._client = QdrantClient(host=host, port=port)

    # ── Collection management ─────────────────────────────────────────────────

    def ensure_collection(self) -> None:
        """Create the 'repos' collection if it does not already exist."""
        if self._client.collection_exists(_COLLECTION):
            logger.info("Qdrant collection '%s' already exists.", _COLLECTION)
            return

        self._client.create_collection(
            collection_name=_COLLECTION,
            vectors_config=VectorParams(size=_VECTOR_SIZE, distance=Distance.COSINE),
        )
        logger.info("Qdrant collection '%s' created.", _COLLECTION)

    # ── CRUD ──────────────────────────────────────────────────────────────────

    def upsert_repo(self, repo_name: str, vector: list[float], payload: dict) -> None:
        """
        Upsert a single repository point.
        The point ID is a deterministic UUID derived from the repo full name,
        so re-analyzing the same repo updates its vector rather than duplicating it.
        """
        point_id = self._repo_id(repo_name)

        self._client.upsert(
            collection_name=_COLLECTION,
            points=[
                PointStruct(
                    id=point_id,
                    vector=vector,
                    payload=payload,
                )
            ],
        )

    def get_all_vectors(self) -> list[tuple[list[float], dict]]:
        """
        Retrieve every point from the collection as (vector, payload) pairs.
        Uses scroll with pagination to handle collections larger than the page size.
        """
        results: list[tuple[list[float], dict]] = []
        offset: Optional[Any] = None

        while True:
            records, next_offset = self._client.scroll(
                collection_name=_COLLECTION,
                with_vectors=True,
                with_payload=True,
                limit=100,
                offset=offset,
            )

            for record in records:
                if record.vector and record.payload:
                    results.append((record.vector, record.payload))

            if next_offset is None:
                break
            offset = next_offset

        return results

    # ── Helpers ───────────────────────────────────────────────────────────────

    @staticmethod
    def _repo_id(repo_name: str) -> str:
        """
        Derive a deterministic UUID string from the repository full name.
        Qdrant accepts UUID strings as point IDs.
        """
        digest = hashlib.md5(repo_name.encode()).hexdigest()
        return str(uuid.UUID(digest))
