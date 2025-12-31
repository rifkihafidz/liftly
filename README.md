# Liftly - Workout Logging & Planning Application

A comprehensive mobile and web application for fitness enthusiasts to plan, log, and track their workout sessions with detailed exercise metrics and progress tracking.

## 📱 Overview

Liftly helps users create personalized workout plans, log their exercise sessions in real-time, and track their fitness progress over time. The app provides an intuitive interface for managing multiple exercises per workout, including support for drop sets and detailed metrics like weight, repetitions, and notes.

### Key Capabilities
- **Workout Planning**: Create custom workout plans with multiple exercises
- **Session Tracking**: Log workouts in real-time with start/end times
- **Exercise Management**: Add, edit, and delete exercises with detailed metrics
- **Set Management**: Support for regular sets and drop sets
- **Progress History**: View past workouts and track performance
- **User Authentication**: Secure login with JWT tokens

---

## 🏗️ Architecture

### Tech Stack

**Backend:**
- **Language**: Java 17
- **Framework**: Spring Boot 3.2.0
- **Database**: PostgreSQL
- **Authentication**: Basic auth (JWT planned ⚠️)
- **API**: RESTful JSON API
- **Serialization**: Jackson with custom deserializers

**Frontend:**
- **Language**: Dart
- **Framework**: Flutter
- **State Management**: BLoC (Business Logic Component)
- **HTTP Client**: Dio
- **Localization**: Intl (Indonesian support)

**Deployment:**
- **Database**: Docker PostgreSQL
- **Backend**: Spring Boot application
- **Frontend**: Flutter Web & Mobile (iOS/Android)

### Project Structure

```
liftly/
├── backend/                          # Java Spring Boot API
│   ├── src/main/java/com/liftly/
│   │   ├── api/
│   │   │   ├── controller/          # REST API endpoints
│   │   │   ├── dto/                 # Data Transfer Objects
│   │   │   ├── exception/           # Custom exceptions
│   │   │   └── service/             # Business logic
│   │   ├── core/
│   │   │   ├── entity/              # JPA entities (User, Plan, Workout, etc.)
│   │   │   ├── repository/          # Database repositories
│   │   │   └── security/            # JWT & authentication
│   │   └── Application.java         # Main entry point
│   ├── src/main/resources/
│   │   ├── application.properties    # Configuration
│   │   └── init.sql                  # Database initialization
│   ├── pom.xml                       # Maven dependencies
│   └── mvnw                          # Maven wrapper
│
├── frontend/                         # Flutter application
│   ├── lib/
│   │   ├── main.dart                 # App entry point
│   │   ├── core/
│   │   │   ├── constants/            # Colors, strings, etc.
│   │   │   ├── models/               # Data models
│   │   │   └── services/             # API client, local storage
│   │   ├── features/
│   │   │   ├── auth/                 # Authentication pages & BLoC
│   │   │   ├── session/              # Workout session creation
│   │   │   ├── workout_log/          # Workout history & editing
│   │   │   └── profile/              # User profile
│   │   └── shared/
│   │       └── widgets/              # Reusable UI components
│   ├── pubspec.yaml                  # Flutter dependencies
│   ├── android/                      # Android native code
│   ├── ios/                          # iOS native code
│   └── web/                          # Web deployment
│
├── docker-compose.yml                # Local development environment
├── SETUP.md                          # Setup & installation guide
├── API_TESTING.md                    # API endpoint documentation
├── COMMIT_NOTES.md                   # Latest commit details
├── FILE_CHANGES.md                   # Detailed file changes
├── COMMIT_QUICK_REF.md               # Quick commit reference
└── README.md                         # This file
```

---

## 🚀 Getting Started

### Prerequisites

**Required:**
- Java 17 or higher
- Maven 3.8+
- Node.js 18+ (for Flutter web development)
- Docker & Docker Compose
- Flutter SDK (for mobile/web development)

**Optional:**
- Android Studio (for Android development)
- Xcode (for iOS development)
- VS Code with extensions

### Installation & Setup

See [SETUP.md](./SETUP.md) for detailed installation instructions.

**Quick Start:**

```bash
# 1. Start PostgreSQL database
docker-compose up -d

# 2. Run backend API
cd backend
./mvnw spring-boot:run
# API starts at http://localhost:8080/api

# 3. Run frontend (in new terminal)
cd frontend
flutter pub get
flutter run -d chrome
# App opens in Chrome at http://localhost
```

---

## 📚 API Documentation

### Authentication

**Register:**
```bash
POST /api/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Login:**
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

# Returns: { "token": "jwt_token_here" }
```

### Workout Plans

**Create Plan:**
```bash
POST /api/plans?userId=1
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Chest & Triceps",
  "description": "Monday routine",
  "exercises": [
    {
      "name": "Bench Press",
      "order": 1
    }
  ]
}
```

**Get All Plans:**
```bash
GET /api/plans?userId=1
Authorization: Bearer {token}
```

**Get Plan Details:**
```bash
GET /api/plans/1?userId=1
Authorization: Bearer {token}
```

