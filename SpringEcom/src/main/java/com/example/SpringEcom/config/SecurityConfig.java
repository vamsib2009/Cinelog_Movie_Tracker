//package com.example.SpringEcom.config;
//
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.security.config.Customizer;
//import org.springframework.security.config.annotation.web.builders.HttpSecurity;
//import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
//import org.springframework.security.config.http.SessionCreationPolicy;
//import org.springframework.security.core.userdetails.User;
//import org.springframework.security.core.userdetails.UserDetails;
//import org.springframework.security.core.userdetails.UserDetailsService;
//import org.springframework.security.provisioning.InMemoryUserDetailsManager;
//import org.springframework.security.web.SecurityFilterChain;
//
//@Configuration
//@EnableWebSecurity //This is disable the default Spring Security
//public class SecurityConfig {
//
//    @Bean
//    //SecurityFilterChain is the servlet that controls the entry point to the application
//    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception{
//        //Disable CSRF token
//        http.csrf(customizer -> customizer.disable())
//                //No one should be able to access without Authentication
//                . authorizeHttpRequests(request -> request.anyRequest().authenticated())
//                //Enable basic form login
////                .http.formLogin(Customer.withDefualts())
//                .httpBasic(Customizer.withDefaults())
//                //Ways of handling CSRD ->  Make it Stateless, No need to worry about session ID. Give new Session ID everytime make request
//                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
//
//        return http.build();
//
//    }
//
//
//    //Something to verify the Username Password
//    //UserDetailsService is an interface, later we have to build class to implement (UserDetialsManager implements it)
//    @Bean
//    public UserDetailsService userDetailsService() {
//        //User implements UserDetails
//        UserDetails user= User.withDefaultPasswordEncoder()
//                .username("navin")
//                .password("n@123")
//                .roles("USER")
//                .build();
//
//        UserDetails admin= User.withDefaultPasswordEncoder()
//                .username("admin")
//                .password("v@1234")
//                .roles("ADMIN")
//                .build();
//
//        return new InMemoryUserDetailsManager(user,admin);
//    }
//}
