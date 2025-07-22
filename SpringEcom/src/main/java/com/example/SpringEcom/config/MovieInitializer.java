package com.example.SpringEcom.config;

import com.example.SpringEcom.model.Category;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.repo.MovieRepo;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;


@Service
public class MovieInitializer {

    private final MovieRepo movieRepository;
    private final DataSource dataSource;

    private final List<Integer> insertedIds = new ArrayList<>();

    public MovieInitializer(MovieRepo movieRepository, DataSource dataSource) {
        this.movieRepository = movieRepository;
        this.dataSource = dataSource;
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
                    movie.setDescription(json.get("plot").asText());
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

                    Movie saved = movieRepository.save(movie);

                    // Extract embedding array
                    JsonNode embeddingNode = json.get("poster_embedding");
                    if (embeddingNode == null || !embeddingNode.isArray() || embeddingNode.size() != 512) {
                        System.out.println("⚠️ Skipping embedding insert for '" + name + "' due to missing/invalid embedding.");
                        continue;
                    }

                    // Convert to vector string format for pgvector
                    StringBuilder embeddingStr = new StringBuilder("[");
                    for (int j = 0; j < embeddingNode.size(); j++) {
                        embeddingStr.append(embeddingNode.get(j).asDouble());
                        if (j < embeddingNode.size() - 1) embeddingStr.append(",");
                    }
                    embeddingStr.append("]");

                    // Insert into poster_embeddings table
                    String sql = "INSERT INTO poster_embeddings (movie_id, embedding) VALUES (?, ?)";

                    try (Connection conn = dataSource.getConnection();
                         PreparedStatement ps = conn.prepareStatement(sql)) {
                        System.out.println("Preparing to insert embedding for movie ID: " + saved.getId());
                        System.out.println("Embedding vector: " + embeddingStr);
                        conn.setAutoCommit(true);  // OR false + commit()
                        ps.setInt(1, saved.getId());
                        ps.setObject(2, embeddingStr.toString(), Types.OTHER); // pgvector handles VECTOR casting
                        System.out.println("Preparing to insert embedding for movie ID: " + saved.getId());
                        ps.executeUpdate();
                        System.out.println("Inserted embedding for movie '" + name + "' with ID " + saved.getId() + "");

                    } catch (Exception e) {
                        System.err.println("❌ Failed to insert embedding for movie '" + name + "': " + e.getMessage());
                    }


                } catch (Exception e) {
                    System.err.println("Error processing movie entry: " + e.getMessage());
                    continue; // Skip this movie and continue with the next one
                }
            }

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
}
