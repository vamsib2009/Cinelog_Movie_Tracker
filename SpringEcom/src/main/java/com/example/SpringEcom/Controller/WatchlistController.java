package com.example.SpringEcom.Controller;

import com.example.SpringEcom.model.Watchlist;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.service.WatchlistService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/watchlist")
public class WatchlistController {

    @Autowired
    private WatchlistService watchlistService;
    //Constructor Injection

    @PostMapping("/add")
    public ResponseEntity<String> addWatchlist(@RequestParam Integer userId, @RequestParam Integer movieId) {
        boolean added = watchlistService.addWatchlist(userId, movieId);
        if (added) {
            return ResponseEntity.ok("Movie added to Watchlist!");
        } else {
            return ResponseEntity.badRequest().body("Movie is already in watchlist or invalid user/movie.");
        }
    }

    @PostMapping("/get")
    public ResponseEntity<List<Movie>> getWatchlist(@RequestParam Integer userId) {
        return new ResponseEntity<>(watchlistService.getWatchlist(userId), HttpStatus.OK);
    }

    @PostMapping("/delete")
    public ResponseEntity<String> deleteWatchlist(@RequestParam Integer userId, @RequestParam Integer movieId) {
        boolean deleted = watchlistService.deleteWatchlist(userId, movieId);
        if(deleted) {
            return ResponseEntity.ok("Movie deleted from Watchlist!");
        }
        else
        {
            return ResponseEntity.badRequest().body("Issue deleting from Watchlist");
        }
    }

}

