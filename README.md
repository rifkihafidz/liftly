# Liftly 💪

**Liftly** is a modern, premium workout tracker and statistics application built with Flutter. It is designed to help users track their lifting progress, analyze trends, and visualize personal records with a beautiful, dynamic user interface.

## ✨ Features

*   **📋 Workout Plans**: Create, edit, and organize reusable workout routines.
*   **▶️ Smart Session Queue**: Start workouts from defined plans or queue exercises on the fly.
*   **📈 Advanced Analytics**: Visualize your progress with interactive charts for workout frequency, volume, and intensity.
*   **🏆 Personal Records**: Automatically track and highlight your PRs across different exercises.
*   **📜 Workout History**: Detailed logs of past workouts with filtering and editing capabilities.
*   **💪 Flexible Sets**: Support for Normal, Warmup, and Drop Sets with easy logging.
*   **💬 Daily Motivation**: Random motivational quotes to keep you inspired.
*   **📅 Dynamic Time Periods**: View stats by Week, Month, or Year with a sticky, intuitive date navigator.
*   **📱 Cross-Platform**: Optimized for Android, iOS, macOS, Windows, and Linux.
*   **🎨 Premium UI/UX**: Features a consistent dark mode design, glassmorphism effects, and smooth animations.
*   **📤 Shareable Stats**: Export your workout summaries as images to social media.

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest stable version recommended)
*   Dart SDK
*   Android Studio / Xcode (for mobile development)

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
│   ├── features/       # Feature-specific code (Stats, Workout Log, Plans)
│   │   ├── stats/
│   │   ├── workout_log/
│   │   └── ...
│   ├── shared/         # Reusable widgets and UI components
│   └── main.dart       # Entry point
├── android/            # Android native code
├── ios/                # iOS native code
├── macos/              # macOS native code
└── ...
```

## 🛠️ Built With

*   **[Flutter](https://flutter.dev/)** - UI Toolkit
*   **[fl_chart](https://pub.dev/packages/fl_chart)** - For rendering beautiful charts
*   **[flutter_bloc](https://pub.dev/packages/flutter_bloc)** - State management
*   **[sqflite](https://pub.dev/packages/sqflite)** - Local database storage

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.