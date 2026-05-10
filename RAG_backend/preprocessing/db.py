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


_FETCH_BY_ID_SQL = text(
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
    WHERE m.id = :id
    GROUP BY m.id;
    """
)


def fetch_movie_by_id(movie_id: int) -> dict | None:
    with engine.connect() as conn:
        row = conn.execute(_FETCH_BY_ID_SQL, {"id": movie_id}).first()
        return dict(row._mapping) if row else None


_FETCH_BY_IDS_SQL = text(
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
    WHERE m.id = ANY(:ids)
    GROUP BY m.id;
    """
)


def fetch_movies_by_ids(ids: list[int]) -> list[dict]:
    if not ids:
        return []
    with engine.connect() as conn:
        rows = [
            dict(row._mapping)
            for row in conn.execute(_FETCH_BY_IDS_SQL, {"ids": ids})
        ]
    by_id = {r["id"]: r for r in rows}
    return [by_id[i] for i in ids if i in by_id]


def filter_movies(
    genre: str | None = None,
    language: str | None = None,
    min_rating: float | None = None,
    year_from: int | None = None,
    year_to: int | None = None,
    limit: int = 20,
) -> list[dict]:
    where = []
    params: dict = {"limit": limit}
    if genre:
        where.append("m.category ILIKE :genre")
        params["genre"] = genre
    if language:
        where.append(":language = ANY(m.language)")
        params["language"] = language
    if min_rating is not None:
        where.append("m.imdbrating >= :min_rating")
        params["min_rating"] = min_rating
    if year_from is not None:
        where.append("EXTRACT(YEAR FROM m.release_date) >= :year_from")
        params["year_from"] = year_from
    if year_to is not None:
        where.append("EXTRACT(YEAR FROM m.release_date) <= :year_to")
        params["year_to"] = year_to

    where_sql = ("WHERE " + " AND ".join(where)) if where else ""
    sql = text(
        f"""
        SELECT
            m.id, m.name, m.description, m.director_name, m.category,
            m.imdbrating, m.release_date, m.language, m.country,
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
        {where_sql}
        GROUP BY m.id
        ORDER BY m.imdbrating DESC NULLS LAST
        LIMIT :limit;
        """
    )
    with engine.connect() as conn:
        return [dict(row._mapping) for row in conn.execute(sql, params)]


_SIMILAR_SQL = text(
    """
    SELECT
        m.id, m.name, m.description, m.director_name, m.category,
        m.imdbrating, m.release_date, m.language, m.country,
        COALESCE(
            array_agg(DISTINCT ma.actor_name) FILTER (WHERE ma.actor_name IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS actors,
        COALESCE(
            array_agg(DISTINCT mt.tag) FILTER (WHERE mt.tag IS NOT NULL),
            ARRAY[]::varchar[]
        ) AS tags,
        m.rag_embedding <=> (SELECT rag_embedding FROM movie WHERE id = :id) AS distance
    FROM movie m
    WHERE m.id != :id
      AND m.rag_embedding IS NOT NULL
      AND (SELECT rag_embedding FROM movie WHERE id = :id) IS NOT NULL
    GROUP BY m.id
    ORDER BY distance
    LIMIT :k;
    """
)


def find_similar_movies(movie_id: int, top_k: int) -> list[dict]:
    with engine.connect() as conn:
        return [
            dict(row._mapping)
            for row in conn.execute(_SIMILAR_SQL, {"id": movie_id, "k": top_k})
        ]
