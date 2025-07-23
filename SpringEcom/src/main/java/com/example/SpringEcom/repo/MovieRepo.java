package com.example.SpringEcom.repo;

import com.example.SpringEcom.model.Movie;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

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
}
