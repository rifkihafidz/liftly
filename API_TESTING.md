# Liftly API Testing Guide

## Base URL
```
http://192.168.1.5:8080/api
```

> **Note**: Change IP `192.168.1.5` to your backend server's IP address

---

## Response Format

All API responses follow a standardized format:

### Success Response
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Error message",
  "errors": {
    // Field validation errors (optional)
  }
}
```

---

## Authentication Endpoints

### 1. Register
**Endpoint**: `POST /auth/register`

**Request**:
```bash
curl -X POST http://192.168.1.5:8080/api/auth/register \
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
  "success": true,
  "statusCode": 201,
  "message": "Registration successful",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

---

### 2. Login
**Endpoint**: `POST /auth/login`

**Request**:
```bash
curl -X POST http://192.168.1.5:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Login successful",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

---

### 3. Logout
**Endpoint**: `POST /auth/logout`

**Request**:
```bash
curl -X POST "http://192.168.1.5:8080/api/auth/logout?userId=1" \
  -H "Content-Type: application/json"
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Logout successful"
}
```

---

## Plan Endpoints

### 1. Create Plan
**Endpoint**: `POST /plans?userId={userId}`

**Request**:
```bash
curl -X POST "http://192.168.1.5:8080/api/plans?userId=1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Push/Pull/Legs",
    "description": "3-day strength training program",
    "exercises": ["Bench Press", "Incline Dumbbell", "Cable Flyes"]
  }'
```

**Response** (Status: 201):
```json
{
  "success": true,
  "statusCode": 201,
  "message": "Plan created successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "name": "Push/Pull/Legs",
    "description": "3-day strength training program",
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
      }
    ],
    "createdAt": "2025-12-23T10:30:00.000000",
    "updatedAt": "2025-12-23T10:30:00.000000"
  }
}
```

---

### 2. Get All Plans
**Endpoint**: `GET /plans?userId={userId}`

**Request**:
```bash
curl -X GET "http://192.168.1.5:8080/api/plans?userId=1" \
  -H "Content-Type: application/json"
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Plans retrieved successfully",
  "data": [
    {
      "id": 1,
      "userId": 1,
      "name": "Push/Pull/Legs",
      "description": "3-day strength training program",
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
      "createdAt": "2025-12-23T10:30:00.000000",
      "updatedAt": "2025-12-23T10:30:00.000000"
    }
  ]
}
```

---

### 3. Get Single Plan
**Endpoint**: `GET /plans/{planId}?userId={userId}`

**Request**:
```bash
curl -X GET "http://192.168.1.5:8080/api/plans/1?userId=1" \
  -H "Content-Type: application/json"
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Plan retrieved successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "name": "Push/Pull/Legs",
    "description": "3-day strength training program",
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
    "createdAt": "2025-12-23T10:30:00.000000",
    "updatedAt": "2025-12-23T10:30:00.000000"
  }
}
```

---

### 4. Update Plan
**Endpoint**: `PUT /plans/{planId}?userId={userId}`

**Request**:
```bash
curl -X PUT "http://192.168.1.5:8080/api/plans/1?userId=1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Push/Pull/Legs - Updated",
    "description": "Updated 3-day strength program",
    "exercises": ["Bench Press", "Incline Dumbbell", "Squats"]
  }'
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Plan updated successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "name": "Push/Pull/Legs - Updated",
    "description": "Updated 3-day strength program",
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
        "name": "Squats",
        "order": 2
      }
    ],
    "createdAt": "2025-12-23T10:30:00.000000",
    "updatedAt": "2025-12-23T10:45:00.000000"
  }
}
```

---

### 5. Delete Plan
**Endpoint**: `DELETE /plans/{planId}?userId={userId}`

**Request**:
```bash
curl -X DELETE "http://192.168.1.5:8080/api/plans/1?userId=1" \
  -H "Content-Type: application/json"
```

**Response** (Status: 200):
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Plan deleted successfully"
}
```

---

## Error Responses

### 1. Validation Error
**Status**: 400
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": {
    "name": "Name cannot be blank",
    "password": "Password is required"
  }
}
```

### 2. Not Found Error
**Status**: 401
```json
{
  "success": false,
  "statusCode": 401,
  "message": "Plan not found"
}
```

### 3. Conflict Error (e.g., Email already exists)
**Status**: 409
```json
{
  "success": false,
  "statusCode": 409,
  "message": "Email already registered"
}
```

### 4. Server Error
**Status**: 500
```json
{
  "success": false,
  "statusCode": 500,
  "message": "An unexpected error occurred"
}
```

---

## Testing Workflow

### 1. Register New User
```bash
curl -X POST http://192.168.1.5:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

### 2. Login with the registered user
```bash
curl -X POST http://192.168.1.5:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "password123"
  }'
```
> Note: Extract the user ID from the response to use in plan operations

### 3. Create a plan (use userId from login response)
```bash
curl -X POST "http://192.168.1.5:8080/api/plans?userId=1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My First Plan",
    "description": "My workout plan",
    "exercises": ["Push-ups", "Squats", "Running"]
  }'
```

### 4. Get all plans
```bash
curl -X GET "http://192.168.1.5:8080/api/plans?userId=1"
```

### 5. Update a plan
```bash
curl -X PUT "http://192.168.1.5:8080/api/plans/1?userId=1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Plan",
    "description": "Updated description",
    "exercises": ["Pull-ups", "Squats"]
  }'
```

### 6. Delete a plan
```bash
curl -X DELETE "http://192.168.1.5:8080/api/plans/1?userId=1"
```

### 7. Logout
```bash
curl -X POST "http://192.168.1.5:8080/api/auth/logout?userId=1"
```

---

## Notes

- All requests require `Content-Type: application/json` header
- User ID is passed as a query parameter in all plan operations for authorization
- Exercises are stored as a simple list of strings with automatic ordering
- All timestamps are in ISO 8601 format
- Success field always indicates whether the operation succeeded (true/false)
- Error field contains validation errors only when applicable
- HTTP status codes match the standard REST conventions (200, 201, 400, 401, 409, 500)
