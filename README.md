# java-spring-boot-app-treeleaf

This is the somple java springboot app which is dockerized & deployed into EKS cluster using helm

The docker image optimized for multi-stage build & was tested locally
### Build image
  ```hcl
  docker build -t java-springboot-app:latest .
  ```
### Deploy container
  ```hcl
  docker run -d --name -java-springboot-app -p 8090:8080 java-springboot-app
  ```
<p align="center">
  <img src="./deploy.png" alt="deploy localhost" width="80%">
</p>

<p align="center">
  <img src="./diagram.png" alt="Architecture Design" width="80%">
</p>