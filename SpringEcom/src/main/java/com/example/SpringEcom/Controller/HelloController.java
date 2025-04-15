package com.example.SpringEcom.Controller;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {


    @GetMapping("/hello")
    public String greet(){
        return "Welcome to Vamsi's Backend logic for Movie App";
    }

    @GetMapping("/about")
    public String about(){
        return "Application created by Vamsi B";
    }
}