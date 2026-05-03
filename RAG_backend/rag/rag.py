import json
import os
from typing import Iterator

from dotenv import load_dotenv
from openai import OpenAI
from pydantic import BaseModel

from preprocessing.db import search_movies
from schema.request import ChatTurn
from schema.response import MovieResponse, RagResponse

load_dotenv()

EMBED_MODEL = "text-embedding-3-small"
CHAT_MODEL = "gpt-4o-mini"

# Always retrieve a wide pool for the LLM to choose from, regardless of how many
# suggestions we'll display. More context = better LLM judgment.
RETRIEVAL_K = 10

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY") or os.getenv("OPEN_API_KEY"))


class _LLMOutput(BaseModel):
    answer: str
    is_recommendation: bool
    recommended_movie_ids: list[int]


def _system_prompt(max_suggestions: int) -> str:
    return f"""You are a warm, enthusiastic movie companion helping a user explore their personal movie collection.

You will receive the user's query and a list of candidate movies retrieved from their collection by semantic similarity. Each movie has an id you can reference.

Tone & content rules:
- Write a 100-300 word answer in a warm, conversational tone. Refer to movies by name, never by id.
- Stay POSITIVE about every movie in the user's collection. Highlight what makes each one interesting, fun, or worth watching. Never criticize, dismiss, mock, or make backhanded comments about a movie — even ones you wouldn't personally pick. If you're recommending it, sell it like you mean it.
- NEVER criticize the database, the collection, "missing data", "outdated records", or imply the collection is incomplete. The user knows what's in their library; don't draw attention to what isn't.
- If the user asks for something specific that isn't directly in the candidates (e.g. "the latest Telugu movies" when nothing recent is in the list), gracefully pivot. Phrase it like "Here are some Telugu picks from your collection you might enjoy..." — never "your collection doesn't have recent releases" or similar negative framing.
- If the user asks for recommendations or "what should I watch" style questions, set is_recommendation=true and pick UP TO {max_suggestions} movies that genuinely fit. Quality over quantity — one perfect pick beats three mediocre ones. If only one or two truly fit, return only those.
- If the user asks a factual or conversational question (e.g. "tell me about Inception", "who directed X"), set is_recommendation=false and leave recommended_movie_ids empty.
- Only reference movies from the provided candidate list. If genuinely nothing in the list relates to the query at all, say something like "Hmm, nothing in your collection matches that exactly — how about exploring some other recommendations?" without naming any movie."""


def _embed_query(query: str) -> list[float]:
    resp = client.embeddings.create(model=EMBED_MODEL, input=query)
    return resp.data[0].embedding


def _retrieval_text(query: str, history: list[ChatTurn] | None) -> str:
    # Follow-ups like "another one like that" lose all signal on their own.
    # Prepend recent user turns so retrieval inherits the conversation's topic.
    prior = " ".join(h.content for h in (history or []) if h.role == "user")
    return f"{prior} {query}".strip() if prior else query


def _format_for_prompt(m: dict) -> str:
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


def _to_response(m: dict) -> MovieResponse:
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


def run_rag(
    query: str,
    max_suggestions: int,
    history: list[ChatTurn] | None = None,
) -> RagResponse:
    qvec = _embed_query(_retrieval_text(query, history))
    candidates = search_movies(qvec, RETRIEVAL_K)

    context = "\n".join(_format_for_prompt(m) for m in candidates)
    user_msg = (
        f"User query: {query}\n\n"
        f"Candidate movies from their collection (most semantically similar first):\n{context}"
    )

    messages = [
        {"role": "system", "content": _system_prompt(max_suggestions)},
        *[{"role": h.role, "content": h.content} for h in (history or [])],
        {"role": "user", "content": user_msg},
    ]

    completion = client.beta.chat.completions.parse(
        model=CHAT_MODEL,
        messages=messages,
        response_format=_LLMOutput,
    )
    parsed = completion.choices[0].message.parsed

    movies = None
    if parsed.is_recommendation and parsed.recommended_movie_ids:
        by_id = {m["id"]: m for m in candidates}
        # Cap at max_suggestions in case the LLM returns more than asked.
        picked = [
            by_id[mid] for mid in parsed.recommended_movie_ids if mid in by_id
        ][:max_suggestions]
        if picked:
            movies = [_to_response(m) for m in picked]

    return RagResponse(text=parsed.answer, movies=movies)


def _sse(payload: dict) -> str:
    return "data: " + json.dumps(payload) + "\n\n"


_ANSWER_MARKER = '"answer":"'


def _extract_answer(raw: str) -> str:
    """Pull the in-progress answer string out of partial structured-output JSON.
    The model emits {"answer":"...","is_recommendation":...,...} character by
    character. While `answer` is still being written, the JSON parser can't
    materialize the field — but we can scan for it and decode escapes ourselves.
    """
    i = raw.find(_ANSWER_MARKER)
    if i == -1:
        return ""
    out = []
    i += len(_ANSWER_MARKER)
    while i < len(raw):
        c = raw[i]
        if c == "\\" and i + 1 < len(raw):
            nxt = raw[i + 1]
            esc = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\", "/": "/"}.get(nxt)
            if esc is not None:
                out.append(esc)
                i += 2
                continue
            # Unknown escape — leave both chars in, advance.
            out.append(c)
            i += 1
            continue
        if c == '"':
            return "".join(out)  # end of answer field
        out.append(c)
        i += 1
    return "".join(out)  # still streaming


def stream_rag(
    query: str,
    max_suggestions: int,
    history: list[ChatTurn] | None = None,
) -> Iterator[str]:
    """Yields SSE-formatted strings: text deltas, then a final 'done' event with movies."""
    qvec = _embed_query(_retrieval_text(query, history))
    candidates = search_movies(qvec, RETRIEVAL_K)

    context = "\n".join(_format_for_prompt(m) for m in candidates)
    user_msg = (
        f"User query: {query}\n\n"
        f"Candidate movies from their collection (most semantically similar first):\n{context}"
    )
    messages = [
        {"role": "system", "content": _system_prompt(max_suggestions)},
        *[{"role": h.role, "content": h.content} for h in (history or [])],
        {"role": "user", "content": user_msg},
    ]

    last_answer = ""
    parsed = None
    with client.beta.chat.completions.stream(
        model=CHAT_MODEL,
        messages=messages,
        response_format=_LLMOutput,
    ) as stream:
        for event in stream:
            # content.delta events have a `snapshot` string with all JSON so far.
            if event.type != "content.delta":
                continue
            raw = event.snapshot
            if not isinstance(raw, str):
                continue
            current = _extract_answer(raw)
            if len(current) > len(last_answer):
                delta = current[len(last_answer):]
                yield _sse({"type": "text", "delta": delta})
                last_answer = current
        final = stream.get_final_completion()
        parsed = final.choices[0].message.parsed

    movies_payload = None
    if parsed and parsed.is_recommendation and parsed.recommended_movie_ids:
        by_id = {m["id"]: m for m in candidates}
        picked = [
            by_id[mid] for mid in parsed.recommended_movie_ids if mid in by_id
        ][:max_suggestions]
        if picked:
            movies_payload = [_to_response(m).model_dump() for m in picked]

    yield _sse({"type": "done", "movies": movies_payload})
