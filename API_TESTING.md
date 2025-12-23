# Liftly API Testing Guide

## Base URL
```
http://192.168.1.4:8080/api
```

> **Note**: Change IP `192.168.1.4` to your backend server's IP address

---

## Authentication Endpoints

### 1. Register
**Endpoint**: `POST /auth/register`

**Request**:
```bash
curl -X POST http://192.168.1.4:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

**Response** (Status: 201):
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "message": "Registration successful"
}
```

---

### 2. Login
**Endpoint**: `POST /auth/login`

**Request**:
```bash
curl -X POST http://192.168.1.4:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Response** (Status: 200):
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "message": "Login successful"
}
```

---

### 3. Logout
**Endpoint**: `POST /auth/logout`

**Request**:
```bash
curl -X POST http://192.168.1.4:8080/api/auth/logout?userId=1 \
  -H "Content-Type: application/json"
```

**Response** (Status: 200):
```json
"Logout successful"
```

---

## Plans Endpoints

### 1. Create Plan
**Endpoint**: `POST /plans`

**Request**:
```bash
curl -X POST http://192.168.1.4:8080/api/plans?userId=1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Push/Pull/Legs",
    "description": "3-day strength program",
    "exercises": ["Bench Press", "Incline Dumbbell", "Cable Flyes", "Barbell Row", "Lat Pulldown"]
  }'
```

**Parameters**:
- `userId` (required): The ID of the user creating the plan

**Request Body**:
- `name` (required): Name of the plan
- `description` (optional): Description of the plan
- `exercises` (required): Array of exercise names

**Response** (Status: 201):
```json
{
  "id": 1,
  "userId": 1,
  "name": "Push/Pull/Legs",
  "description": "3-day strength program",
  "exercises": [
    {
      "id": 1,
      "name": "Bench Press",
      "order": 0
    },
    {
      "id": 2,
      "name": "Incline Dumbbell",
      "order": 1
    },
    {
      "id": 3,
      "name": "Cable Flyes",
      "order": 2
    },
    {
      "id": 4,
      "name": "Barbell Row",
      "order": 3
    },
    {
      "id": 5,
      "name": "Lat Pulldown",
      "order": 4
    }
  ],
  "createdAt": "2025-12-23T10:30:45",
  "updatedAt": "2025-12-23T10:30:45"
}
```

---

### 2. Get List Plans
**Endpoint**: `GET /plans`

**Request**:
```bash
curl -X GET http://192.168.1.4:8080/api/plans?userId=1 \
  -H "Content-Type: application/json"
```

**Parameters**:
- `userId` (required): The ID of the user

**Response** (Status: 200):
```json
[
  {
    "id": 1,
    "userId": 1,
    "name": "Push/Pull/Legs",
    "description": "3-day strength program",
    "exercises": [
      {
        "id": 1,
        "name": "Bench Press",
        "order": 0
      },
      {
        "id": 2,
        "name": "Incline Dumbbell",
        "order": 1
      },
      {
        "id": 3,
        "name": "Cable Flyes",
        "order": 2
      },
      {
        "id": 4,
        "name": "Barbell Row",
        "order": 3
      },
      {
        "id": 5,
        "name": "Lat Pulldown",
        "order": 4
      }
    ],
    "createdAt": "2025-12-23T10:30:45",
    "updatedAt": "2025-12-23T10:30:45"
  },
  {
    "id": 2,
    "userId": 1,
    "name": "Upper/Lower",
    "description": "4-day split",
    "exercises": [
      {
        "id": 6,
        "name": "Squat",
        "order": 0
      },
      {
        "id": 7,
        "name": "Deadlift",
        "order": 1
      }
    ],
    "createdAt": "2025-12-23T11:00:00",
    "updatedAt": "2025-12-23T11:00:00"
  }
]
```

---

### 3. Get Plan by ID
**Endpoint**: `GET /plans/{planId}`

**Request**:
```bash
curl -X GET http://192.168.1.4:8080/api/plans/1?userId=1 \
  -H "Content-Type: application/json"
```

**Parameters**:
- `planId` (required): The ID of the plan
- `userId` (required): The ID of the user

