import os

from dotenv import load_dotenv
from openai import OpenAI

from schema.response import MovieResponse

load_dotenv()

EMBED_MODEL = "text-embedding-3-small"

_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY") or os.getenv("OPEN_API_KEY"))


def embed_query(query: str) -> list[float]:
    resp = _client.embeddings.create(model=EMBED_MODEL, input=query)
    return resp.data[0].embedding


def format_movie_for_prompt(m: dict) -> str:
    bits = [f"[id={m['id']}] {m['name']}"]
    if m.get("director_name"):
        bits.append(f"dir. {m['director_name']}")
    if m.get("category"):
        bits.append(f"genre: {m['category']}")
    if m.get("imdbrating") is not None:
        bits.append(f"IMDb {m['imdbrating']}")
    if m.get("release_date"):
        bits.append(f"({m['release_date'].year})")
    if m.get("language"):
        bits.append(f"lang: {', '.join(m['language'])}")
    if m.get("actors"):
        bits.append(f"cast: {', '.join(m['actors'][:4])}")
    if m.get("description"):
        bits.append(f"— {m['description'][:220]}")
    return ". ".join(bits)


def to_movie_response(m: dict) -> MovieResponse:
    return MovieResponse(
        id=m["id"],
        name=m.get("name") or "",
        description=m.get("description") or "",
        directorName=m.get("director_name") or "",
        category=m.get("category") or "",
        imdbrating=float(m.get("imdbrating") or 0.0),
        releaseDate=m["release_date"].isoformat() if m.get("release_date") else "",
        language=list(m.get("language") or []),
        country=list(m.get("country") or []),
        actorNames=list(m.get("actors") or []),
        tags=list(m.get("tags") or []),
    )
