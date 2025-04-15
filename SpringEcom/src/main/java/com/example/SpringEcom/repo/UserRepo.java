package com.example.SpringEcom.repo;

import com.example.SpringEcom.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

public interface UserRepo extends JpaRepository <User, Integer> {
    Optional<User> findByusername(String username);

}
