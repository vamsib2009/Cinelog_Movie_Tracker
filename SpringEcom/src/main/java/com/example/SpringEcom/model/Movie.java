package com.example.SpringEcom.model;


import ch.qos.logback.classic.Logger;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Array;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
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

    private List<String> language = new ArrayList<>();
    private List<String> country = new ArrayList<>();

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


    //Column to store the embeddings
    @Setter
    @Column(name="plot_embedding")
    @JdbcTypeCode(SqlTypes.VECTOR)
    @Array(length=512)
    public float[] plotEmbedding;

    @Setter
    @Column(name="poster_embedding")
    @JdbcTypeCode(SqlTypes.VECTOR)
    @Array(length=512)
    public float[] posterEmbedding;

    @Setter
    @Column(name="rag_embedding")
    @JdbcTypeCode(SqlTypes.VECTOR)
    @Array(length=1536)
    public float[] ragEmbedding;




}
