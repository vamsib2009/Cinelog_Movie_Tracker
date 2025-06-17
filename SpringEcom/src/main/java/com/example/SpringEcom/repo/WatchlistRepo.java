package com.example.SpringEcom.repo;

import com.example.SpringEcom.model.Watchlist;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface WatchlistRepo extends JpaRepository<Watchlist, Integer> {
    List<Watchlist> findByUser(Optional<User> user);


    boolean existsByUserAndMovie(User user, Movie movie);

    Optional<Watchlist> getByUserAndMovie(User user, Movie movie);

    @Query(value = "SELECT COUNT(DISTINCT user_id) FROM favorites WHERE movie_id = ?1", nativeQuery = true)
    Optional<Integer> getNoOfWatchlist(Integer movieId);
}
