Module 1 – Project Structure & Java App
1. Repo Structure (Initial Stage)
end-to-end-java-cicd-pipeline/
│
├── app/                           # Java Spring Boot application
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/demo/
│   │   │   │   ├── DemoApplication.java
│   │   │   │   └── controller/
│   │   │   │       └── HelloController.java
│   │   │   └── resources/
│   │   │       ├── application.properties
│   │   │       └── static/
│   │   │           └── index.html
│   │   └── test/java/com/example/demo/
│   │       └── DemoApplicationTests.java
│   └── pom.xml
│
└── README.md   # will be filled at the end

2. Code for Each File
app/src/main/java/com/example/demo/DemoApplication.java

package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}


app/src/main/java/com/example/demo/controller/HelloController.java

package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Hello from the End-to-End CI/CD Pipeline Java Application!";
    }
}


app/src/main/resources/application.properties

server.port=8080
spring.application.name=java-cicd-demo

app/src/main/resources/static/index.html

<!DOCTYPE html>
<html>
<head>
    <title>Java CI/CD Demo</title>
</head>
<body>
    <h1>Welcome to the End-to-End CI/CD Pipeline Demo!</h1>
    <p>This page is served from the Spring Boot application.</p>
</body>
</html>

app/src/test/java/com/example/demo/DemoApplicationTests.java

package com.example.demo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class DemoApplicationTests {

    @Test
    void contextLoads() {
    }
}


app/pom.xml

<project xmlns="http://maven.apache.org/POM/4.0.0" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
    https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>java-cicd-demo</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>java-cicd-demo</name>
    <description>Java CI/CD Demo Application</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.4</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <!-- Spring Boot Starter Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Spring Boot Starter Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

3. Commands to Build & Run Locally

# Navigate to app folder
cd app

# Build the Spring Boot app
mvn clean package

# Run the app
java -jar target/java-cicd-demo-1.0.0.jar

# Test in browser
# Visit http://localhost:8080

Module 2 – Dockerization of the App

docker/
 └── Dockerfile
Final Multi-Stage Dockerfile

# Stage 1: Build
FROM maven:3.9.8-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

Build & Run

docker build -t venkatesh384/java-cicd-app:latest -f docker/Dockerfile .
docker run -p 8080:8080 venkatesh384/java-cicd-app:latest

3. Push the image

docker push venkatesh384/java-cicd-app:latest

Module 3 – Jenkins Declarative Pipeline

Jenkinsfile

pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // Jenkins credential ID
        DOCKER_IMAGE = "your-dockerhub-username/java-cicd-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your-username/java-cicd-app.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('MySonarQubeServer') {
                    sh 'mvn sonar:sonar -Dsonar.projectKey=java-cicd-app'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} -f docker/Dockerfile .
                    docker tag $DOCKER_IMAGE:${BUILD_NUMBER} $DOCKER_IMAGE:latest
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    sh """
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push $DOCKER_IMAGE:${BUILD_NUMBER}
                    docker push $DOCKER_IMAGE:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}


Required Tools & Plugins in Jenkins

1.Pipeline

2.Docker Pipeline

3.SonarQube Scanner for Jenkins (Module 4 setup)

4.Git plugin

Implementation Steps
Install with Docker group access

docker run -d \
  --name jenkins \
  -u root \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

Here:

-u root lets Jenkins run as root

/var/run/docker.sock allows Jenkins to control Docker on the host

Inside Jenkins, you’d then install Docker CLI in the container.

2. Access the container shell

docker exec -it jenkins bash
cat /var/jenkins_home/secrets/initialAdminPassword

Install Docker on Jenkins server:

sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
newgrp docker


Create Jenkins credentials for DockerHub:

ID: dockerhub-creds

Username & password from DockerHub account

Create Jenkins credentials for GitHub if repo is private.

Configure SonarQube server in Jenkins → Manage Jenkins → Configure System.


Commands for Local Testing (Before Jenkins)

# Build jar
mvn clean package -DskipTests

# Build docker image
docker build -t your-dockerhub-username/java-cicd-app:latest -f docker/Dockerfile .

# Run docker image
docker run -p 8080:8080 your-dockerhub-username/java-cicd-app:latest


dockerhub-credentials → Create in Jenkins under Manage Jenkins → Credentials:

Kind: Username & Password

ID: dockerhub-creds

Username: venkatesh384

Password: DockerHub password or token

Module 4 – SonarQube Integration

Purpose

Run static code analysis on our Java application.

Detect code smells, bugs, and security vulnerabilities before deployment.

Push results to SonarQube dashboard for tracking.

Part 1 – Local / Docker SonarQube Setup

docker run -d   --name sonarqube   -p 9000:9000   -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true   sonarqube:latest
                    (or)
docker run -d --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts-community

SonarQube UI → http://<server-ip>:9000

Default credentials: admin / admin (you’ll be prompted to change the password)

Part 2 – Jenkins SonarQube Configuration

Install Plugin

Go to Manage Jenkins → Plugins

Install SonarQube Scanner for Jenkins

Configure SonarQube Server

Go to Manage Jenkins → Configure System

Find SonarQube servers → Add:

Name: MySonarQubeServer
Server URL: http://<sonarqube-ip>:9000
Authentication Token: <generated in SonarQube UI>

Add SonarQube Scanner Tool

Go to Manage Jenkins → Global Tool Configuration

Add SonarQube Scanner with name SonarScanner.

Part 3 – Project Configuration in SonarQube

Open SonarQube UI → Projects → Manually Create Project

Set:

Project Key → java-cicd-app

Name → Java CICD App

Generate a Token and copy it (use in Jenkins configuration above).

Part 4 – Jenkinsfile Update
Update SonarQube stage in Jenkinsfile:
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('MySonarQubeServer') {
            sh 'mvn sonar:sonar -Dsonar.projectKey=java-cicd-app -Dsonar.host.url=http://<sonarqube-ip>:9000 -Dsonar.login=<token>'
        }
    }
}
(Replace <sonarqube-ip> and <token> with actual values)


Part 5 – Local Test (without Jenkins)

# Install sonar scanner locally
brew install sonar-scanner  # Mac
sudo apt install sonar-scanner-cli -y  # Ubuntu

# Run analysis locally
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=java-cicd-app \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<token>