### Workout Sessions

**Create Workout Session:**
```bash
POST /api/workouts?userId=1
Authorization: NOT YET IMPLEMENTED (JWT)
Content-Type: application/json

# Note: Currently requires userId as query parameter
# TODO: Implement JWT token-based authorization

{
  "workoutDate": "2025-12-23",
  "startedAt": "10:30:00",
  "endedAt": "16:45:30",
  "planId": 1,
  "exercises": [
    {
      "name": "Bench Press",
      "order": 1,
      "skipped": false,
      "sets": [
        {
          "setNumber": 1,
          "segments": [
            {
              "weight": 100,
              "repsFrom": 5,
              "repsTo": 8,
              "notes": "Heavy weight",
              "segmentOrder": 0
            }
          ]
        }
      ]
    }
  ]
}
```

**Update Workout:**
```bash
PUT /api/workouts/1?userId=1
Authorization: Bearer {token}
Content-Type: application/json

# Same structure as create
```

**Delete Workout:**
```bash
DELETE /api/workouts/1?userId=1
Authorization: Bearer {token}
```

**Get Workout Details:**
```bash
GET /api/workouts/1?userId=1
Authorization: Bearer {token}
```

See [API_TESTING.md](./API_TESTING.md) for complete API reference with all endpoints and examples.

---

## 🎯 Core Features

### 1. Workout Planning
- Create custom workout plans
- Add exercises to plans
- Organize exercises by order
- Edit and delete plans
- Reuse plans for multiple sessions

### 2. Session Tracking
- Start workout sessions (attached to plan or standalone)
- Real-time session timer
- Log individual exercises
- Track start and end times
- View session history

### 3. Exercise Management
- Add exercises with custom names
- Support for multiple sets per exercise
- Track weight (kg) and repetitions (reps)
- Add exercise notes
- Skip exercises if needed

### 4. Drop Set Support
- Create drop sets within exercises
- Multiple weight/rep combinations in single exercise
- Automatic segment ordering
- Delete individual drop sets
- Track progression within exercise

### 5. Progress Tracking
- View all past workouts
- Filter by date range
- See exercise details per session
- Track weight progression
- Compare sets and reps over time

### 6. User Management
- User login and registration
- User profile management
- Personal workout history
- User identification via userId parameter
- ⚠️ JWT authentication not yet implemented

---

## 📊 Data Models

