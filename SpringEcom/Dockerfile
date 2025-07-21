FROM openjdk:21-jdk
ADD target/cinelog-movie-app.jar cinelog-movie-app.jar
ENTRYPOINT ["java", "-jar", "/cinelog-movie-app.jar"]
COPY src/main/resources/ /app/resources/
