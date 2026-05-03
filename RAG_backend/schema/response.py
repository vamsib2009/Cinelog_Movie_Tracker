from pydantic import BaseModel


class MovieResponse(BaseModel):
    id: int
    name: str = ""
    description: str = ""
    directorName: str = ""
    category: str = ""
    imdbrating: float = 0.0
    releaseDate: str = ""
    language: list[str] = []
    country: list[str] = []
    actorNames: list[str] = []
    tags: list[str] = []


class RagResponse(BaseModel):
    text: str
    movies: list[MovieResponse] | None = None
