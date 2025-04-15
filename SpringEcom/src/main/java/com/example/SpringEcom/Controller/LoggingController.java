package com.example.SpringEcom.Controller;


import com.example.SpringEcom.model.Logging;
import com.example.SpringEcom.service.FavoriteService;
import com.example.SpringEcom.service.LoggingService;
import com.example.SpringEcom.service.WatchedService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/logging")
public class LoggingController {
    //First inject the service
    @Autowired
    private LoggingService loggingService;

    @Autowired
    private FavoriteService favoriteService;

    @Autowired
    private WatchedService watchedService;

    @PostMapping("/add")
    public ResponseEntity<String> addLog(@RequestParam Integer userId, @RequestParam Integer movieId)
    {
        boolean logged = loggingService.addLog(userId, movieId);
        if(logged) return ResponseEntity.ok("Movie logged");
        else{
            return ResponseEntity.badRequest().body("Some issue registering the log. Check if movieid and userid are correct");
        }
    }

    @GetMapping("/get")
    //Response Entity in a template format
    public ResponseEntity<?> getAccesses(
            @RequestParam(required = false) Integer movieId,
            @RequestParam(required = false) Integer userId)
            //Actually using optional is better since it reminds the user to perform null checks
    {
        System.out.println("called");
        System.out.println("Movie ID called in Logging: " + movieId);
        System.out.println("User ID called in Logging: " + userId);
        Optional<Integer> fetchedViews = loggingService.getViews(movieId, userId);
        Optional<Integer> fetchedFav = favoriteService.getFav(movieId);
        Optional<Integer> fetchWatched = watchedService.getCountWatchedByMovie(movieId);

        ArrayList<Integer> mp = new ArrayList<>();

        if(fetchedViews.isPresent() && fetchedFav.isPresent() && fetchWatched.isPresent())
        {
            mp.add(fetchedViews.get());
            mp.add(fetchedFav.get());
            mp.add(fetchWatched.get());
            return ResponseEntity.ok(mp);
        }
        else{
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Not Present");
        }

    }



}
