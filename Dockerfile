# Stage 1: Build
FROM maven:3.9.1-eclipse-temurin-17 as builder
WORKDIR /app
COPY ./spring-boot .
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
