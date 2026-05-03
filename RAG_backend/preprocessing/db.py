import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

_DB_URL = os.environ["DATABASE_URL"]
if _DB_URL.startswith("postgresql://"):
    _DB_URL = _DB_URL.replace("postgresql://", "postgresql+psycopg2://", 1)

engine = create_engine(_DB_URL, pool_pre_ping=True, future=True)


_FETCH_SQL = text(
    """
    SELECT
        m.id,
        m.name,
        m.description,
        m.director_name,
        m.category,
        m.imdbrating,
        m.release_date,
        m.language,
        m.country,
        COALESCE(
            array_agg(DISTINCT ma.actor_name) FILTER (WHERE ma.actor_name IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS actors,
        COALESCE(
            array_agg(DISTINCT mt.tag) FILTER (WHERE mt.tag IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS tags
    FROM movie m
    LEFT JOIN movie_actors ma ON ma.movie_id = m.id
    LEFT JOIN movie_tags   mt ON mt.movie_id = m.id
    GROUP BY m.id
    ORDER BY m.id;
    """
)


def fetch_all_movies() -> list[dict]:
    with engine.connect() as conn:
        return [dict(row._mapping) for row in conn.execute(_FETCH_SQL)]


_UPDATE_SQL = text(
    "UPDATE movie SET rag_embedding = CAST(:vec AS vector) WHERE id = :id"
)


def update_embeddings(pairs: list[tuple[int, list[float]]]) -> None:
    if not pairs:
        return
    params = [
        {"id": mid, "vec": "[" + ",".join(f"{x:.7f}" for x in vec) + "]"}
        for mid, vec in pairs
    ]
    with engine.begin() as conn:
        conn.execute(_UPDATE_SQL, params)


def count_embedded() -> int:
    with engine.connect() as conn:
        return conn.execute(
            text("SELECT count(*) FROM movie WHERE rag_embedding IS NOT NULL")
        ).scalar_one()


_SEARCH_SQL = text(
    """
    SELECT
        m.id,
        m.name,
        m.description,
        m.director_name,
        m.category,
        m.imdbrating,
        m.release_date,
        m.language,
        m.country,
        COALESCE(
            array_agg(DISTINCT ma.actor_name) FILTER (WHERE ma.actor_name IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS actors,
        COALESCE(
            array_agg(DISTINCT mt.tag) FILTER (WHERE mt.tag IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS tags,
        m.rag_embedding <=> CAST(:vec AS vector) AS distance
    FROM movie m
    LEFT JOIN movie_actors ma ON ma.movie_id = m.id
    LEFT JOIN movie_tags   mt ON mt.movie_id = m.id
    WHERE m.rag_embedding IS NOT NULL
    GROUP BY m.id
    ORDER BY distance
    LIMIT :k;
    """
)


def search_movies(query_vec: list[float], top_k: int) -> list[dict]:
    vec_str = "[" + ",".join(f"{x:.7f}" for x in query_vec) + "]"
    with engine.connect() as conn:
        return [
            dict(row._mapping)
            for row in conn.execute(_SEARCH_SQL, {"vec": vec_str, "k": top_k})
        ]
