package com.example.SpringEcom.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class MovieInitializerController {
    @Autowired
    private MovieInitializer movieInitializer;

    @GetMapping("/init")
    public String init(){
        movieInitializer.loadMoviesFromJSONL();
        return "next step after service is called";
    }

}
