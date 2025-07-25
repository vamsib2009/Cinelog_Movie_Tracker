package com.example.SpringEcom.config;


import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.PosterEmbeddings;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.PosterEmbeddingRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.ArrayList;
import java.util.List;

@Controller
public class EmbeddingsTestController {
    @Autowired
    private PosterEmbeddingRepo repository;
    @Autowired
    private MovieRepo movieRepo;


    @GetMapping("/posters/{movieId}/similar")
    public ResponseEntity<List<Movie>> findSimilarPosters(
            @PathVariable Integer movieId,
            @RequestParam(defaultValue = "5") int limit) {

        // Directly call the repository method and return the results
        List<Integer> similarItems = repository.findSimilarMovieIds(movieId, limit);
        List<Movie> m = new ArrayList<>();
        for (Integer id : similarItems) {
            // Process each 'id' one by one
            Movie moviex = movieRepo.findMovieById(id);
            m.add(moviex);
            // You could call another method here, e.g., movieService.getDetails(id);
        }


        return ResponseEntity.ok(m);
    }

    //Test the working in multimodal space From Plot to Poster
    @GetMapping("/posters/{movieId}/similarplot")
    public ResponseEntity<List<Movie>> findSimilarPostersfromPlot(
            @PathVariable Integer movieId,
            @RequestParam(defaultValue = "5") int limit) {

        // Directly call the repository method and return the results
        List<Integer> similarItems = repository.findPlotToPosterEmbeddings(movieId, limit);
        List<Movie> m = new ArrayList<>();
        for (Integer id : similarItems) {
            // Process each 'id' one by one
            Movie moviex = movieRepo.findMovieById(id);
            m.add(moviex);
            // You could call another method here, e.g., movieService.getDetails(id);
        }

        return ResponseEntity.ok(m);
    }


}
