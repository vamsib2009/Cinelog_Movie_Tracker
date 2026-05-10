# Build stage: compile the jar with Maven
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

# Runtime stage: slim JRE only, smaller image
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/cinelog-movie-app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Xmx384m", "-jar", "/app/app.jar"]
