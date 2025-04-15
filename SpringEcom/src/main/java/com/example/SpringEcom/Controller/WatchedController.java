package com.example.SpringEcom.Controller;


import com.example.SpringEcom.service.WatchedService;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.*;

@RestController
@RequestMapping("/watched")
public class WatchedController {

    //Inject watchedService
    @Autowired
    public WatchedService watchedService;


    //How many movies a user has watched
    @GetMapping("/countuser")
    public ResponseEntity<?> getCountByUser(@RequestParam Integer userId) {
        return ResponseEntity.ok().body(watchedService.getCountWatchedByUser(userId));
    }

    //How many users have watched a movie
    @GetMapping("/countmovie")
    public ResponseEntity<?> getCountByMovie(@RequestParam Integer movieId) {
        return ResponseEntity.ok().body(watchedService.getCountWatchedByMovie(movieId));
    }

    @PutMapping("/toggle")
    public ResponseEntity<Boolean> toggleWatched(@RequestParam Integer userId, @RequestParam Integer movieId) {
        return ResponseEntity.ok().body(watchedService.toggleWatched(userId, movieId));
    }

    //Get watched or not watched
    @GetMapping("/getwatched")
    public ResponseEntity<UserMovieRatingDTO> getWatched(@RequestParam Integer userId, @RequestParam Integer movieId) {
        Boolean watched = watchedService.getWatched(userId, movieId);
        Float rating = watchedService.getUserRa(userId, movieId);
        String review = watchedService.getUserRe(userId, movieId);

        Float safeRating = (rating != null) ? rating : 0.0f;
        String safeReview = (review != null) ? review : "No review yet";

        UserMovieRatingDTO udto = new UserMovieRatingDTO(watched, safeRating, safeReview);

        return ResponseEntity.ok().body(udto);
    }

    @Data
    public static class UserMovieRatingDTO {
        private Boolean watched;
        private Float userRating;
        private String userReview;

        // Constructors
        public UserMovieRatingDTO(Boolean watched, Float userRating, String userReview) {
            this.watched = watched;
            this.userRating = userRating;
            this.userReview = userReview;
        }

        // Getters and Setters
    }


//    @GetMapping("/getur")
//    public ResponseEntity<Map<Float, String>> getRatings(@RequestParam Integer userId, @RequestParam Integer movieId) {
//        return ResponseEntity.ok().body(watchedService.getUR(userId, movieId));
//    }


    //Update user Rating for that user for that movie
    @PutMapping("/updaterating")
    public ResponseEntity<String> addPersonalMovieRating(@RequestBody RatingRequest request) {
        try {
            System.out.println(request.toString());
            watchedService.addOrUpdateRating(request.getMovieId(), request.getUserId(), request.getUserRating(), request.getUserReview());
            System.out.println("Here");
            return new ResponseEntity<>("Updated", HttpStatus.OK);
        } catch (IOException e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }


        // DTO for JSON Request. getter setter implemented using Lomb

    }

    @Data
    public static class RatingRequest {
        private int id;
        private Float userRating;
        private String userReview;
        private Integer movieId;
        private Integer userId;

    }
}
