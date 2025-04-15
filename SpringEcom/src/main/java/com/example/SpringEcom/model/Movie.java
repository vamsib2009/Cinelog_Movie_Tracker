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

    @Enumerated(EnumType.STRING) //Store the category as a string instead of an Ordinal/Numerical for easier querying
    private Category category;

    private float imdbrating;
    private Date releaseDate;
    private boolean OttAvailable;

    @Column(nullable = true)
    private Float userRating;
    @Column(nullable = true)
    private String userReview;

    @Column(nullable = false, columnDefinition = "BOOLEAN DEFAULT FALSE")
    private boolean Watched;


}
