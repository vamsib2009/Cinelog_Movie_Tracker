package com.example.SpringEcom.service;

import com.example.SpringEcom.model.Movie;
import com.example.SpringEcom.repo.MovieRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;


@Service
public class MovieService {

    @Autowired
    private MovieRepo movieRepo;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public List<Movie> getAllMovies()
    {
        return movieRepo.findAll(); //I think find all is a given function
    }

    public Movie getMovieById(int id) {

        return movieRepo.findById(id).orElse(null);
    }

//    public Movie updateMovie(Movie movie, MultipartFile imageFile) throws IOException {
//        movie.setImageName(imageFile.getOriginalFilename());
//        movie.setImageType(imageFile.getContentType());
//        movie.setImageData(imageFile.getBytes());
//
//        return movieRepo.save(movie);
//    }

    public List<Movie> searchMovies(String keyword) {
        return movieRepo.searchMovies(keyword);
    }

    public void addOrUpdateRating (int id, Float userRating, String userReview) throws IOException{
        Movie up_movie = movieRepo.findById(id).orElse(null);


        up_movie.setUserRating(userRating);  //I think the DB allows not null, so it should be fine
        up_movie.setUserReview(userReview);
        movieRepo.save(up_movie);
        System.out.println(up_movie.toString()); //This is successful in the first testing

    }

    public void addMovie(Movie movie)
    {
        movieRepo.save(movie);
    }
}
