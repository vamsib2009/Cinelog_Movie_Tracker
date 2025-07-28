package com.example.SpringEcom.config;

import com.example.SpringEcom.model.Category;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.repo.MovieRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;


@Service
public class MovieInitializer {

    private final MovieRepo movieRepository;

    private final List<Integer> insertedIds = new ArrayList<>();

    @Autowired
    public MovieInitializer(MovieRepo movieRepository) {
        this.movieRepository = movieRepository;
    }

    @Value("classpath:movies.jsonl")
    private Resource jsonlResource;


    public void loadMoviesFromJSONL() {
        ObjectMapper objectMapper = new ObjectMapper();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(jsonlResource.getInputStream()))) {
            String line;

            while ((line = reader.readLine()) != null) {
                try {
                    JsonNode json = objectMapper.readTree(line);

                    String name = json.get("title").asText();
                    String directorName = json.get("director").asText();
                    String releaseDateStr = json.get("release_date").asText();
                    String plot = json.get("plot").asText();

                    // Skip if required fields are missing or null
                    if (name == null || directorName == null || releaseDateStr == null) {
                        System.err.println("Skipping movie due to missing required fields");
                        continue;
                    }

                    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);
                    LocalDate localDate;
                    try {
                        localDate = LocalDate.parse(releaseDateStr, formatter);
                    } catch (Exception e) {
                        System.err.println("Skipping movie '" + name + "' due to invalid date format: " + releaseDateStr);
                        continue;
                    }

                    Date releaseDate = Date.from(localDate.atStartOfDay(ZoneId.systemDefault()).toInstant());

                    Optional<Movie> existing = movieRepository.findByNameAndDirectorNameAndReleaseDate(
                            name, directorName, releaseDate
                    );
                    if (existing.isPresent()) {
                        System.out.println("Skipping movie due to existing record");
                        continue; // Skip duplicates
                    }

                    Movie movie = new Movie();
                    movie.setName(name);
                    movie.setDescription(plot);
                    movie.setDirectorName(directorName);

                    try {
                        movie.setCategory(Category.valueOf(json.get("genre").asText()));
                    } catch (IllegalArgumentException e) {
                        movie.setCategory(Category.SciFi); // fallback
                    }

                    try {
                        movie.setImdbrating(Float.parseFloat(json.get("rating").asText()));
                    } catch (NumberFormatException e) {
                        System.err.println("Skipping movie '" + name + "' due to invalid rating format");
                        continue;
                    }

                    movie.setReleaseDate(releaseDate);
                    movie.setLanguage(List.of(json.get("language").asText().split("\\|")));
                    movie.setCountry(List.of(json.get("country").asText().split("\\|")));
                    movie.setActorNames(Arrays.asList(json.get("cast").asText().split("\\|")));
                    //Temporatily save as dummy
                    movie.setTags(Arrays.asList("dummy","dummy"));

                    float[] embeddingArray = new float[512];
                    for (int i = 0; i < embeddingArray.length; i++) {
                        embeddingArray[i] = Float.parseFloat(json.get("poster_embedding").get(i).asText());
                    }
                    movie.setPosterEmbedding(embeddingArray);

                    float[] plotEmbeddingArray = new float[512];
                    for (int i = 0; i < plotEmbeddingArray.length; i++) {
                        plotEmbeddingArray[i] = Float.parseFloat(json.get("plot_embedding").get(i).asText());
                    }
                    movie.setPlotEmbedding(plotEmbeddingArray);

                    Movie savedMovie = movieRepository.save(movie);



            System.out.println("✅ Movies loaded from JSONL if not already present.");
        } catch (Exception e) {
            System.err.println("❌ Error reading JSONL file: " + e.getMessage());
            e.printStackTrace();
        }
    }

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
} catch (IOException e) {
            throw new RuntimeException(e);
        }}}
