package com.example.SpringEcom.model;

// Example PlotEmbeddings.java Entity
import com.pgvector.PGvector;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Array;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.Type;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "plot_embeddings")
@NoArgsConstructor
@AllArgsConstructor
public class PlotEmbeddings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Setter
    @ManyToOne
    @JoinColumn(name = "movie_id", nullable = false)
    private Movie movie;

    @Setter
    @Column(name="the_vector")
    @JdbcTypeCode(SqlTypes.VECTOR)
    @Array(length=512)
    public float[] embedding;

    // Getters and setters...
}