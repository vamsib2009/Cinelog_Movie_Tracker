from langchain_core.tools import tool

from agent.tools._shared import embed_query, format_movie_for_prompt
from preprocessing import db


@tool
def db_search(query: str, top_k: int = 10) -> str:
    """Semantic search of the user's personal movie collection by vibe/topic.

    Use for free-form recommendation queries like "feel-good comedies",
    "movies about heists", or "something like Inception". Returns up to
    top_k candidate movies with id, name, director, genre, rating, year,
    language, cast, and a short description. Always pass through this
    before calling present_movies for collection-based recommendations.
    """
    qvec = embed_query(query)
    rows = db.search_movies(qvec, top_k)
    if not rows:
        return "No matching movies in the collection."
    return "\n".join(format_movie_for_prompt(r) for r in rows)


@tool
def get_movie_by_id(movie_id: int) -> str:
    """Fetch full details for a single movie in the user's collection by its id.

    Use after db_search when the user asks a follow-up about a specific
    movie ("tell me more about that one"), or when you have an id from
    earlier context and need its full details again.
    """
    m = db.fetch_movie_by_id(movie_id)
    if not m:
        return f"No movie with id={movie_id} in the collection."
    return format_movie_for_prompt(m)


@tool
def filter_movies(
    genre: str | None = None,
    language: str | None = None,
    min_rating: float | None = None,
    year_from: int | None = None,
    year_to: int | None = None,
    limit: int = 20,
) -> str:
    """Structured filter over the user's collection. Use when the user has
    HARD constraints (specific genre, language, rating threshold, year range)
    that semantic search would muddle.

    Example: "Telugu movies after 2015 rated above 8" →
    filter_movies(language="Telugu", year_from=2015, min_rating=8.0).

    All arguments are optional. genre matches the movie's category column
    case-insensitively. language is matched against the movie's language
    array. Results sorted by IMDb rating (highest first).
    """
    rows = db.filter_movies(
        genre=genre,
        language=language,
        min_rating=min_rating,
        year_from=year_from,
        year_to=year_to,
        limit=limit,
    )
    if not rows:
        return "No movies in the collection match those filters."
    return "\n".join(format_movie_for_prompt(r) for r in rows)


@tool
def find_similar_to_movie(movie_id: int, top_k: int = 5) -> str:
    """Find movies in the user's collection similar to a given movie id.

    Powers "more like this" — uses the stored embedding of the seed movie,
    so no fresh embedding call is made. Returns up to top_k similar movies.
    Use after the user expresses interest in a specific movie they own.
    """
    rows = db.find_similar_movies(movie_id, top_k)
    if not rows:
        return f"Couldn't find similar movies for id={movie_id}."
    return "\n".join(format_movie_for_prompt(r) for r in rows)
