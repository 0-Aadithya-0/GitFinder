import asyncio
import logging
import os
import time
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

_GITHUB_API = "https://api.github.com"
_MAX_RETRIES = 5

# This module defines the GithubRepository class, which provides methods to interact with the GitHub API.
# It includes functionality to search repositories, fetch README files, and get repository details,
# with built-in handling for API rate limits using exponential backoff. The class uses an authentication
# token from the environment for authorized requests.
class GithubRepository:
    def __init__(self) -> None:
        token = os.getenv("GITHUB_TOKEN", "")
        self._headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json",
        }

    # ── Public methods ────────────────────────────────────────────────────────

    async def search_repos(self, query: str, per_page: int = 20) -> list[dict]:
        """Search GitHub repositories. Returns raw list of repo items."""
        url = f"{_GITHUB_API}/search/repositories"
        params = {"q": query, "per_page": per_page, "sort": "stars"}

        response = await self._with_backoff(url, params=params)
        data = response.json()
        return data.get("items", [])

    async def get_readme(self, owner: str, repo: str) -> Optional[str]:
        """Fetch raw README markdown. Returns None if no README exists."""
        url = f"{_GITHUB_API}/repos/{owner}/{repo}/readme"
        headers = {**self._headers, "Accept": "application/vnd.github.v3.raw"}

        try:
            async with httpx.AsyncClient(headers=headers, timeout=15) as client:
                response = await client.get(url)
                if response.status_code == 404:
                    return None
                if response.status_code == 403:
                    # Rate limited — fall through to backoff path
                    response = await self._with_backoff(url, headers=headers)
                    return response.text if response.status_code == 200 else None
                response.raise_for_status()
                return response.text
        except httpx.HTTPStatusError:
            return None

    # This method is used in URL-mode where we have no search results and need to fetch metadata for a single repo.
    async def get_repo_details(self, owner: str, repo: str) -> dict:
        """Fetch full repo metadata. Used in URL-mode (no search results available)."""
        url = f"{_GITHUB_API}/repos/{owner}/{repo}"
        response = await self._with_backoff(url)
        return response.json()

    # ── Internal helpers ──────────────────────────────────────────────────────

    async def _with_backoff(
        self,
        url: str,
        params: Optional[dict] = None,
        headers: Optional[dict] = None,
    ) -> httpx.Response:
        """
        GET request with exponential backoff on 403 rate-limit responses.
        Retries up to _MAX_RETRIES times with delays of 1, 2, 4, 8, 16 seconds.
        Uses the X-RateLimit-Reset header for precise wait time when available.
        404 responses are returned immediately without retry.
        """
        merged_headers = {**self._headers, **(headers or {})}

        for attempt in range(_MAX_RETRIES):
            async with httpx.AsyncClient(headers=merged_headers, timeout=30) as client:
                response = await client.get(url, params=params)

            if response.status_code == 404:
                return response

            if response.status_code == 403:
                wait = self._rate_limit_wait(response, attempt)
                logger.warning(
                    "GitHub rate limit hit (attempt %d/%d). Waiting %.1fs.",
                    attempt + 1,
                    _MAX_RETRIES,
                    wait,
                )
                await asyncio.sleep(wait)
                continue

            response.raise_for_status()
            return response

        raise RuntimeError(f"GitHub API request failed after {_MAX_RETRIES} retries: {url}")

    @staticmethod
    def _rate_limit_wait(response: httpx.Response, attempt: int) -> float:
        """
        Return seconds to wait before the next retry.
        Prefers the X-RateLimit-Reset Unix timestamp when present.
        Falls back to exponential backoff: 2^attempt seconds.
        """
        reset_header = response.headers.get("X-RateLimit-Reset")
        if reset_header:
            try:
                reset_at = int(reset_header)
                wait = max(reset_at - time.time(), 0) + 1  # +1s buffer
                return wait
            except ValueError:
                pass

        return float(2**attempt)
