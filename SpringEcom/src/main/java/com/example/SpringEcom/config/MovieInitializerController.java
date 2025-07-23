package com.example.SpringEcom.config;

import com.example.SpringEcom.repo.PosterEmbeddingRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import redis.clients.jedis.JedisPooled;

import javax.sql.DataSource;

@Controller
public class MovieInitializerController {
    @Autowired
    private MovieInitializer movieInitializer;
    @Autowired
    private PosterEmbeddingRepo posterEmbeddingRepo;

    @Autowired
    private JedisPooled jedis;

    @GetMapping("/init")
    public String init(){
        movieInitializer.loadMoviesFromJSONL();
        return "next step after service is called";
    }


    @GetMapping("/check-embeddings")
    public ResponseEntity<String> checkPosterEmbeddings() {
        long count = posterEmbeddingRepo.count();
        if(count == 0) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("No Embeddings in DB");
        }
        else {
            return ResponseEntity.ok("Embeddings present in DB");
        }
    }

}
