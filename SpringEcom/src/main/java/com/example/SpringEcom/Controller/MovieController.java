package com.example.SpringEcom.Controller;

import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.service.LoggingService;
import com.example.SpringEcom.service.MovieService;
//import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Date;
import java.util.List;

@CrossOrigin(origins = "*")  // Allow from all origins (you can restrict it to "http://localhost:3000" if needed)
@RestController
@RequestMapping("/api")
public class MovieController {

    @Autowired
    private MovieService movieService;

    @Autowired
    private LoggingService loggingService;

    @Transactional
    @GetMapping("/movies")
    public ResponseEntity<List<Movie>> getMovies(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<Movie> moviePage = movieService.getPaginatedMovies(page, size);
        return ResponseEntity.ok(moviePage.getContent());
    }

    @GetMapping("/movies/{id}")
    public ResponseEntity<Movie> getMovieById(@PathVariable int id){
        Movie movie = movieService.getMovieById(id);

        if(movie!= null)
            return new ResponseEntity<>(movie, HttpStatus.OK);
        else
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @GetMapping("/manualtesting")
    public String sendstr() { return "Testing 1 2 3...";}

    
    //Endpoint to add movies from admin console
    @PostMapping("/addmovie")
    public ResponseEntity<String> addMoviesFromAdmin(@RequestBody Movie movie)
    {
        //I guess JSON automatically mapped to Movie entity
        try {
            movieService.addMovie(movie);
            return ResponseEntity.ok("Added Movie");
        }
        catch (Exception e)
        {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
        }

    }


    //Search for something
    @GetMapping("/search")
    public ResponseEntity<List<Movie>> searchMovies(@RequestParam String keyword){
        List<Movie> movies = movieService.searchMovies(keyword);
        return new ResponseEntity<>(movies, HttpStatus.OK);
    }

    @GetMapping("/trending")
    public ResponseEntity<?> getTrendingMovies()
    {
        List<Movie> movies = loggingService.getTrending();
        return new ResponseEntity<>(movies, HttpStatus.OK);
    }


    //Add Image to a certain query
//    @PutMapping("/movies/{id}")
//    public ResponseEntity<String> updateMovie(@PathVariable int id, @RequestPart Movie movie, @RequestPart MultipartFile imageFile){
//        Movie updatedMovie = null;
//        try{
//            updatedMovie = movieService.updateMovie(movie, imageFile);
//            return new ResponseEntity<>("Updated", HttpStatus.OK);
//        }
//        catch (IOException e){
//            return new ResponseEntity<>(e.getMessage(), HttpStatus.BAD_REQUEST);
//        }
//    }
}
