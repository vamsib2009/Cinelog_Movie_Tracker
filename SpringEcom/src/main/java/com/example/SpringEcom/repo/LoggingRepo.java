package com.example.SpringEcom.repo;


import com.example.SpringEcom.model.Logging;
import com.example.SpringEcom.model.Movie;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface LoggingRepo extends JpaRepository<Logging, Integer> {

    //Count of total number of assesses for Movie global

    @Query(value = "SELECT COUNT(*) FROM logging WHERE movie_id = ?1",
    nativeQuery = true)
    Integer findMovietotalnoofAccesses(Integer movieId);

    @Query(value = "SELECT COUNT(*) FROM logging WHERE movie_id = ?1 and user_id = ?2",
    nativeQuery = true)
    Integer findMovieAccessesByUser(Integer movieId, Integer userId);

    //@Query(value = "SELECT movie.* FROM movie WHERE movie.id IN (SELECT movie_id FROM logging GROUP BY movie_id ORDER BY COUNT(*) DESC LIMIT 3)")
    @Query(value = "SELECT m.* FROM movie m JOIN (SELECT movie_id FROM logging GROUP BY movie_id ORDER BY COUNT(*) DESC LIMIT 3) top_movies ON m.id = top_movies.movie_id", nativeQuery = true)
    List<Movie> findTrendingTop3();

}
