package com.example.SpringEcom.repo;

import com.example.SpringEcom.model.PosterEmbeddings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PosterEmbeddingRepo extends JpaRepository<PosterEmbeddings, Integer> {

    @Query("""
        SELECT p.movie.id
        FROM PosterEmbeddings p
        WHERE p.movie.id != :movieId
        ORDER BY cosine_distance(
            p.embedding,
            (SELECT p2.embedding FROM PosterEmbeddings p2 WHERE p2.movie.id = :movieId)
        )
        LIMIT :limit
    """)
    List<Integer> findSimilarMovieIds(@Param("movieId") Integer movieId, @Param("limit") int limit);

}