**Response** (Status: 200):
```json
{
  "id": 1,
  "userId": 1,
  "name": "Push/Pull/Legs",
  "description": "3-day strength program",
  "exercises": [
    {
      "id": 1,
      "name": "Bench Press",
      "order": 0
    },
    {
      "id": 2,
      "name": "Incline Dumbbell",
      "order": 1
    }
  ],
  "createdAt": "2025-12-23T10:30:45",
  "updatedAt": "2025-12-23T10:30:45"
}
```

---

### 4. Update Plan
**Endpoint**: `PUT /plans/{planId}`

**Request**:
```bash
curl -X PUT http://192.168.1.4:8080/api/plans/1?userId=1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Push/Pull/Legs v2",
    "description": "3-day strength program - updated",
    "exercises": ["Bench Press", "Incline Press", "Dumbbell Flyes"]
  }'
```

**Parameters**:
- `planId` (required): The ID of the plan to update
- `userId` (required): The ID of the user

**Request Body**:
- `name` (required): Updated name
- `description` (optional): Updated description
- `exercises` (required): Updated exercise list

**Response** (Status: 200):
```json
{
  "id": 1,
  "userId": 1,
  "name": "Push/Pull/Legs v2",
  "description": "3-day strength program - updated",
  "exercises": [
    {
      "id": 1,
      "name": "Bench Press",
      "order": 0
    },
    {
      "id": 2,
      "name": "Incline Press",
      "order": 1
    },
    {
      "id": 3,
      "name": "Dumbbell Flyes",
      "order": 2
    }
  ],
  "createdAt": "2025-12-23T10:30:45",
  "updatedAt": "2025-12-23T12:15:30"
}
```

---

### 5. Delete Plan
**Endpoint**: `DELETE /plans/{planId}`

**Request**:
```bash
curl -X DELETE http://192.168.1.4:8080/api/plans/1?userId=1 \
  -H "Content-Type: application/json"
```

**Parameters**:
- `planId` (required): The ID of the plan to delete
- `userId` (required): The ID of the user

**Response** (Status: 200):
```json
"Plan deleted successfully"
```

---

## Testing Workflow Example

### Step 1: Register a new user
```bash
curl -X POST http://192.168.1.4:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "firstName": "Test",
    "lastName": "User"
  }'
# Save the returned user ID (e.g., 1)
```

### Step 2: Login
```bash
curl -X POST http://192.168.1.4:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }'
```

### Step 3: Create a plan
```bash
curl -X POST http://192.168.1.4:8080/api/plans?userId=1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My First Plan",
    "description": "Getting started with fitness",
    "exercises": ["Squats", "Bench Press", "Deadlifts"]
  }'
# Save the returned plan ID (e.g., 1)
```

### Step 4: Get all plans
```bash
curl -X GET http://192.168.1.4:8080/api/plans?userId=1 \
  -H "Content-Type: application/json"
```

### Step 5: Update the plan
```bash
curl -X PUT http://192.168.1.4:8080/api/plans/1?userId=1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Updated Plan",
    "description": "Updated plan description",
    "exercises": ["Squats", "Bench Press", "Deadlifts", "Pull-ups"]
  }'
```

### Step 6: Delete the plan
```bash
curl -X DELETE http://192.168.1.4:8080/api/plans/1?userId=1 \
  -H "Content-Type: application/json"
```

### Step 7: Logout
```bash
curl -X POST http://192.168.1.4:8080/api/auth/logout?userId=1 \
  -H "Content-Type: application/json"
```

---

## Error Responses

### 400 - Bad Request
```json
{
  "message": "Request tidak valid. Cek kembali data Anda."
}
```

### 401 - Unauthorized
```json
{
  "message": "Akses ditolak. Login kembali diperlukan."
}
```

### 404 - Not Found
```json
{
  "message": "Resource tidak ditemukan."
}
```

### 409 - Conflict
```json
{
  "message": "Data sudah ada atau terjadi konflik."
}
```

### 500 - Server Error
```json
{
  "message": "Server error. Coba lagi nanti."
}
```

---

## Tips for Testing

1. **Use a REST Client**: Tools like Postman, Insomnia, or VSCode REST Client extension make testing easier
2. **Save IDs**: After creating a user or plan, save the IDs for use in subsequent requests
3. **Check IP Address**: Make sure to use the correct IP address for your backend server
4. **Content-Type**: Always include `Content-Type: application/json` header
5. **Query Parameters**: User ID and Plan ID are required as query parameters in most endpoints

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
