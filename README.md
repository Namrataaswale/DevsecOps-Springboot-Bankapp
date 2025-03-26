# DevsecOps-Springboot-Bankapp
End-to-End Banking Application A full-stack banking application built with Spring Boot and deployed using DevOps best practices. It features secure authentication, account management, and transactions. The deployment follows a CI/CD pipeline, utilizing Docker, Kubernetes, Jenkins, and AWS for scalability and automation.

# DevSecOps-Springboot-Bankapp

![Bank App Logo](images/bank-app-logo.png)

A secure banking application built with Spring Boot with integrated DevSecOps practices.

## Features
- Account management (create, view, update)
- Transaction processing (deposit, withdraw, transfer)
- JWT authentication & role-based authorization
- DevSecOps pipeline with SAST/DAST scanning

## Technologies
- **Backend**: Spring Boot 3, Spring Security
- **Database**: PostgreSQL
- **Security**: SonarQube, Trivy, OWASP ZAP

## Quick Start
```bash
git clone https://github.com/Namrataaswale/DevSecOps-Springboot-Bankapp.git
cd DevSecOps-Springboot-Bankapp
docker-compose -f docker-compose.db.yml up -d
mvn clean install
java -jar target/bankapp-0.0.1-SNAPSHOT.jar
