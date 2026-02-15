import 'package:flutter/material.dart';

class AppConstants {
  // --- General ---
  static const String appVersion = '1.1.2';
  static const String appName = 'Liftly';

  // --- Backup & Cloud ---
  static const String googleClientId =
      '640418928410-gi91t91l20sn2roq14r7snvpptlff6mq.apps.googleusercontent.com';
  static const String backupFolderName = 'Liftly Backup';
  static const String backupMimeFolder = 'application/vnd.google-apps.folder';
  static const String excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  // --- Storage & Database ---
  static const String workoutBox = 'workouts';
  static const String planBox = 'plans';
  static const String settingsBox = 'settings';
  static const String metaBox = 'workout_metadata';

  // --- Excel Export ---
  static const String sheetWorkouts = 'workouts';
  static const String sheetWorkoutExercises = 'workout_exercises';
  static const String sheetWorkoutSets = 'workout_sets';
  static const String sheetSetSegments = 'set_segments';
  static const String sheetPlans = 'plans';
  static const String sheetPlanExercises = 'plan_exercises';

  // --- UI Strings ---
  static const String headerCloudBackup = 'CLOUD BACKUP';
  static const String headerLocalData = 'LOCAL DATA';
  static const String headerDangerZone = 'DANGER ZONE';

  static const String titleExportOptions = 'Export Options';
  static const String titleImportData = 'Import Data';
  static const String titleRestoreCloud = 'Restoring from Cloud';

  // --- UI Styling ---
  static const double defaultPadding = 24.0;
  static const double itemSpacing = 12.0;
  static const double subSectionSpacing = 16.0;
  static const double sectionSpacing = 32.0;

  static const TextStyle versionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
