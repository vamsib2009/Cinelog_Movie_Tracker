//package com.example.SpringEcom.config;
//
//import jakarta.annotation.PostConstruct;
//import lombok.RequiredArgsConstructor;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.jdbc.core.JdbcTemplate;
//
//@Configuration
//@RequiredArgsConstructor
//public class AIConfig {
//
//    private final JdbcTemplate jdbcTemplate;
//
//    @PostConstruct
//    public void initVectorTables() {
//        System.out.println("🧠 Initializing vector tables");
//
//        jdbcTemplate.execute("CREATE EXTENSION IF NOT EXISTS vector;");
//        jdbcTemplate.execute("""
//            CREATE TABLE poster_embeddings (
//                id SERIAL PRIMARY KEY,
//                movie_id INT,
//                embedding VECTOR(512)
//            );
//        """);
//        System.out.println("✅ Vector table created successfully");
//    }
//}
