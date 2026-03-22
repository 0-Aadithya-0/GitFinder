import asyncio
import logging
import re
from typing import Optional

from repositories.github_repository import GithubRepository
from repositories.qdrant_repository import QdrantRepository
from services import vectorization_service
from services.reduction_service import normalize_coordinates, reduce_to_2d

logger = logging.getLogger(__name__)

_GITHUB_URL_RE = re.compile(
    r"https?://(?:www\.)?github\.com/([^/\s]+)/([^/\s]+?)/?(?:\.git)?/?$"
)


class AnalyzeService:
    def __init__(
        self,
        github_repo: GithubRepository,
        qdrant_repo: QdrantRepository,
    ) -> None:
        self._github = github_repo
        self._qdrant = qdrant_repo

    # ── Public API ────────────────────────────────────────────────────────────

    async def analyze_by_query(self, query: str) -> list[dict]:
        """
        Search GitHub for repos matching `query`, embed their READMEs,
        store in Qdrant, then return normalized 2D coordinates + metadata.

        Data sourcing note:
          GitHub search results already include stargazers_count, forks_count,
          open_issues_count, and language. get_repo_details() is NOT called —
          doing so would double the API call count for no benefit.
        """
        raw_repos = await self._github.search_repos(query)
        if not raw_repos:
            return []

        # Fetch all READMEs concurrently to avoid 20 sequential API calls.
        readme_tasks = [
            self._github.get_readme(r["owner"]["login"], r["name"])
            for r in raw_repos
        ]
        readmes: list[Optional[str]] = await asyncio.gather(*readme_tasks)

        repo_records = []
        for repo_item, readme_text in zip(raw_repos, readmes):
            record = self._build_record_from_search(repo_item, readme_text)
            repo_records.append(record)

        return await self._embed_store_reduce(repo_records)

    async def analyze_by_urls(self, urls: list[str]) -> list[dict]:
        """
        Analyze a specific list of GitHub repo URLs.
        Fetches repo details and README concurrently per repo since
        search results (which carry metadata) are not available in this mode.
        """
        parsed = [self._parse_github_url(url) for url in urls]
        valid = [(owner, repo) for owner, repo in parsed if owner and repo]

        if not valid:
            return []

        # Fetch details + README concurrently for each repo.
        async def fetch_one(owner: str, repo: str) -> Optional[dict]:
            details, readme_text = await asyncio.gather(
                self._github.get_repo_details(owner, repo),
                self._github.get_readme(owner, repo),
            )
            return self._build_record_from_details(details, readme_text)

        results = await asyncio.gather(*[fetch_one(o, r) for o, r in valid])
        repo_records = [r for r in results if r is not None]

        if not repo_records:
            return []

        return await self._embed_store_reduce(repo_records)

    # ── Internal pipeline ─────────────────────────────────────────────────────
    # This method encapsulates the shared tail of both analysis pipelines:
    async def _embed_store_reduce(self, repo_records: list[dict]) -> list[dict]:
        """
        Shared pipeline tail:
          clean → embed → upsert → get_all_vectors → reduce → normalize → respond
        """
        for record in repo_records:
            raw_text = record.pop("_raw_text", "")
            clean_text = vectorization_service.clean_markdown(raw_text)
            record["doc_length"] = len(clean_text)
            vector = vectorization_service.embed_text(clean_text)

            self._qdrant.upsert_repo(
                repo_name=record["repository"],
                vector=vector,
                payload=record,
            )

        all_vectors_and_payloads = self._qdrant.get_all_vectors()
        if not all_vectors_and_payloads:
            return []

        vectors = [v for v, _ in all_vectors_and_payloads]
        payloads = [p for _, p in all_vectors_and_payloads]

        coords_2d = reduce_to_2d(vectors)
        normalized = normalize_coordinates(coords_2d)

        response = []
        for (x, y), payload in zip(normalized, payloads):
            response.append(
                {
                    "repository": payload.get("repository", ""),
                    "x": x,
                    "y": y,
                    "stars": payload.get("stars", 0),
                    "forks": payload.get("forks", 0),
                    "issues": payload.get("issues", 0),
                    "language": payload.get("language"),
                    "doc_length": payload.get("doc_length", 0),
                }
            )

        return response

    # ── Record builders ───────────────────────────────────────────────────────

    def _build_record_from_search(
        self, repo_item: dict, readme_text: Optional[str]
    ) -> dict:
        """Build an intermediate record from a GitHub search result item."""
        full_name = repo_item.get("full_name", "")
        raw_text = readme_text or repo_item.get("description") or full_name

        return {
            "repository": full_name,
            "stars": repo_item.get("stargazers_count", 0),
            "forks": repo_item.get("forks_count", 0),
            "issues": repo_item.get("open_issues_count", 0),
            "language": repo_item.get("language"),
            "_raw_text": raw_text,  # consumed and removed in _embed_store_reduce
        }

    def _build_record_from_details(
        self, details: dict, readme_text: Optional[str]
    ) -> Optional[dict]:
        """Build an intermediate record from a get_repo_details response."""
        if not details or details.get("message") == "Not Found":
            return None

        full_name = details.get("full_name", "")
        raw_text = readme_text or details.get("description") or full_name

        return {
            "repository": full_name,
            "stars": details.get("stargazers_count", 0),
            "forks": details.get("forks_count", 0),
            "issues": details.get("open_issues_count", 0),
            "language": details.get("language"),
            "_raw_text": raw_text,
        }

    # ── Utilities ─────────────────────────────────────────────────────────────

    @staticmethod
    def _parse_github_url(url: str) -> tuple[Optional[str], Optional[str]]:
        """
        Extract (owner, repo) from a GitHub URL.
        Returns (None, None) if the URL does not match the expected pattern.
        """
        match = _GITHUB_URL_RE.match(url.strip())
        if match:
            return match.group(1), match.group(2)
        return None, None
