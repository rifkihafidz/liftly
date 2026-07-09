# Frontend Models Documentation

## Overview
This directory contains all data models used in the Liftly Flutter application. The models follow Dart best practices and use Equatable for value comparison.

## Key Models

### ApiResponse<T> - Base Response Model
**File**: `api_response.dart`

The generic response model that wraps all API responses from the backend. This ensures consistent error handling and response parsing across the application.

**Key Features**:
- Generic type T for flexible data types
- Consistent success/error structure
- Built-in JSON serialization
- Equatable for easy testing

**Structure**:
```dart
class ApiResponse<T> {
  bool success;           // Whether the operation succeeded
  int statusCode;         // HTTP status code
  String message;         // Descriptive message
  T? data;               // Response payload (any type)
  Map<String, dynamic>? errors;  // Validation errors
}
```

**Usage Examples**:
```dart
// Success response with typed data
final response = await ApiService.loginTyped(...);
if (response.success) {
  final userData = response.data; // Type-safe!
  print(userData['id']);
}

// Error response with validation errors
if (!response.success && response.errors != null) {
  response.errors!.forEach((field, error) {
    print('$field: $error');
  });
}
```

**Factory Methods**:
- `ApiResponse.success()` - Create a success response
- `ApiResponse.error()` - Create an error response
- `ApiResponse.fromJson()` - Parse from JSON with custom data parser
- `toJson()` - Convert to JSON

---

### User - User Data Model
**File**: `user.dart`

Represents a user in the system with authentication and profile information.

**Fields**:
- `id` - User ID
- `email` - User email
- `firstName` - First name
- `lastName` - Last name

---

### WorkoutPlan - Plan Data Model
**File**: `workout_plan.dart`

Represents a workout plan with exercises.

**Fields**:
- `id` - Plan ID
- `userId` - Owner user ID
- `name` - Plan name
- `description` - Plan description
- `exercises` - List of exercises in the plan
- `createdAt` - Creation timestamp
- `updatedAt` - Last update timestamp

---

### CustomExercise & WorkoutSession
**Files**: `custom_exercise.dart`, `workout_session.dart`

Support models for exercises and workout sessions.

---

## Working with ApiResponse

### Basic Usage

```dart
// Using legacy method (returns only data)
final userData = await ApiService.login(email: 'user@test.com', password: 'pass');

// Using new typed method (returns ApiResponse<T>)
final response = await ApiService.loginTyped(email: 'user@test.com', password: 'pass');
if (response.success) {
  final userData = response.data;
} else {
  print('Error: ${response.message}');
}
```

### Error Handling

```dart
final response = await ApiService.getPlansTyped(userId: '1');

if (!response.success) {
  switch (response.statusCode) {
    case 400:
      // Validation errors
      print('Field errors: ${response.errors}');
      break;
    case 401:
      // Not found or auth error
      print(response.message);
      break;
    case 409:
      // Conflict
      print(response.message);
      break;
    case 500:
      // Server error
      print('Server error');
      break;
  }
}
```

### Type Safety

```dart
// Strongly typed response parsing
final response = await ApiService.getPlansTyped(userId: '1');

// response.data is List<Map<String, dynamic>>
// No need for runtime type checks!
if (response.success) {
  for (final plan in response.data!) {
    print('Plan: ${plan['name']}');
  }
}
```

---

## Creating Custom ApiResponse Models

You can create specific typed models for complex responses:

```dart
// For a response containing a single plan
class PlanResponse extends ApiResponse<Map<String, dynamic>> {
  PlanResponse({
    required bool success,
    required int statusCode,
    required String message,
    Map<String, dynamic>? data,
    Map<String, dynamic>? errors,
  }) : super(
    success: success,
    statusCode: statusCode,
    message: message,
    data: data,
    errors: errors,
  );
}
```

---

## Model Equality Testing

All models extend Equatable, making them easy to test:

```dart
final response1 = ApiResponse<String>.success(
  data: 'test',
  message: 'Success',
);

final response2 = ApiResponse<String>.success(
  data: 'test',
  message: 'Success',
);

// Easy equality comparison
expect(response1, equals(response2));
```

---

## Best Practices

1. **Always check `success` flag** before accessing `data`
2. **Use typed methods** from ApiService for better type safety
3. **Handle validation errors** by checking the `errors` map
4. **Follow status code conventions** in error handling
5. **Use Equatable** for easy model comparison in tests
6. **Provide dataParser** function when using `fromJson()`

---

## Backward Compatibility

The original `_handleResponse()` method in ApiService is maintained for backward compatibility. Legacy code continues to work without modifications:

```dart
// Old method - still works
final data = await ApiService.login(...);

// New method - better error handling
final response = await ApiService.loginTyped(...);
```

---

**Last Updated**: December 23, 2025
**Version**: 1.0.0
