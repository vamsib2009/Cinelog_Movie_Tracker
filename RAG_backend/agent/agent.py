import os
import re
from datetime import date

from dotenv import load_dotenv
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI

from agent.prompt import SYSTEM_PROMPT
from agent.tools import ALL_TOOLS
from agent.tools._shared import to_movie_response
from preprocessing import db
from schema.request import ChatTurn
from schema.response import RagResponse

_COLLECTION_TOOLS = {"db_search", "filter_movies", "find_similar_to_movie", "get_movie_by_id"}
_ID_RE = re.compile(r"\[id=(\d+)\]")

load_dotenv()

CHAT_MODEL = "gpt-4o"

_llm = ChatOpenAI(
    model=CHAT_MODEL,
    temperature=0.4,
    api_key=os.getenv("OPENAI_API_KEY") or os.getenv("OPEN_API_KEY"),
)

_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", SYSTEM_PROMPT),
        MessagesPlaceholder("chat_history", optional=True),
        ("human", "{input}"),
        MessagesPlaceholder("agent_scratchpad"),
    ]
)


def _build_executor(max_suggestions: int) -> AgentExecutor:
    prompt = _prompt.partial(
        max_suggestions=str(max_suggestions),
        current_date=date.today().isoformat(),
        current_year=str(date.today().year),
    )
    agent = create_tool_calling_agent(_llm, ALL_TOOLS, prompt)
    return AgentExecutor(
        agent=agent,
        tools=ALL_TOOLS,
        verbose=True,
        return_intermediate_steps=True,
        max_iterations=8,
        handle_parsing_errors=True,
    )


def _to_lc_history(history: list[ChatTurn] | None):
    msgs = []
    for h in history or []:
        if h.role == "user":
            msgs.append(HumanMessage(content=h.content))
        else:
            msgs.append(AIMessage(content=h.content))
    return msgs


def _ids_from_present_movies(steps: list) -> list[int]:
    """Last present_movies call's ids, in the order the agent passed them."""
    ids: list[int] = []
    for action, _obs in steps:
        if getattr(action, "tool", None) == "present_movies":
            raw = (action.tool_input or {}).get("movie_ids", [])
            if isinstance(raw, list):
                ids = [int(x) for x in raw if isinstance(x, (int, str)) and str(x).lstrip("-").isdigit()]
    return ids


def _ids_from_collection_tool_fallback(steps: list) -> list[int]:
    """Fallback: ids parsed (in order) from the most recent collection-tool
    observation. Used when the agent searched the library but forgot to call
    present_movies - which gpt-4o-mini does often.
    """
    last_obs: str | None = None
    for action, obs in steps:
        if getattr(action, "tool", None) in _COLLECTION_TOOLS:
            last_obs = obs if isinstance(obs, str) else str(obs)
    if not last_obs:
        return []
    seen: set[int] = set()
    ids: list[int] = []
    for m in _ID_RE.finditer(last_obs):
        i = int(m.group(1))
        if i not in seen:
            seen.add(i)
            ids.append(i)
    return ids


def run_agent(
    query: str,
    history: list[ChatTurn] | None,
    max_suggestions: int,
) -> RagResponse:
    executor = _build_executor(max_suggestions)
    result = executor.invoke(
        {"input": query, "chat_history": _to_lc_history(history)}
    )

    text = result.get("output") or ""
    steps = result.get("intermediate_steps") or []

    picked_ids = _ids_from_present_movies(steps)
    if not picked_ids:
        picked_ids = _ids_from_collection_tool_fallback(steps)
    picked_ids = picked_ids[:max_suggestions]

    movies = None
    if picked_ids:
        rows = db.fetch_movies_by_ids(picked_ids)
        if rows:
            movies = [to_movie_response(m) for m in rows]

    return RagResponse(text=text, movies=movies)
