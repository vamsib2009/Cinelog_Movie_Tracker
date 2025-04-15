package com.example.SpringEcom.service;

import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.User;
import com.example.SpringEcom.model.Favorites;
import com.example.SpringEcom.repo.FavoriteRepo;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class FavoriteService{

    //Inject all three repo
    @Autowired
    private FavoriteRepo favoriteRepo;

    @Autowired
    private UserRepo userRepo;

    @Autowired
    private MovieRepo movieRepo;

    public boolean addFavorite(Integer userId, Integer movieId){
        Optional<User> user = userRepo.findById(userId);
        Optional<Movie> movie = movieRepo.findById(movieId);

        if(user.isPresent() && movie.isPresent()){
            //Here the .get() method is to get an entire object instead of a field in the object
            if(!favoriteRepo.existsByUserAndMovie(user.get(), movie.get())){
                Favorites favorite = new Favorites();
                favorite.setUser(user.get());
                favorite.setMovie(movie.get());
                favoriteRepo.save(favorite);
                return true;
            }
        }
        return false;
    }

    public List<Movie> getFavorites(Integer userId)
    {
        User user = userRepo.findById(userId).orElseThrow(() -> new RuntimeException("No User with that ID Found"));

        return favoriteRepo.findByUser(Optional.ofNullable(user))
                .stream()
                .map(Favorites::getMovie)
                .collect(Collectors.toList())
                ;
    }

    //This func counts how many Users have favorited a movie
    public Optional<Integer> getFav(Integer movieId)
    {
        System.out.println(favoriteRepo.getNoOfFavorites(movieId));
        return favoriteRepo.getNoOfFavorites(movieId);
       }

    public boolean deleteFavorite(Integer userId, Integer movieId){
        Optional<User> user = userRepo.findById(userId);
        Optional<Movie> movie = movieRepo.findById(movieId);

        if(user.isPresent() && movie.isPresent()){

            Optional<Favorites> favorite = favoriteRepo.getByUserAndMovie(user.get(), movie.get());

            if(favorite.isPresent()) {
                favoriteRepo.delete(favorite.get());
                return true;
            }
        }
        return false;

    }
}
