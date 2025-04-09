# Use a multi-stage build to keep the image small

#
FROM eclipse-temurin:17 AS builder

#Set the working dir
WORKDIR /app

# Copy and build the app
COPY . .


RUN ./mvnw package -DskipTests

# Second stage: run the app
FROM eclipse-temurin:17-jdk-jammy

# Set working dir
WORKDIR /app


COPY --from=builder /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run 
ENTRYPOINT ["java", "-jar", "app.jar"]
