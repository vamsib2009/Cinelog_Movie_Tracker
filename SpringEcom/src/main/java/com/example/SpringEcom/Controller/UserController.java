package com.example.SpringEcom.Controller;

import com.example.SpringEcom.model.User;
import com.example.SpringEcom.service.UserService;
import lombok.Data;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ResponseStatusException;


import javax.management.relation.Role;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/auth")
public class UserController {

    //Constructor injection
    UserService userService;
    public UserController(UserService userService)
    {
        this.userService = userService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDTO> login(@RequestParam String username, @RequestParam String password) {
        System.out.println("Here in login method");
        return userService.loginUser(username, password)
                .map(user -> ResponseEntity.ok(new LoginResponseDTO(user.getRole(), user.getId())))  //For the user, map it to a Login ResponseDTO with userId
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid username or password"));
    }


    //Let's create a login response DTO
    @Data
    public static class LoginResponseDTO{
        private int userId;
        private String role;

        public LoginResponseDTO(String role, int userId) {
            this.role = role;
            this.userId = userId;
        }

    }
}
