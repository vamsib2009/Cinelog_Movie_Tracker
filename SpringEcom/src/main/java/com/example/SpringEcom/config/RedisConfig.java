package com.example.SpringEcom.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import redis.clients.jedis.JedisPooled;

@Configuration
public class RedisConfig {

    // Injects 'spring.data.redis.host' from your properties file
    @Value("${spring.data.redis.host}")
    private String redisHost;

    // Injects 'spring.data.redis.port' from your properties file
    @Value("${spring.data.redis.port}")
    private int redisPort;

    @Bean
    public JedisPooled jedisPooled() {
        // Use the injected values to create the connection
        return new JedisPooled(redisHost, redisPort);
    }
}