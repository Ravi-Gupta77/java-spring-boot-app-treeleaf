# Use a multi-stage build to keep the image small
FROM eclipse-temurin:17 AS builder
WORKDIR /app

# Copy and build the app
COPY . .
RUN ./mvnw package -DskipTests

# Second stage: run the app
FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
