from typing import Optional

from pydantic import BaseModel, model_validator


class AnalyzeRequest(BaseModel):
    query: Optional[str] = None
    repos: Optional[list[str]] = None

    @model_validator(mode="after")
    def check_exactly_one(self) -> "AnalyzeRequest":
        # Use explicit `is None` checks — NOT falsiness.
        # An empty string "" is falsy but is NOT None; it must not slip through.
        if self.query is None and self.repos is None:
            raise ValueError("Provide either 'query' or 'repos'.")
        if self.query is not None and self.repos is not None:
            raise ValueError("Provide either 'query' or 'repos', not both.")
        return self


class RepoResult(BaseModel):
    repository: str
    x: float
    y: float
    stars: int
    forks: int
    issues: int
    language: Optional[str] = None
    doc_length: int
