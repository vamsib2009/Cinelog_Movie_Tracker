package com.example.SpringEcom.service;

import com.example.SpringEcom.model.Logging;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import com.example.SpringEcom.repo.LoggingRepo;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class LoggingService {

    //Inject UserRepo and MovieRepo because we need to fetch the movie+user
    @Autowired
    private UserRepo userRepo;
    @Autowired
    private MovieRepo movieRepo;

    //Inject the LoggingRepo for fetch calls
    @Autowired
    private LoggingRepo loggingRepo;


    public boolean addLog(Integer userId, Integer movieId)
    {
        //Create optional just for formality of null safety
        Optional<User> user = userRepo.findById(userId);
        Optional<Movie> movie = movieRepo.findById(movieId);

        if(user.isPresent() && movie.isPresent())
        {
            Logging logging = new Logging();
            //.get() method to get the entire object
            logging.setUser(user.get());
            logging.setMovie(movie.get());
            loggingRepo.save(logging);
            return true;
        }
        return false;
    }

    //Implement logic for getting number of accesses
    public Optional<Integer> getViews(Integer movieId, Integer userId)
    {

        //Total number of accesses for one movie
        if(userId == null && movieId != null)
        {
            //If non-null returns a empty Optional which can be easily checked in the container
            System.out.println("Total Views Repo access called");
            return Optional.ofNullable(loggingRepo.findMovietotalnoofAccesses(movieId));
        }

        //Total number of accesses for one movie based on that user
        else if(userId != null && movieId != null)
        {
            return Optional.ofNullable(loggingRepo.findMovieAccessesByUser(movieId, userId));
        }
        else
        {
            return Optional.ofNullable(null);  //Or Optional.empty()
        }
    }

    //For Trending
    public List<Movie> getTrending()
    {
        return loggingRepo.findTrendingTop3();
    }




}
