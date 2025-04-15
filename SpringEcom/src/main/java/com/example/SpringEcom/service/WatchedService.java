package com.example.SpringEcom.service;

import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import com.example.SpringEcom.model.Watched;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.UserRepo;
import com.example.SpringEcom.repo.WatchedRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
public class WatchedService {

    @Autowired
    private WatchedRepo watchedRepo;

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private MovieRepo movieRepo;

    //Get How many movies a user has watched
    public Integer getCountWatchedByUser(Integer userId)
    {
        Optional<User> user = userRepo.findById(userId);

        if(user.isPresent())
        {
            return watchedRepo.countByUser(user.get());
        }
        else
        {
            return 0;
        }
    }

    public Optional<Integer> getCountWatchedByMovie(Integer movieId) {
        Optional<Movie> movie = movieRepo.findById(movieId);

        if (movie.isPresent()) {
            Integer count = watchedRepo.countByMovie(movie.get()); // Assuming this returns an Integer
            return Optional.of(count); // Wrap it in Optional
        } else {
            return Optional.of(0); // Ensure return type matches Optional<Integer>
        }
    }


    //Toggle the watch status
    @Transactional
    public boolean toggleWatched(Integer userId, Integer movieId)
    {
        Optional<User> userOpt = userRepo.findById(userId);
        Optional<Movie> movieOpt = movieRepo.findById(movieId);

        if(userOpt.isPresent() && movieOpt.isPresent()){
            User user = userOpt.get();
            Movie movie = movieOpt.get();

            Optional<Watched> w = watchedRepo.findByUserAndMovie(user, movie);

            if(w.isPresent())
            {
                watchedRepo.deleteByUserAndMovie(user, movie);
                watchedRepo.flush(); // Ensure the delete operation is committed immediately
                return false;
            }
            else{
                Watched watched = new Watched();
                watched.setMovie(movie);
                watched.setUser(user);
                watched.setWatchedTime(LocalDateTime.now());
                watchedRepo.save(watched);
                return true;
            }
        }

        return false;

    }

    //Get whether a movie is watched by the user or not
    public boolean getWatched(Integer userId, Integer movieId) {
        Optional<User> userOpt = userRepo.findById(userId);
        Optional<Movie> movieOpt = movieRepo.findById(movieId);

        if (userOpt.isPresent() && movieOpt.isPresent()) {
            User user = userOpt.get();
            Movie movie = movieOpt.get();

            Optional<Watched> w = watchedRepo.findByUserAndMovie(user, movie);

            if (w.isPresent()) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    @Transactional
    public void addOrUpdateRating (Integer  movieId, Integer userId, Float userRating, String userReview) throws IOException {
        Optional<User> userOpt = userRepo.findById(userId);
        Optional<Movie> movieOpt = movieRepo.findById(movieId);

        Optional<Watched> up_movie = watchedRepo.findByUserAndMovie(userOpt.get(), movieOpt.get());


        if (up_movie.isPresent()) {
            Watched updatedmovie = up_movie.get();
            updatedmovie.setURa(userRating);
            updatedmovie.setURe(userReview);
            watchedRepo.save(updatedmovie);
            System.out.println(up_movie.toString());
        }
        else {
            Watched watched = new Watched();
            watched.setMovie(movieOpt.get());
            watched.setUser(userOpt.get());
            watched.setURa(userRating);
            watched.setURe(userReview);
            watchedRepo.save(watched);
            System.out.println(up_movie.toString());
        }
    }

    public Float getUserRa(Integer  userId, Integer movieId) {
        Optional<User> userOpt = userRepo.findById(userId);
        Optional<Movie> movieOpt = movieRepo.findById(movieId);

        if(userOpt.isPresent() && movieOpt.isPresent()) {
            return watchedRepo.findByUserAndMovie(userOpt.get(), movieOpt.get())
                    .map(Watched::getURa)
                    .orElse(null);
        }
        return null;
    }

    public String getUserRe(Integer  userId, Integer movieId) {
        Optional<User> userOpt = userRepo.findById(userId);
        Optional<Movie> movieOpt = movieRepo.findById(movieId);

        if(userOpt.isPresent() && movieOpt.isPresent()) {
            return watchedRepo.findByUserAndMovie(userOpt.get(), movieOpt.get())
                    .map(Watched::getURe)
                    .orElse(null);
        }
        return null;
    }
}
