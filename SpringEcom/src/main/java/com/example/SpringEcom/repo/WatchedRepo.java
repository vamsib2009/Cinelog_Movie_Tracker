package com.example.SpringEcom.repo;


import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import com.example.SpringEcom.model.Watched;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;


@Repository
public interface WatchedRepo extends JpaRepository<Watched, Integer> {

    //get count of how many users have watched a movie
    Integer countByMovie(Movie movie);


    //Toggle the watch status (check by user and movie)
    Optional<Watched> findByUserAndMovie(User user, Movie movie);


    void deleteByUserAndMovie(User user, Movie movie);

    //Get all watched movies by a particular user
    List<Movie> findByUser(User user);

    //get count of how many movies a user has watched
    Integer countByUser(User user);
}
