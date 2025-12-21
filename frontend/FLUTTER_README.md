# Liftly - Flutter Frontend

## ✨ Project Structure

```
lib/
├── main.dart                 # App entry point & auth wrapper
├── config/
│   └── theme/
│       └── app_theme.dart    # Dark theme with custom colors
├── core/
│   ├── constants/
│   │   └── colors.dart       # Color palette
│   └── models/
│       ├── user.dart         # User model
│       ├── workout_plan.dart # Plan & Exercise models
│       └── workout_session.dart # Session & Set models
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   ├── auth_event.dart
│   │   │   ├── auth_state.dart
│   │   │   └── auth_bloc.dart
│   │   ├── pages/
│   │   │   └── login_page.dart
│   │   └── repositories/
│   ├── home/
│   │   └── pages/
│   │       └── home_page.dart
│   ├── plans/
│   │   ├── bloc/
│   │   ├── pages/
│   │   └── repositories/
│   ├── session/
│   │   ├── bloc/
│   │   │   ├── session_event.dart
│   │   │   ├── session_state.dart
│   │   │   └── session_bloc.dart
│   │   ├── pages/
│   │   │   └── session_page.dart
│   │   └── repositories/
│   └── stats/
│       ├── bloc/
│       └── pages/
└── shared/
    └── widgets/
        └── input_field.dart
```

## 🎨 UI Pages

### 1. **Login Page** (`lib/features/auth/pages/login_page.dart`)
- Clean, dark-themed login form
- Email & password input fields
- Form validation
- Loading state with spinner
- Mock login support (any email/password)

### 2. **Home Page** (`lib/features/home/pages/home_page.dart`)
- 4 menu cards:
  - **Start Workout** → Navigate to session logging
  - **Workout Plans** → Plan CRUD (coming soon)
  - **Workout History** → View/edit past sessions (coming soon)
  - **Statistics** → View progress & stats (coming soon)
- Logout button in AppBar

### 3. **Session Logging Page** (`lib/features/session/pages/session_page.dart`)
- Real-time workout timer in AppBar
- Exercise list with:
  - Skip/unskip toggle
  - Add set button
  - Visual feedback for skipped exercises
- Set card UI showing:
  - Set number & dropset indicator
  - All segments with weight, reps, volume
  - Delete set button
  - **"Add Drop" button** for creating dropsets
- Dialogs for:
  - Adding new sets
  - Adding dropset segments
- Finish Workout button to save session

## 🎯 Key Features Implemented

### ✅ Authentication
- Login form with validation
- Auth BLoC for state management
- Auth wrapper for navigation

### ✅ Session Logging with Dropset Logic
**Your proposed dropset UX is implemented:**
1. Add a set → creates 1 segment (weight + reps_from + reps_to)
2. Click **"Add Drop"** → creates new segment for same set
3. Each segment shows: weight, reps, calculated volume
4. Can delete individual segments (except the last one)
5. Delete entire set with one click

**Segment Example:**
```
Set #1 (Dropset)
├─ Segment #1: [50kg] [6-8 reps] Vol: 350
├─ [+ Add Drop]
└─ Segment #2: [40kg] [8-10 reps] Vol: 360
   └─ [+ Add Drop]
```

### ✅ BLoC Architecture
- **AuthBloc** - User authentication
- **SessionBloc** - Workout session management with:
  - SessionStarted
  - SessionExerciseSkipped/Unskipped
  - SessionSetAdded/Removed
  - SessionSegmentAdded/Removed
  - SessionEnded
  - SessionSaveRequested

### ✅ Dark Mode Theme
- Custom color palette (AppColors)
- All components styled for dark UI
- Accent blue (#1E88E5) for highlights
- Consistent typography

### ✅ State Management
- Immutable models with Equatable
- BLoC pattern for all features
- Clean separation of concerns

## 📦 Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.4      # State management
  bloc: ^8.1.4              # BLoC core
  equatable: ^2.0.5         # Value equality
  http: ^1.1.0              # API calls (ready for backend integration)
  intl: ^0.19.0             # Internationalization
```

## 🚀 Running the App

### From VS Code with launch config:
```bash
Press F5 or Run > Start Debugging
Select "frontend" configuration
```

### From terminal:
```bash
cd frontend
flutter pub get
flutter run -d <device_id>
```

### Available devices:
```bash
flutter devices
```

## 🎮 Testing the App

1. **Login Screen**
   - Enter any email & password
   - Click "Login"
   - Mock login takes 1 second

2. **Home Screen**
   - Shows 4 menu options
   - Click "Start Workout" to try session logging

3. **Session Logging**
   - App provides 4 sample exercises
   - For each exercise:
     - Click on exercise to skip it
     - Click "Add Set" to add a new set
     - Click "Add Drop" to add dropset segment
     - Delete segments or entire set as needed
   - Timer running in AppBar
   - Click "Finish Workout" to save

## 📝 Models

### User
```dart
User(id, email, token)
```

### WorkoutSession
```dart
WorkoutSession(
  id, userId, planId?, workoutDate,
  startedAt?, endedAt?, exercises,
  createdAt, updatedAt
)
```

### SessionExercise
```dart
SessionExercise(
  id, name, variant?, order,
  skipped, sets
)
```

### ExerciseSet
```dart
ExerciseSet(
  id, segments[], setNumber
)
```

### SetSegment
```dart
SetSegment(
  id, weight, repsFrom, repsTo, segmentOrder
)
// Calculated properties:
// - totalReps = repsTo - repsFrom + 1
// - volume = weight * totalReps
```

## 🔮 Next Steps

1. **Backend Integration**
   - Implement API repositories
   - Connect HTTP calls to backend endpoints
   - Add JWT token management

2. **Workout Plans CRUD**
   - Create/read/update/delete plans
   - Manage plan exercises
   - Create session from plan

3. **Workout History**
   - List past sessions
   - Edit existing sessions
   - Delete sessions

4. **Statistics**
   - Top weight per exercise
   - Total volume calculation
   - Charts & visualizations

5. **Additional Features**
   - Exercise database/search
   - Workout notes
   - Rest timer between sets
   - Photo/video support

## 💡 Design Decisions

- **Dark mode only**: As per spec, all UI optimized for dark theme
- **BLoC pattern**: Scalable, testable state management
- **Immutable models**: Prevents accidental state mutations
- **Dropset UX**: Simple, intuitive flow that matches real gym logging
- **No validation on app start**: Focuses on logging, validation on save

## 📱 UI Colors

| Color | Value |
|-------|-------|
| Dark Background | `#0F0F0F` |
| Card Background | `#1A1A1A` |
| Input Background | `#252525` |
| Accent (Blue) | `#1E88E5` |
| Text Primary | `#FFFFFF` |
| Text Secondary | `#B0B0B0` |
| Success (Green) | `#4CAF50` |
| Error (Red) | `#F44336` |

---

**Ready to start coding the backend?** 🔥
