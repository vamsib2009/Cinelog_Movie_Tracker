package com.example.SpringEcom.model;


import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Data
@Table(name = "users")
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) //Auto increment primary key
    private Integer id;

    private String username;
    private String password;

    @Enumerated(EnumType.STRING)
    private Role role;

    public String getRole() {
        return role.name();  // Convert Enum to String
    }
}
