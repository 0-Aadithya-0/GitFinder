import logging
import re

from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

_MODEL_NAME = "all-MiniLM-L6-v2"
_MAX_CHARS = 2000

# This module provides functions to load a sentence-transformers model,
# clean markdown text, and embed text into vectors for similarity search.
# Module-level singleton — set by load_model() at app startup.
# NOT lazily initialized: concurrent requests checking `_model is None`
# simultaneously would both attempt to load the 90MB model (race condition).
_model: SentenceTransformer | None = None


def load_model() -> None:
    """
    Load the sentence-transformers model into the module-level singleton.
    Must be called once at application startup (in the lifespan handler)
    before any requests are served.
    """
    global _model
    logger.info("Loading sentence-transformers model '%s'...", _MODEL_NAME)
    _model = SentenceTransformer(_MODEL_NAME)
    logger.info("Model loaded.")


def clean_markdown(text: str) -> str:
    """
    Strip markdown/HTML noise to produce clean plain text for embedding.

    Steps:
      1. Strip all HTML tags via BeautifulSoup.
      2. Remove shield.io badge URLs.
      3. Remove residual markdown image syntax.
      4. Convert markdown links to their display text only.
      5. Collapse repeated whitespace and newlines.
      6. Truncate to _MAX_CHARS to prevent memory spikes during embedding.
    """
    # 1. Strip HTML tags
    text = BeautifulSoup(text, "html.parser").get_text(separator=" ")

    # 2. Remove shields.io badges: ![alt](https://img.shields.io/...)
    text = re.sub(r"!\[.*?\]\(https?://img\.shields\.io[^)]*\)", "", text)

    # 3. Remove any remaining markdown image syntax: ![alt](url)
    text = re.sub(r"!\[.*?\]\([^)]*\)", "", text)

    # 4. Convert markdown links to display text: [text](url) → text
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)

    # 5. Collapse whitespace
    text = re.sub(r"\s+", " ", text).strip()

    # 6. Truncate
    return text[:_MAX_CHARS]


def embed_text(text: str) -> list[float]:
    """
    Encode text into a 384-dimensional vector using the loaded model.
    normalize_embeddings=True ensures cosine similarity == dot product,
    which matches the Cosine distance metric used in Qdrant.
    """
    if _model is None:
        raise RuntimeError("Model not loaded. Call load_model() at startup.")
    embedding = _model.encode(text, normalize_embeddings=True)
    return embedding.tolist()
