# Liftly API - Backend Setup

## Prerequisites
- Docker & Docker Compose installed
- Java 17+
- Maven 3.6+

## Quick Start

### 1. Start PostgreSQL Database

```bash
docker-compose up -d
```

This will:
- Create PostgreSQL container
- Create `liftly` database
- Create `users` table with indexes and triggers
- Run on `localhost:5432`

**Database Credentials:**
- User: `postgres`
- Password: `postgres`
- Database: `liftly`

### 2. Verify Database Connection

```bash
# Check if container is running
docker-compose ps

# View logs
docker-compose logs postgres
```

### 3. Run Spring Boot Application

```bash
./mvnw spring-boot:run
```

Server starts at: `http://localhost:8080/api`

### 4. Test API with Postman

**Register:**
```
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
```
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Logout:**
```
POST http://localhost:8080/api/auth/logout?userId=1
```

## Useful Commands

```bash
# Stop database
docker-compose down

# Stop and remove all data
docker-compose down -v

# View database logs
docker-compose logs -f postgres

# Access PostgreSQL CLI
docker-compose exec postgres psql -U postgres -d liftly

# View tables
docker-compose exec postgres psql -U postgres -d liftly -c "\dt"

# View users
docker-compose exec postgres psql -U postgres -d liftly -c "SELECT * FROM users;"
```

## Development

### Auto-reload on code changes
```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"
```

### Build only (no run)
```bash
./mvnw clean install -DskipTests
```

### Run tests
```bash
./mvnw test
```

## Troubleshooting

**Port 5432 already in use:**
```bash
# Kill existing process on port 5432
lsof -ti:5432 | xargs kill -9

# Or change port in docker-compose.yml
```

**Connection refused:**
- Ensure PostgreSQL container is running: `docker-compose ps`
- Check logs: `docker-compose logs postgres`
- Verify credentials in `application.yml`

**Table doesn't exist:**
- Restart container: `docker-compose restart postgres`
- Check init.sql was executed: `docker-compose logs postgres | grep init.sql`
