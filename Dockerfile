# Using OpenJDK 17 base image
FROM eclipse-temurin:17 AS builder

#Set the working dir
WORKDIR /app

# Copy apps code
COPY . .

# Runs the Maven wrapper to package app into .jar file.
RUN ./mvnw package -DskipTests

# Using Temurin JDK 17 image
FROM eclipse-temurin:17-jdk-jammy

# Set working dir
WORKDIR /app

# Copy jar file from build stage
COPY --from=builder /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run 
ENTRYPOINT ["java", "-jar", "app.jar"]
