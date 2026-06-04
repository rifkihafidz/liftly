# Liftly 💪

**Liftly** is a modern, premium workout tracker and statistics application built with Flutter. It is designed to help users track their lifting progress, analyze trends, and visualize personal records with a beautiful, dynamic user interface.

## ✨ Features

- **📋 Workout Plans**: Create, edit, and organize reusable workout routines.
- **▶️ Smart Session Queue**: Start workouts from defined plans or queue exercises on the fly.
- **📈 Advanced Analytics**: Visualize your progress with interactive charts for workout frequency, volume, and intensity.
- **🏆 Personal Records**: Automatically track and highlight your PRs across different exercises.
- **📜 Workout History**: Detailed logs of past workouts with filtering and editing capabilities.
- **🛠️ Exercise Management**: Bulk edit, rename, and intelligently merge duplicate exercises in your glossary.
- **💪 Flexible Sets**: Support for Normal, Warmup, and Drop Sets with easy logging.
- **☁️ Cloud Backup**: Automatic backup to Google Drive with one-click restore.
- **📤 Import/Export**: Export and import your data in Excel format (.xlsx).
- **💬 Daily Motivation**: Random motivational quotes to keep you inspired.
- **📅 Dynamic Time Periods**: View stats by Week, Month, or Year with a sticky, intuitive date navigator.
- **📱 Cross-Platform**: Optimized for Android, iOS, macOS, Windows, Linux, and Web.
- **🎨 Premium UI/UX**: Features a consistent dark mode design, glassmorphism effects, and smooth animations.
- **🔥 Muscle Heatmap**: Interactive visualizer showing targeted muscle groups based on workout intensity.
- **📤 Advanced Sharing**: Export aesthetic workout summaries and heatmaps with customizable data points and transparent backgrounds.
- **⚡ Performance Optimized**: Handles 1000+ workouts efficiently with intelligent caching.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest stable version recommended)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1.  **Clone the repository**

    ```bash
    git clone https://github.com/rifkihafidz/liftly.git
    cd liftly
    ```

2.  **Install dependencies**

    ```bash
    flutter pub get
    ```

3.  **Run the application**
    ```bash
    # Run on your connected device or emulator
    flutter run
    ```

## 📂 Project Structure

The project follows a feature-first architecture for scalability and maintainability.

```
liftly/
├── lib/
│   ├── core/           # Core utilities, services, and models
│   ├── features/       # Feature-specific code (Stats, Workout Log, Plans, Session)
│   │   ├── stats/
│   │   ├── workout_log/
│   │   ├── session/
│   │   ├── settings/
│   │   └── ...
│   ├── shared/         # Reusable widgets and UI components
│   └── main.dart       # Entry point
├── android/            # Android native code
├── ios/                # iOS native code
├── macos/              # macOS native code
├── web/                # Web platform files
└── ...
```

## 🛠️ Built With

- **[Flutter](https://flutter.dev/)** - UI Toolkit
- **[fl_chart](https://pub.dev/packages/fl_chart)** - For rendering beautiful charts
- **[flutter_bloc](https://pub.dev/packages/flutter_bloc)** - State management
- **[hive](https://pub.dev/packages/hive)** - Fast, lightweight local database
- **[google_sign_in](https://pub.dev/packages/google_sign_in)** - Google authentication
- **[googleapis](https://pub.dev/packages/googleapis)** - Google Drive integration
- **[excel](https://pub.dev/packages/excel)** - Excel file generation and parsing

## � Changelog

### v2.4.0
- **Feature**: Introduced an interactive **Muscle Heatmap** visualizer (Front & Back anatomy) with dynamic intensity color-coding (Yellow, Orange, Red) based on workout volume.
- **Feature**: Enhanced **Workout Sharing** capabilities. Users can now share aesthetic workout summaries or muscle heatmaps as high-quality images with togglable transparent backgrounds and customizable data points.
- **Feature**: Added a mini exercise log preview directly on the Workout Session History Cards.
- **UI/UX**: Standardized UI consistency, resolved RenderFlex overflows, and improved the `ExerciseDetailCard` state persistence during scrolling.

### v2.3.6
- **Feature**: Added **Exercise Management** to bulk edit, rename, and intelligently merge duplicate exercises across all past workouts and plans.
- **UI/UX**: Enforced strict mobile-width layout constraint (`480px`) on Web platform to guarantee interface integrity.
- **UI/UX**: Standardized navigation transitions globally using a custom `SmoothPageRoute`.
- **Bug fixes**: Resolved calculation bugs for Personal Records (PR) and "Best Session" when merging multiple exercises in the same session.
- **Bug fixes**: Fixed race conditions in dialog navigations to prevent immediate pop dismissals on async operations.
- **Data Management**: Updated local data repository logic (`HiveService`) with robust cache invalidation and synchronized state handling.

### v2.0.0
- **Bug fixes**: Resolved workout history stale data after editing a workout
- **Bug fixes**: Success popup now correctly appears after saving workout edits
- **Stability**: Comprehensive codebase audit — removed dead code, fixed minor bugs across 76+ files
- **Refactor**: Unified logging via `AppLogger`; replaced hardcoded constants with `AppConstants`
- **UI**: Scroll-to-top on tab re-select for all 5 main pages via `IndexedStack` + `ActiveTabScope`

## �📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