### User
```dart
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Plan
```dart
class Plan {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Workout Session
```dart
class WorkoutSession {
  final int id;
  final int userId;
  final int? planId;
  final DateTime workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Exercise
```dart
class Exercise {
  final int? id;
  final String name;
  final int order;
  final bool skipped;
  final List<ExerciseSet> sets;
}
```

### Exercise Set
```dart
class ExerciseSet {
  final int? id;
  final int setNumber;
  final List<SetSegment> segments;
}
```

### Set Segment
```dart
class SetSegment {
  final int? id;
  final double weight;
  final int repsFrom;
  final int repsTo;
  final int segmentOrder;
  final String notes;
}
```

---

## 🔄 Data Flow

### Workout Creation Flow
1. User selects or creates a plan
2. Frontend creates WorkoutSession with plan exercises
3. User logs into StartWorkoutPage
4. SessionBloc manages session state
5. Session page displays exercises with custom widgets
6. User enters weight, reps, and notes for each set
7. OnSave: Backend receives workout data with temporary IDs
8. Backend returns real database IDs
9. Frontend navigates to detail page with real IDs
10. User can view or edit the saved workout

### Workout Editing Flow
1. User views workout in history
2. Navigates to detail page
3. Clicks edit to open edit page
4. Same UI as session page but with existing data
5. ID validation prevents duplicate exercises
6. OnSave: Only exercises with valid IDs are sent
7. Backend validates and updates
8. Frontend updates local state

### Delete Workflow
1. User clicks delete in detail page
2. Confirmation dialog appears
3. Backend deletes workout
4. Frontend navigates to history with `fromDelete: true`
5. PopScope prevents back navigation
6. User stays in history list

---

## 🎨 UI/UX Features

### Custom Widgets
- **_WeightField**: Weight input with kg label
- **_NumberField**: Numeric input for reps
- **_ToField**: To reps field with integrated delete button
- **_NotesField**: Multi-line notes input
- **_DateTimeInput**: Date/time display with edit capability
- **_WorkoutDateTimeDialog**: Unified date/time picker

### Design System
- **Colors**: Custom app colors (primary, accent, error, etc.)
- **Typography**: Consistent text styles using TextTheme
- **Spacing**: 8pt baseline grid
- **Cards**: Rounded corners (12pt radius) with shadows
- **Buttons**: Elevated buttons with icons for primary actions

### Localization
- Indonesian locale support (`id_ID`)
- Date formatting: `d MMMM y` (e.g., "23 Desember 2025")
- Time formatting: 24-hour format (`HH:mm`)

---

## 🔐 Security

### Authentication
- ⚠️ **JWT NOT YET IMPLEMENTED** - Currently using basic auth
- Secure password hashing with bcrypt
- User login/register endpoints ready
- User isolation via userId parameter

⚡ **TODO**: Implement JWT token generation and validation

### Authorization
- ✅ User ID validation via request parameters
- ⚠️ **TODO**: Implement JWT-based endpoint authorization
- ⚠️ **TODO**: Row-level security for user data

**Note:** All endpoints currently have `permitAll()` - authorization via userId parameter in requests

### Data Validation
- Frontend form validation
- Backend input sanitization
- Type validation for all fields
- Null safety with Dart null-safety

### API Security
- CORS configuration for web access
- Request validation at controller level
- Error handling without exposing internal details

---

## 📊 Date/Time Handling

### Format Standards
- **API Request Date**: `YYYY-MM-DD` (LocalDate)
- **API Request Time**: `HH:MM:SS` (time component)
- **API Response DateTime**: `yyyy-MM-dd HH:mm:ss` (ISO-like)
- **Display Format**: `d MMMM y` with Indonesian locale
- **Timezone**: UTC throughout backend

### Custom Deserializer
TimeDeserializer converts time-only strings (`HH:mm:ss`) to LocalDateTime combined with workout date by service layer.

---

## 🧪 Testing

### Backend Testing
- Unit tests for service layer
- Integration tests for API endpoints
- Database test fixtures

### Frontend Testing
- Widget tests for UI components
- BLoC tests for state management
- Integration tests for complete flows

### Manual Testing
See [API_TESTING.md](./API_TESTING.md) for manual testing procedures with curl commands.

---

## 🔄 Recent Updates

### Workout Logging Feature (Latest)
- ✅ Fixed session creation with real database IDs
- ✅ Added unified date/time picker
- ✅ Implemented custom field widgets
- ✅ Fixed delete workflow
- ✅ Standardized datetime format
- ✅ Added Indonesian locale support

See [COMMIT_NOTES.md](./COMMIT_NOTES.md) for comprehensive changelog.

---

## 📈 Future Enhancements

### Priority 1 - Critical
- [ ] **JWT Authentication** (high priority - marked as TODO)
  - Implement JWT token generation on login
  - Add JWT validation filter to SecurityConfig
  - Implement token refresh endpoint
  - Add token expiration handling

### Priority 2 - Features
- [ ] Workout templates
- [ ] Exercise library with form tips
- [ ] Weight progression analytics
- [ ] Social features (share workouts)
- [ ] Offline mode
- [ ] Push notifications for workout reminders
- [ ] Integration with wearables
- [ ] Video demonstrations for exercises
- [ ] AI-powered workout suggestions
- [ ] Export workouts to PDF

### Improvements
- [ ] Performance optimization
- [ ] Improved caching
- [ ] Offline-first architecture
- [ ] Enhanced error handling
- [ ] More localization options
- [ ] Dark mode support

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "feat: description"`
3. Push to branch: `git push origin feature/your-feature`
4. Open pull request with description

### Code Style
- Backend: Follow Google Java Style Guide
- Frontend: Follow Effective Dart style guide
- Write meaningful commit messages
- Include tests for new features

### Reporting Issues
Please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, app version, etc.)

---

## 📞 Support & Contact

For questions or support:
- Check existing documentation
- Review API_TESTING.md for API usage
- Check SETUP.md for setup issues
- Open an issue on the repository

---

## 📄 License

This project is private and proprietary.

---

## 📋 Quick Links

- [Setup Guide](./SETUP.md) - Installation and configuration
- [API Testing](./API_TESTING.md) - API endpoints and examples
- [Commit Notes](./COMMIT_NOTES.md) - Latest changes
- [File Changes](./FILE_CHANGES.md) - Detailed file modifications
- [Quick Reference](./COMMIT_QUICK_REF.md) - Quick commit guide

---

## 🎓 Learning Resources

### For Backend Development
- Spring Boot Docs: https://spring.io/projects/spring-boot
- Spring Data JPA: https://spring.io/projects/spring-data-jpa
- Spring Security: https://spring.io/projects/spring-security

### For Frontend Development
- Flutter Docs: https://flutter.dev/docs
- BLoC Pattern: https://bloclibrary.dev/
- Dart Language: https://dart.dev/guides

### For API Development
- RESTful API Design: https://restfulapi.net/
- JSON Best Practices: https://www.json.org/

---

## 📝 Changelog

## 📊 Implementation Status

✅ **IMPLEMENTED:**
- Workout planning & session tracking
- Exercise management with drop sets
- User registration & login endpoints
- Password hashing with bcrypt
- Responsive date/time handling
- Comprehensive API
- Custom field widgets & UI

⚠️ **NOT YET IMPLEMENTED:**
- JWT token generation and validation
- Token refresh endpoints
- Proper endpoint-level JWT authorization
- Token expiration handling

**Current Authentication:** Basic auth with userId parameter in requests
**Planned Authentication:** JWT (Spring Security)

---

**Last Updated:** December 31, 2025

For the latest updates, see [COMMIT_NOTES.md](./COMMIT_NOTES.md)
