package com.example.SpringEcom.model;


import jakarta.persistence.*;
import lombok.Data;
import lombok.Generated;

import java.time.LocalDateTime;

@Entity
@Data
@Table(name = "logging")
public class Logging {

    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne
    @JoinColumn(name = "movie_id")
    private Movie movie;

    @Column(updatable = false, nullable = false)
    private LocalDateTime loggeddate;

    @PrePersist //Tells the hibernate to add this method before commitiing to the database
    protected void onCreate()
    {
        loggeddate = LocalDateTime.now();
    }

}
