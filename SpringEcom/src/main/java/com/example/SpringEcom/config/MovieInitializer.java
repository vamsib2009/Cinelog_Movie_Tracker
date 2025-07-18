//package com.example.SpringEcom.config;
//
//import com.example.SpringEcom.model.Category;
//import com.example.SpringEcom.model.Movie;
//import com.example.SpringEcom.repo.MovieRepo;
//import jakarta.annotation.PostConstruct;
//import jakarta.annotation.PreDestroy;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.core.io.Resource;
//import org.springframework.stereotype.Component;
//
//import java.io.BufferedReader;
//import java.io.InputStreamReader;
//import java.time.LocalDate;
//import java.time.ZoneId;
//import java.time.format.DateTimeFormatter;
//import java.util.*;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import com.fasterxml.jackson.databind.JsonNode;
//import org.springframework.core.io.Resource;
//
//import java.io.BufferedReader;
//import java.io.InputStreamReader;
//import java.time.LocalDate;
//import java.time.ZoneId;
//import java.util.*;
//
//
//@Component
//public class MovieInitializer {
//
//    private final MovieRepo movieRepository;
//    private final List<Integer> insertedIds = new ArrayList<>();
//
//    @Value("classpath:movies.csv")
//    private Resource csvResource;
//
//    public MovieInitializer(MovieRepo movieRepository) {
//        this.movieRepository = movieRepository;
//    }
//
////    @PostConstruct
////    public void loadMoviesFromCSV() {
////        try (BufferedReader reader = new BufferedReader(new InputStreamReader(csvResource.getInputStream()))) {
////            String line = reader.readLine(); // Skip header
////            while ((line = reader.readLine()) != null) {
////                String[] parts = line.split(",");
////
////                String name = parts[0].trim();
////                String directorName = parts[2].trim();
////                LocalDate localDate = LocalDate.parse(parts[5].trim());
////                Date releaseDate = Date.from(localDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
////
////                // Check if movie already exists
////                Optional<Movie> existing = movieRepository.findByNameAndDirectorNameAndReleaseDate(
////                        name, directorName, releaseDate
////                );
////
////                if (existing.isPresent()) {
////                    continue; // Skip duplicates
////                }
////
////                // Parse & save new movie
////                Movie movie = new Movie();
////                movie.setName(name);
////                movie.setDescription(parts[1].trim());
////                movie.setDirectorName(directorName);
////                movie.setCategory(Category.valueOf(parts[3].trim()));
////                movie.setImdbrating(Float.parseFloat(parts[4].trim()));
////                movie.setReleaseDate(releaseDate);
////                movie.setLanguage(parts[6].trim());
////                movie.setCountry(parts[7].trim());
////                movie.setActorNames(Arrays.asList(parts[8].trim().split("\\|")));
////                movie.setTags(Arrays.asList(parts[9].trim().split("\\|")));
////
////                movieRepository.save(movie);
////            }
////
////            System.out.println("✅ Movies loaded from CSV if not already present.");
////        } catch (Exception e) {
////            e.printStackTrace();
////        }
////    }
//
//    @Value("classpath:movies.jsonl")
//    private Resource jsonlResource;
//
//
//    @PostConstruct
//    public void loadMoviesFromJSONL() {
//        ObjectMapper objectMapper = new ObjectMapper();
//
//        try (BufferedReader reader = new BufferedReader(new InputStreamReader(jsonlResource.getInputStream()))) {
//            String line;
//
//            while ((line = reader.readLine()) != null) {
//                try {
//                    JsonNode json = objectMapper.readTree(line);
//
//                    String name = json.get("title").asText();
//                    String directorName = json.get("director").asText();
//                    String releaseDateStr = json.get("release_date").asText();
//
//                    // Skip if required fields are missing or null
//                    if (name == null || directorName == null || releaseDateStr == null) {
//                        System.err.println("Skipping movie due to missing required fields");
//                        continue;
//                    }
//
//                    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);
//                    LocalDate localDate;
//                    try {
//                        localDate = LocalDate.parse(releaseDateStr, formatter);
//                    } catch (Exception e) {
//                        System.err.println("Skipping movie '" + name + "' due to invalid date format: " + releaseDateStr);
//                        continue;
//                    }
//
//                    Date releaseDate = Date.from(localDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
//
//                    Optional<Movie> existing = movieRepository.findByNameAndDirectorNameAndReleaseDate(
//                            name, directorName, releaseDate
//                    );
//                    if (existing.isPresent()) {
//                        continue; // Skip duplicates
//                    }
//
//                    Movie movie = new Movie();
//                    movie.setName(name);
//                    movie.setDescription(json.get("plot").asText());
//                    movie.setDirectorName(directorName);
//
//                    try {
//                        movie.setCategory(Category.valueOf(json.get("genre").asText()));
//                    } catch (IllegalArgumentException e) {
//                        movie.setCategory(Category.SciFi); // fallback
//                    }
//
//                    try {
//                        movie.setImdbrating(Float.parseFloat(json.get("rating").asText()));
//                    } catch (NumberFormatException e) {
//                        System.err.println("Skipping movie '" + name + "' due to invalid rating format");
//                        continue;
//                    }
//
//                    movie.setReleaseDate(releaseDate);
//                    movie.setLanguage(List.of(json.get("language").asText().split("\\|")));
//                    movie.setCountry(List.of(json.get("country").asText().split("\\|")));
//                    movie.setActorNames(Arrays.asList(json.get("cast").asText().split("\\|")));
//                    movie.setTags(Arrays.asList(json.get("tags").asText().split("\\|")));
//
//                    movieRepository.save(movie);
//
//                } catch (Exception e) {
//                    System.err.println("Error processing movie entry: " + e.getMessage());
//                    continue; // Skip this movie and continue with the next one
//                }
//            }
//
//            System.out.println("✅ Movies loaded from JSONL if not already present.");
//        } catch (Exception e) {
//            System.err.println("❌ Error reading JSONL file: " + e.getMessage());
//            e.printStackTrace();
//        }
//    }
//
//    @PreDestroy
//    public void cleanupMovies() {
//        try {
//            movieRepository.deleteAllById(insertedIds);
//            System.out.println("🧹 Cleaned up CSV-loaded movies.");
//        } catch (Exception e) {
//            System.err.println("❌ Failed to clean up inserted movies.");
//            e.printStackTrace();
//        }
//    }
//}
