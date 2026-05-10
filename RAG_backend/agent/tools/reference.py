from langchain_community.tools import DuckDuckGoSearchRun, WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper
from langchain_core.tools import tool

_ddg = DuckDuckGoSearchRun()
_wiki = WikipediaQueryRun(
    api_wrapper=WikipediaAPIWrapper(top_k_results=2, doc_content_chars_max=2000)
)


@tool
def web_search(query: str) -> str:
    """General web search via DuckDuckGo. Use for movie news, reviews,
    release dates, and any factual lookup that isn't well covered by
    Wikipedia or TMDB. Returns top snippets.
    """
    try:
        return _ddg.run(query)
    except Exception as e:
        return f"Web search failed: {e}"


@tool
def wikipedia_lookup(query: str) -> str:
    """Wikipedia summary lookup. Use for deeper context on directors,
    actors, film history, classic movies, or anything where a long-form
    encyclopedia entry beats a search snippet.
    """
    try:
        return _wiki.run(query)
    except Exception as e:
        return f"Wikipedia lookup failed: {e}"
