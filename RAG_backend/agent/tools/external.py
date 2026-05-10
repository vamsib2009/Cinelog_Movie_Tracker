import os

import requests
from dotenv import load_dotenv
from langchain_community.tools import DuckDuckGoSearchRun
from langchain_core.tools import tool

load_dotenv()

_TMDB_KEY = os.getenv("TMDB_API_KEY")
_TMDB_BASE = "https://api.themoviedb.org/3"
_TIMEOUT = 10

_ddg = DuckDuckGoSearchRun()


def _tmdb_get(path: str, params: dict | None = None) -> dict:
    if not _TMDB_KEY:
        raise RuntimeError("TMDB_API_KEY is not set in .env")
    # TMDB has two auth schemes. Long JWT-style tokens (v4 Read Access Token,
    # start with "eyJ") use the Authorization: Bearer header. Short API keys
    # (v3) use the api_key query parameter. Detect and use whichever fits.
    is_v4_token = _TMDB_KEY.startswith("eyJ")
    headers = {"accept": "application/json"}
    query = dict(params or {})
    if is_v4_token:
        headers["Authorization"] = f"Bearer {_TMDB_KEY}"
    else:
        query["api_key"] = _TMDB_KEY
    r = requests.get(f"{_TMDB_BASE}{path}", headers=headers, params=query, timeout=_TIMEOUT)
    r.raise_for_status()
    return r.json()


def _format_tmdb_results(results: list[dict], limit: int = 10) -> str:
    lines = []
    for r in results[:limit]:
        title = r.get("title") or r.get("name") or "Untitled"
        date = r.get("release_date") or r.get("first_air_date") or ""
        rating = r.get("vote_average")
        overview = (r.get("overview") or "")[:240]
        bits = [title]
        if date:
            bits.append(f"({date})")
        if rating is not None:
            bits.append(f"TMDB {rating}")
        head = " ".join(bits)
        lines.append(f"{head} — {overview}" if overview else head)
    return "\n".join(lines) if lines else "No results."


@tool
def tmdb_now_playing(region: str = "US") -> str:
    """List movies currently playing in theaters in a given region.

    region is a 2-letter ISO country code (e.g. "US", "IN", "GB").
    Returns up to 10 titles with release date, TMDB rating, and overview.
    Use for "what's in theaters", "what's out right now". Do NOT call
    present_movies for these results — they are not in the user's collection.
    """
    try:
        data = _tmdb_get("/movie/now_playing", {"region": region, "page": 1})
    except Exception as e:
        return f"TMDB now_playing failed: {e}"
    return _format_tmdb_results(data.get("results", []))


@tool
def tmdb_trending(time_window: str = "week") -> str:
    """Globally trending movies on TMDB. time_window is "day" or "week".

    Use for "what's trending", "popular right now", "what's everyone watching".
    Do NOT call present_movies for these — they are not in the user's collection.
    """
    if time_window not in {"day", "week"}:
        time_window = "week"
    try:
        data = _tmdb_get(f"/trending/movie/{time_window}")
    except Exception as e:
        return f"TMDB trending failed: {e}"
    return _format_tmdb_results(data.get("results", []))


@tool
def find_showtimes(movie: str, location: str) -> str:
    """Look up showtimes for a movie near a location via web search.

    No reliable free showtime API exists, so this is a templated DuckDuckGo
    search. Results may be partial or stale — always tell the user to verify
    on the cinema's site / a ticketing app.
    """
    query = f"{movie} showtimes near {location} today"
    try:
        snippets = _ddg.run(query)
    except Exception as e:
        return f"Showtime search failed: {e}"
    return f"Search query: {query}\n\n{snippets}"
