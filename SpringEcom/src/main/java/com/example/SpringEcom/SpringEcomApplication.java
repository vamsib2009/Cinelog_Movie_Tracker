package com.example.SpringEcom;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.util.*;
import java.sql.*;
import java.util.Date;
import java.time.*;

@SpringBootApplication
public class SpringEcomApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringEcomApplication.class, args);
		Date currentDate = new Date();
		System.out.println("Current Date & Time: " + currentDate);
		Timestamp timestamp = new Timestamp(System.currentTimeMillis());
		System.out.println(timestamp);

		LocalDateTime now = LocalDateTime.now();


		System.out.println("Formatted Date-Time: " + now);

	}

}
