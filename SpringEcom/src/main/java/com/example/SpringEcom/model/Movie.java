package com.example.SpringEcom.model;


import ch.qos.logback.classic.Logger;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.slf4j.LoggerFactory;

import java.util.*;


@Entity //Make a Java class as a Java Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Movie {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) //Auto increment primary key
    private int id;

    private String name;
    private String description;
    private String directorName;

    @Enumerated(EnumType.STRING) //Store the category as a string instead of an Ordinal/Numerical for easier querying
    private Category category;

    private float imdbrating;
    private Date releaseDate;

//    @Column(nullable = true)
//    private Float userRating;
//    @Column(nullable = true)
//    private String userReview;
//
//    @Column(nullable = true, columnDefinition = "BOOLEAN DEFAULT FALSE")
//    private boolean Watched;

    private String language;
    private String country;

    //For Lazy Fetching, the session will close
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
            name = "movie_actors",
            joinColumns = @JoinColumn(name = "movie_id")
    )
    @Column(name = "actor_name")
    private List<String> actorNames = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
            name = "movie_tags",
            joinColumns = @JoinColumn(name = "movie_id")
    )
    @Column(name = "tag")
    private List<String> tags = new ArrayList<>();

}
