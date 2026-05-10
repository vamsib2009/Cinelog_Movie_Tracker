from agent.tools.collection import (
    db_search,
    filter_movies,
    find_similar_to_movie,
    get_movie_by_id,
)
from agent.tools.external import find_showtimes, tmdb_now_playing, tmdb_trending
from agent.tools.present import present_movies
from agent.tools.reference import web_search, wikipedia_lookup

ALL_TOOLS = [
    db_search,
    get_movie_by_id,
    filter_movies,
    find_similar_to_movie,
    tmdb_now_playing,
    tmdb_trending,
    find_showtimes,
    web_search,
    wikipedia_lookup,
    present_movies,
]
