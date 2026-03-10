import logging
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routers.analyze import _get_service, router as analyze_router
from repositories.github_repository import GithubRepository
from repositories.qdrant_repository import QdrantRepository
from services import vectorization_service
from services.analyze_service import AnalyzeService

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ── Singleton service instance ────────────────────────────────────────────────
# Initialized in lifespan, returned by the dependency getter every request.
_service: AnalyzeService | None = None


def get_analyze_service() -> AnalyzeService:
    """FastAPI dependency — returns the module-level singleton."""
    return _service


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    global _service

    # 1. Load sentence-transformers model before any request arrives.
    #    Must be done here, not lazily, to avoid a race condition where
    #    concurrent requests both try to load the model simultaneously.
    vectorization_service.load_model()

    # 2. Initialise repositories (no I/O yet).
    github_repo = GithubRepository()
    qdrant_repo = QdrantRepository()

    # 3. Ensure Qdrant collection exists.
    qdrant_repo.ensure_collection()

    # 4. Build and store the singleton service.
    _service = AnalyzeService(github_repo=github_repo, qdrant_repo=qdrant_repo)

    # 5. Wire the dependency override so the router uses our singleton.
    app.dependency_overrides[_get_service] = get_analyze_service

    logger.info("GitHub Vibe Analyzer backend ready.")
    yield

    # Cleanup (nothing to tear down for now).
    logger.info("Backend shutting down.")


# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(title="GitHub Vibe Analyzer", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    # Include both common Flutter web dev ports.
    # For production, replace with explicit origin(s).
    allow_origins=[
        "http://localhost:8080",
        "http://localhost:5000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(analyze_router)
