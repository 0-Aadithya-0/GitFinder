import logging

from fastapi import APIRouter, Depends, HTTPException

from api.schemas import AnalyzeRequest, RepoResult
from services.analyze_service import AnalyzeService

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_service() -> AnalyzeService:
    """
    Dependency placeholder — overridden at startup by main.py.
    Defined here to keep the import graph clean; the actual singleton
    is injected via app.dependency_overrides in the lifespan handler.
    """
    raise RuntimeError("AnalyzeService not initialized.")


@router.post("/analyze", response_model=list[RepoResult])
async def analyze(
    request: AnalyzeRequest,
    service: AnalyzeService = Depends(_get_service),
) -> list[RepoResult]:
    """
    Analyze GitHub repositories and return normalized 2D vibe coordinates.

    Accepts either:
      - {"query": "flutter state management"}  — broad GitHub search
      - {"repos": ["https://github.com/owner/repo", ...]}  — specific URLs
    """
    try:
        if request.query is not None:
            results = await service.analyze_by_query(request.query)
        else:
            results = await service.analyze_by_urls(request.repos)

        return [RepoResult(**r) for r in results]

    except Exception as exc:
        logger.exception("Error during analysis: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))
