package com.example.SpringEcom.service;


import com.example.SpringEcom.model.User;
import com.example.SpringEcom.repo.UserRepo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Objects;
import java.util.Optional;

@Service
public class UserService {

    //Constructor injection
    UserRepo userRepo;
    public UserService(UserRepo userRepo)
    {
        this.userRepo = userRepo;
    }

    public Optional<User> loginUser(String username, String password)
    {
        Optional<User> user = userRepo.findByusername(username);
        if(user.isPresent() && (Objects.equals(password, user.get().getPassword())))
        {
            return user;
        }
        else{
            return Optional.empty();
        }
    }
}
