# Liftly API Testing Guide

## Backend Status
✅ Spring Boot 3.3.0 running on `http://localhost:8080/api`  
✅ PostgreSQL database connected and persisting data  
✅ Authentication endpoints fully functional  
✅ Security configuration allows public register/login

## API Endpoints

### 1. Register User
**Endpoint:** `POST /api/auth/register`  
**Status Code:** 201 Created

**Request:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

**Response (201 Created):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "token": "75bca6c5-da26-44f8-bdc9-f4a88d1857cc",
  "message": "Registration successful"
}
```

**Validation Rules:**
- Email: Required, must be unique, valid email format
- Password: Required, minimum 6 characters
- firstName: Required
- lastName: Required

---

### 2. Login User
**Endpoint:** `POST /api/auth/login`  
**Status Code:** 200 OK

**Request:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Response (200 OK):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "token": "166b83c8-151b-4519-b28e-e1dc20ee7af5",
  "message": "Login successful"
}
```

**Error Cases:**
- Wrong password → 401 Unauthorized
- User not found → 401 Unauthorized
- User inactive → 401 Unauthorized

---

### 3. Logout User
**Endpoint:** `POST /api/auth/logout`  
**Status Code:** 200 OK  
**Authentication:** Required (Bearer token)

**Request:**
```bash
curl -X POST "http://localhost:8080/api/auth/logout?userId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response (200 OK):**
```
Logout successful
```

---

## Database Verification

### View All Users
```bash
docker exec liftly-postgres psql -U postgres -d liftly -c "SELECT * FROM users;"
```

### PostgreSQL Connection Details
- **Host:** localhost
- **Port:** 5432
- **Database:** liftly
- **Username:** postgres
- **Password:** postgres

---

## Testing with Postman

### Import Collection
Create a new collection with these requests:

**1. Register**
- Method: POST
- URL: `http://localhost:8080/api/auth/register`
- Body (raw JSON):
```json
{
  "email": "testuser@liftly.io",
  "password": "TestPass123",
  "firstName": "Test",
  "lastName": "User"
}
```

**2. Login**
- Method: POST
- URL: `http://localhost:8080/api/auth/login`
- Body (raw JSON):
```json
{
  "email": "testuser@liftly.io",
  "password": "TestPass123"
}
```
- Extract token from response and save to collection variable: `{{auth_token}}`

**3. Logout**
- Method: POST
- URL: `http://localhost:8080/api/auth/logout?userId={{user_id}}`
- Headers: `Authorization: Bearer {{auth_token}}`

---

## Startup Commands

### Start Backend (with hot reload)
```bash
cd /Users/hafidz/Documents/Projects/liftly/backend
mvn spring-boot:run
```

### Start PostgreSQL
```bash
cd /Users/hafidz/Documents/Projects/liftly
docker-compose up -d
```

### Verify Services Running
```bash
# Check backend
curl http://localhost:8080/api/auth/login -X POST -H "Content-Type: application/json" -d '{}'

# Check database
docker exec liftly-postgres pg_isready -U postgres
```

---

## Known Issues & Solutions

### 401 Unauthorized on Register
**Solution:** Spring Security is configured to allow register/login without authentication. If receiving 401:
1. Ensure `SecurityConfig.java` has `@EnableWebSecurity` annotation
2. Verify `requestMatchers("/api/auth/register", "/api/auth/login").permitAll()`
3. Restart backend: `mvn spring-boot:run`

### Database Connection Failed
**Solution:**
```bash
# Check if PostgreSQL container is running
docker ps | grep liftly-postgres

# Restart if needed
docker-compose down
docker-compose up -d

# Verify connection
docker exec liftly-postgres psql -U postgres -d liftly -c "SELECT 1;"
```

### Port 8080 Already in Use
**Solution:**
```bash
# Kill process using port 8080
lsof -i :8080 | grep -v COMMAND | awk '{print $2}' | xargs kill -9

# Restart backend
mvn spring-boot:run
```

---

## Next Steps

1. **JWT Implementation:** Replace UUID tokens with proper JWT implementation
2. **Frontend Integration:** Connect Flutter frontend to these endpoints
3. **Token Refresh:** Add refresh token mechanism
4. **Email Verification:** Add email confirmation for registration
5. **Password Reset:** Implement password recovery flow
6. **API Documentation:** Generate Swagger/OpenAPI docs
7. **Rate Limiting:** Add request throttling for security
8. **Logging:** Enhanced audit trail for authentication events

---

**Last Updated:** 2025-12-21  
**Backend Version:** Spring Boot 3.3.0  
**Database:** PostgreSQL 16 Alpine
