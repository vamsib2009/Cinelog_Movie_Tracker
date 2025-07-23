package com.example.SpringEcom.config;

import com.example.SpringEcom.model.Category;
import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.model.PlotEmbeddings;
import com.example.SpringEcom.model.PosterEmbeddings;
import com.example.SpringEcom.repo.MovieRepo;
import com.example.SpringEcom.repo.PlotEmbeddingRepo;
import com.example.SpringEcom.repo.PosterEmbeddingRepo;
import com.pgvector.PGvector;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.ai.content.Media;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
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
    private final VectorStore vectorStore;
    private final PosterEmbeddingRepo posterRepo;
    private final PlotEmbeddingRepo plotRepo;

    private final List<Integer> insertedIds = new ArrayList<>();

    @Autowired
    public MovieInitializer(MovieRepo movieRepository, DataSource dataSource, VectorStore vectorStore, PosterEmbeddingRepo posterRepo, PlotEmbeddingRepo plotRepo) {
        this.movieRepository = movieRepository;
        this.dataSource = dataSource;
        this.vectorStore = vectorStore;
        this.posterRepo = posterRepo;
        this.plotRepo = plotRepo;
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

                    Movie savedMovie = movieRepository.save(movie);

                    //Process Poster Embeddings
                    PosterEmbeddings posterEmbeddings = new PosterEmbeddings();

                    float[] embeddingArray = new float[512];
                    for (int i = 0; i < embeddingArray.length; i++) {
                        embeddingArray[i] = Float.parseFloat(json.get("poster_embedding").get(i).asText());
                    }
                    posterEmbeddings.setEmbedding(embeddingArray);
                    posterEmbeddings.setMovie(savedMovie);
                    posterRepo.save(posterEmbeddings);

                    //Process Plot Embeddings
                    PlotEmbeddings plotEmbeddings = new PlotEmbeddings();

                    float[] plotEmbeddingArray = new float[512];
                    for (int i = 0; i < plotEmbeddingArray.length; i++) {
                        plotEmbeddingArray[i] = Float.parseFloat(json.get("plot_embedding").get(i).asText());
                    }
                    plotEmbeddings.setEmbedding(plotEmbeddingArray);
                    plotEmbeddings.setMovie(savedMovie);
                    plotRepo.save(plotEmbeddings);




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
