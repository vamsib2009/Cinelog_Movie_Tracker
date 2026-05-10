from langchain_core.tools import tool


@tool
def present_movies(movie_ids: list[int]) -> str:
    """Surface movies from the user's COLLECTION in the UI's movie carousel.

    Call this exactly ONCE near the end of any turn that recommends movies
    from the user's library. Pass the ids you want displayed (in priority
    order). The handler scans the agent's tool calls after execution and
    uses the ids passed here as the response.movies list.

    Do NOT call this for movies that aren't in the user's collection — TMDB
    results, currently-playing titles, or anything from web search go in
    your text answer only.
    """
    return f"Acknowledged {len(movie_ids)} movie(s) for display."
