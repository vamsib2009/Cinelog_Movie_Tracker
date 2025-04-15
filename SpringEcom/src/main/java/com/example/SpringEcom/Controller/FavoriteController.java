package com.example.SpringEcom.Controller;

import com.example.SpringEcom.model.Favorites;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/favorites")
public class FavoriteController {

    FavoriteService favoriteService;
    //Constructor Injection
    private FavoriteController(FavoriteService favoriteService)
    {
        this.favoriteService = favoriteService;
    }

    @PostMapping("/add")
    public ResponseEntity<String> addFavorite(@RequestParam Integer userId, @RequestParam Integer movieId) {
        boolean added = favoriteService.addFavorite(userId, movieId);
        if (added) {
            return ResponseEntity.ok("Movie added to favorites!");
        } else {
            return ResponseEntity.badRequest().body("Movie is already in favorites or invalid user/movie.");
        }
    }

    @PostMapping("/get")
    public ResponseEntity<List<Movie>> getFavorites(@RequestParam Integer userId) {
        return new ResponseEntity<>(favoriteService.getFavorites(userId), HttpStatus.OK);
    }

    @PostMapping("/delete")
    public ResponseEntity<String> deleteFavorite(@RequestParam Integer userId, @RequestParam Integer movieId) {
        boolean deleted = favoriteService.deleteFavorite(userId, movieId);
        if(deleted) {
            return ResponseEntity.ok("Movie deleted from favorites!");
        }
        else
        {
            return ResponseEntity.badRequest().body("Issue deleting from favorites");
        }
    }

}

