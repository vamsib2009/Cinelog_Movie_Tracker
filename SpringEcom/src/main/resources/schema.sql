CREATE EXTENSION IF NOT EXISTS vector;


-- CREATE TABLE poster_embeddings (
--                                    id SERIAL PRIMARY KEY,
--                                    movie_id INT REFERENCES movie(id) ON DELETE CASCADE,
--                                        embedding vector(512) -- assuming CLIP regular size
-- );
--
-- -- 3. Optional: Add index for fast search
-- -- Use either L2, cosine, or inner product
-- CREATE INDEX ON poster_embeddings USING ivfflat (embedding vector_cosine_ops)
--     WITH (lists = 100);
--
-- CREATE TABLE plot_embeddings (
--                                    id SERIAL PRIMARY KEY,
--                                    movie_id INT REFERENCES movie(id) ON DELETE CASCADE,
--                                        embedding VECTOR(512) -- assuming CLIP regular size
-- );
--
-- -- 3. Optional: Add index for fast search
-- -- Use either L2, cosine, or inner product
-- CREATE INDEX ON plot_embeddings USING ivfflat (embedding vector_cosine_ops)
--     WITH (lists = 100);
--
