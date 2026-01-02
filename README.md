# Liftly 💪

**Liftly** is a modern, premium workout tracker and statistics application built with Flutter. It is designed to help users track their lifting progress, analyze trends, and visualize personal records with a beautiful, dynamic user interface.

## ✨ Features

*   **📈 Advanced Analytics**: Visualize your progress with interactive charts for workout frequency, volume, and intensity.
*   **🏆 Personal Records**: Automatically track and highlight your PRs across different exercises.
*   **📅 Dynamic Time Periods**: View stats by Week, Month, or Year with a sticky, intuitive date navigator.
*   **📱 Cross-Platform**: Optimized for Android, iOS, macOS, Windows, and Linux.
*   **🎨 Premium UI/UX**: Features a dark mode design with glassmorphism effects, smooth animations, and haptic feedback.
*   **📤 Shareable Stats**: Export your workout summaries directly to Instagram Stories or other social media.

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

---
*Built with ❤️ by Hafidz*
