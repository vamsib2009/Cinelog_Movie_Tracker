//package com.example.SpringEcom.config;
//
//import jakarta.annotation.PostConstruct;
//import lombok.RequiredArgsConstructor;
//import org.springframework.ai.document.Document;
//import org.springframework.ai.embedding.EmbeddingModel;
//import org.springframework.ai.embedding.EmbeddingRequest;
//import org.springframework.ai.embedding.EmbeddingResponse;
//import org.springframework.ai.vectorstore.VectorStore;
//import org.springframework.ai.vectorstore.redis.RedisVectorStore;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.jdbc.core.JdbcTemplate;
//import redis.clients.jedis.DefaultJedisClientConfig;
//import redis.clients.jedis.HostAndPort;
//import redis.clients.jedis.JedisPooled;
//
//import java.util.Collections;
//import java.util.List;
//
//@Configuration
//public class AIConfig {
//
//    @Autowired
//    private JedisPooled jedisPooled;
//
//    @Bean
//    public EmbeddingModel dummyEmbeddingModel() {
//        return new EmbeddingModel() {
//            public List<List<Float>> embedAll(List<String> texts) {
//                return texts.stream()
//                        .map(t -> Collections.nCopies(512, 0.0f))
//                        .toList();
//            }
//
//            @Override
//            public EmbeddingResponse call(EmbeddingRequest request) {
//                return new EmbeddingResponse(List.of());
//            }
//
//            @Override
//            public float[] embed(String text) {
//                return new float[512];
//            }
//
//            @Override
//            public float[] embed(Document document) {
//                return new float[512];
//            }
//        };
//    }
//
//    @Bean
//    public VectorStore vectorStore(JedisPooled jedisPooled, EmbeddingModel embeddingModel) {
//        return RedisVectorStore.builder(jedisPooled, embeddingModel)
//                .indexName("plot-embedding-index")
//                .prefix("plot-embedding")
////                .metadataFields(
////                        RedisVectorStore.MetadataField.numeric("movieid")
////                )
//                .initializeSchema(true)
//                .build();
//    }
//
//    @PostConstruct
//    public void logInit() {
//        System.out.println("✅ Dummy vector store initialized for 'poster_embeddings'");
//    }
//}
