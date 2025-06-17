package com.example.SpringEcom.service;

import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import com.example.SpringEcom.model.Watchlist;
import com.example.SpringEcom.repo.WatchlistRepo;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class WatchlistService{

    //Inject all three repo
    @Autowired
    private WatchlistRepo watchlistRepo;

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private MovieRepo movieRepo;

    public boolean addWatchlist(Integer userId, Integer movieId){
        Optional<User> user = userRepo.findById(userId);
        Optional<Movie> movie = movieRepo.findById(movieId);

        if(user.isPresent() && movie.isPresent()){
            //Here the .get() method is to get an entire object instead of a field in the object
            if(!watchlistRepo.existsByUserAndMovie(user.get(), movie.get())){
                Watchlist watchlist = new Watchlist();
                watchlist.setUser(user.get());
                watchlist.setMovie(movie.get());
                watchlistRepo.save(watchlist);
                return true;
            }
        }
        return false;
    }

    public List<Movie> getWatchlist(Integer userId)
    {
        User user = userRepo.findById(userId).orElseThrow(() -> new RuntimeException("No User with that ID Found"));

        return watchlistRepo.findByUser(Optional.ofNullable(user))
                .stream()
                .map(Watchlist::getMovie)
                .collect(Collectors.toList())
                ;
    }

    //This func counts how many Users have favorited a movie
    public Optional<Integer> getWatchlistcount(Integer movieId)
    {
        //System.out.println(favoriteRepo.getNoOfFavorites(movieId));
        return watchlistRepo.getNoOfWatchlist(movieId);
    }

    public boolean deleteWatchlist(Integer userId, Integer movieId){
        Optional<User> user = userRepo.findById(userId);
        Optional<Movie> movie = movieRepo.findById(movieId);

        if(user.isPresent() && movie.isPresent()){

            Optional<Watchlist> watchlist = watchlistRepo.getByUserAndMovie(user.get(), movie.get());

            if(watchlist.isPresent()) {
                watchlistRepo.delete(watchlist.get());
                return true;
            }
        }
        return false;

    }
}
