package com.example.SpringEcom.repo;

import com.example.SpringEcom.model.Movie;
import org.springframework.ai.observation.conventions.VectorStoreSimilarityMetric;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Date;
import java.util.List;
import java.util.Optional;

//The integer represents the type of the primary key
public interface MovieRepo extends JpaRepository<Movie, Integer> {

    //name category description
    //DSL domain specific language
    //Query in JPQL format
    @Query("SELECT p FROM Movie p WHERE " +
            "LOWER(COALESCE(p.name, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(p.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(p.category, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(p.directorName, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Movie> searchMovies(String keyword);

    Optional<Movie> findByNameAndDirectorNameAndReleaseDate(String name, String directorName, Date releaseDate);

    Page<Movie> findAll(Pageable pageable);

    Movie findMovieById(Integer id);


//    //Poster related stuff
//    @Query("""
//        SELECT p.movie
//        FROM Movie p
//        WHERE p.id != :movieId
//        ORDER BY cosine_distance(
//            p.plot_embedding,
//            (SELECT p2.plot_embedding FROM Movie p2 WHERE p2.movie.id = :movieId)
//        )
//        LIMIT :limit
//    """)
//    List<Movie> findSimilarMoviePosters(@Param("movieId") Integer movieId, @Param("limit") int limit);

    //Cosine Similarity
    @Query(value = """
    SELECT * FROM movie
    WHERE id != :movieId
    ORDER BY poster_embedding <-> CAST(:embedding AS vector)
    LIMIT :limit
    """, nativeQuery = true)
    List<Movie> searchByPosterEmbedding(
            @Param("embedding") float[] embedding,
            @Param("movieId") Integer movieId,
            @Param("limit") int limit
    );

}
