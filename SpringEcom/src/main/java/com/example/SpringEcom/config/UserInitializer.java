//package com.example.SpringEcom.config;
//
//import com.example.SpringEcom.model.Role;
//import com.example.SpringEcom.model.User;
//import com.example.SpringEcom.repo.UserRepo;
//import jakarta.annotation.PostConstruct;
//import jakarta.annotation.PreDestroy;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.core.io.Resource;
//import org.springframework.stereotype.Component;
//
//import java.io.BufferedReader;
//import java.io.InputStreamReader;
//import java.util.*;
//
//@Component
//public class UserInitializer {
//
//    private final UserRepo userRepo;
//    private final List<Integer> insertedIds = new ArrayList<>();
//
//    @Value("classpath:users.csv")
//    private Resource csvResource;
//
//    public UserInitializer(UserRepo userRepo) {
//        this.userRepo = userRepo;
//    }
//
//    @PostConstruct
//    public void loadUsersFromCSV() {
//        try (BufferedReader reader = new BufferedReader(new InputStreamReader(csvResource.getInputStream()))) {
//            String line = reader.readLine(); // Skip header
//            int lineNum = 1;
//
//            while ((line = reader.readLine()) != null) {
//                lineNum++;
//                String[] parts = line.split(",", -1);
//
//                if (parts.length < 3) {
//                    System.err.println("❌ Invalid line at " + lineNum + ": " + line);
//                    continue;
//                }
//
//                try {
//                    User user = new User();
//                    user.setUsername(parts[0].trim());
//                    user.setPassword(parts[1].trim());
//                    user.setRole(Role.valueOf(parts[2].trim().toUpperCase()));
//
//                    User saved = userRepo.save(user);
//                    insertedIds.add(saved.getId());
//                } catch (Exception e) {
//                    System.err.println("⚠️ Error parsing line " + lineNum + ": " + e.getMessage());
//                }
//            }
//
//            System.out.println("✅ Users loaded from CSV.");
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//    }
//
//    @PreDestroy
//    public void deleteCSVLoadedUsers() {
//        try {
//            userRepo.deleteAllById(insertedIds);
//            System.out.println("🧹 Deleted CSV-loaded users.");
//        } catch (Exception e) {
//            System.err.println("❌ Failed to delete users: " + e.getMessage());
//        }
//    }
//}
