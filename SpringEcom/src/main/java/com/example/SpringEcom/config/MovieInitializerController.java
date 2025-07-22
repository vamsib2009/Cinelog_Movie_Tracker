package com.example.SpringEcom.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import javax.sql.DataSource;

@Controller
public class MovieInitializerController {
    @Autowired
    private MovieInitializer movieInitializer;
    @Autowired
    private JdbcTemplate jdbcTemplate;



    @GetMapping("/init")
    public String init(){
        movieInitializer.loadMoviesFromJSONL();
        return "next step after service is called";
    }

    @GetMapping("/check-embeddings")
    public ResponseEntity<?> checkEmbeddings() {
        Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM poster_embeddings", Integer.class);
        return ResponseEntity.ok("✅ Embedding count in DB: " + count);
    }

}
