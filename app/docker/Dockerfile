# Use an official OpenJDK 17 runtime as base image
FROM openjdk:17-jdk-slim

# Set a working directory inside container
WORKDIR /app

# Copy the Spring Boot JAR file from target/ into container
COPY target/java-cicd-app-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 for the app
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
