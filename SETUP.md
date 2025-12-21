# Liftly - Setup Guide

## Prerequisites
- Docker & Docker Compose
- Java 17+
- Maven 3.8+
- Node.js 18+

## Quick Start

### 1. Start PostgreSQL Database

```bash
docker-compose up -d
```

Verify database is running:
```bash
docker-compose logs postgres
```

Database credentials:
- **Host:** localhost
- **Port:** 5432
- **Database:** liftly
- **Username:** postgres
- **Password:** postgres

### 2. Run Backend

```bash
cd backend
./mvnw spring-boot:run
```

Backend akan start di `http://localhost:8080/api`

### 3. Run Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## API Endpoints

### Authentication

**Register:**
```bash
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Login:**
```bash
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Logout:**
```bash
POST http://localhost:8080/api/auth/logout?userId=1
```

## Docker Commands

**Start database:**
```bash
docker-compose up -d
```

**Stop database:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f postgres
```

**Reset database:**
```bash
docker-compose down -v
docker-compose up -d
```

## Testing with Postman

1. Import the collection from `postman_collection.json`
2. Set environment variables:
   - `base_url`: http://localhost:8080/api
   - `token`: (will be set automatically from login response)

## Troubleshooting

**Database connection refused:**
- Ensure Docker is running: `docker ps`
- Check PostgreSQL logs: `docker-compose logs postgres`
- Restart: `docker-compose restart postgres`

**Port already in use:**
- Change port in `docker-compose.yml` or `application.yml`
- Or kill existing process: `lsof -i :5432`

**Build failures:**
```bash
mvn clean install
```
