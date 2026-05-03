import os

from dotenv import load_dotenv
from openai import OpenAI

from preprocessing.db import count_embedded, fetch_all_movies, update_embeddings

load_dotenv()

EMBED_MODEL = "text-embedding-3-small"
BATCH_SIZE = 100

api_key = os.getenv("OPENAI_API_KEY") or os.getenv("OPEN_API_KEY")
client = OpenAI(api_key=api_key)


def build_text(row: dict) -> str:
    parts = []
    if row.get("name"):
        parts.append(f"Title: {row['name']}")
    if row.get("director_name"):
        parts.append(f"Director: {row['director_name']}")
    if row.get("category"):
        parts.append(f"Category: {row['category']}")
    if row.get("imdbrating") is not None:
        parts.append(f"IMDb: {row['imdbrating']}")
    if row.get("release_date"):
        parts.append(f"Released: {row['release_date'].date().isoformat()}")
    if row.get("language"):
        parts.append(f"Languages: {', '.join(row['language'])}")
    if row.get("country"):
        parts.append(f"Countries: {', '.join(row['country'])}")
    if row.get("actors"):
        parts.append(f"Cast: {', '.join(row['actors'])}")
    if row.get("tags"):
        parts.append(f"Tags: {', '.join(row['tags'])}")
    if row.get("description"):
        parts.append(f"Description: {row['description']}")
    return "\n".join(parts)


def embed_batch(texts: list[str]) -> list[list[float]]:
    resp = client.embeddings.create(model=EMBED_MODEL, input=texts)
    return [d.embedding for d in resp.data]


def main() -> None:
    rows = fetch_all_movies()
    print(f"Fetched {len(rows)} movies")
    if not rows:
        return

    sample_text = ""
    sample_dim = 0
    done = 0
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        texts = [build_text(r) for r in batch]
        vectors = embed_batch(texts)
        update_embeddings([(r["id"], v) for r, v in zip(batch, vectors)])
        done += len(batch)
        if not sample_text:
            sample_text = texts[0]
            sample_dim = len(vectors[0])
        print(f"Embedded + stored {done} / {len(rows)}")

    print(f"\nSample: dim={sample_dim}")
    print("--- text ---")
    print(sample_text)
    print(f"\nrag_embedding populated rows: {count_embedded()} / {len(rows)}")


if __name__ == "__main__":
    main()
