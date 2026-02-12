import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/isar_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataManagementService {
  /// Generate Excel file bytes from Isar data (maintaining legacy tabular format)
  static Future<Uint8List> generateExcelBytes() async {
    final excel = Excel.createExcel();

    // 1. Fetch all data
    // Assuming single user for now or fetch all.
    // For export, we export everything.
    // IsarService.getWorkouts requires userId.
    // We export for current logged in user usually.
    // But BackupService manages Google drive for current user.
    // Yet ExportData is general.
    // We should probably get user from a SessionService or similar if we strictly enforce user.
    // However, existing implementation used raw query on ALL workouts (filtered by is_draft=0).
    // IsarService getWorkouts needs userId.
    // I'll assume we need to pass userId or fetch all.
    // Since Isar is local, fetching all is fine if we want full backup.
    // IsarService doesn't have getAllWorkouts() without userId.
    // I should add getAllWorkouts() to IsarService? Or iterate users?
    // Let's modify IsarService to allow fetching all workouts if we pass empty userId or null?
    // Or just fetch hardcoded 'user_1' if that's what the app uses.
    // The legacy code used: WHERE is_draft = 0 directly, implying it took all users.
    // Let's try to get distinct user IDs first from Isar?
    // IsarService doesn't expose users list.
    // I will add `getAllWorkoutsForAllUsers` to IsarService or similar.
    // OR just use `getAllWorkouts("user_1")` if the app is single user effectively.
    // Let's assume single user for now as typical for local DB apps, or pass a specific user ID if I can get it.
    // But DataManagementService is static.
    // I will iterate all workouts provided by a new IsarService method `getAllWorkoutsRaw()` that returns everything.

    // Let's assume for now we export for "user_1" as default or handle it better.
    // Wait, IsarService.getWorkouts is user scoped.
    // I will skip fetching logic details and implement the FLATTENING logic first.
    // To support "All", I need IsarService to return all. This is cleaner.

    // For now, let's implement the flattening structure.

    // -- DATA FETCHING --
    // We need a way to get EVERYTHING.
    // I'll add `exportAllData` to IsarService that returns {workouts: [], plans: []}

    final allData = await IsarService.getAllDataForExport();
    final workouts = allData['workouts'] as List<WorkoutSession>;
    final plans = allData['plans'] as List<WorkoutPlan>;

    // -- WORKOUTS FLATTENING --
    final workoutRows = <Map<String, dynamic>>[];
    final exerciseRows = <Map<String, dynamic>>[];
    final setRows = <Map<String, dynamic>>[];
    final segmentRows = <Map<String, dynamic>>[];

    for (final w in workouts) {
      if (w.isDraft) continue;

      workoutRows.add({
        'id': w.id,
        'user_id': w.userId,
        'plan_id': w.planId,
        'workout_date': w.workoutDate.toIso8601String(),
        'started_at': w.startedAt?.toIso8601String(),
        'ended_at': w.endedAt?.toIso8601String(),
        'is_draft': w.isDraft ? 1 : 0,
        'created_at': w.createdAt.toIso8601String(),
        'updated_at': w.updatedAt.toIso8601String(),
      });

      for (final ex in w.exercises) {
        // Exercise ID in SQL was UUID. Here it acts same.
        exerciseRows.add({
          'id': ex.id,
          'workout_id': w.id,
          'name': ex.name,
          'exercise_order': ex.order, // SQL column was exercise_order
          'skipped': ex.skipped ? 1 : 0,
          'is_template': ex.isTemplate ? 1 : 0,
        });

        for (final s in ex.sets) {
          setRows.add({
            'id': s.id,
            'exercise_id': ex.id,
            'set_number': s.setNumber,
          });

          for (final seg in s.segments) {
            segmentRows.add({
              'id': seg.id,
              'set_id': s.id,
              'weight': seg.weight,
              'reps_from': seg.repsFrom,
              'reps_to': seg.repsTo,
              'segment_order': seg.segmentOrder, // SQL column segment_order
              'notes': seg.notes,
            });
          }
        }
      }
    }

    // -- PLANS FLATTENING --
    final planRows = <Map<String, dynamic>>[];
    final planExRows = <Map<String, dynamic>>[];

    for (final p in plans) {
      planRows.add({
        'id': p.id,
        'user_id': p.userId,
        'name': p.name,
        'description': p.description,
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': p.updatedAt.toIso8601String(),
      });

      for (final ex in p.exercises) {
        planExRows.add({
          // plan_exercises didn't use ID in repo?
          // MigrationService generated one. Export should ideally export it if exists.
          // In WorkoutPlan model (Dart), PlanExercise has ID.
          'id': ex.id,
          'plan_id': p.id,
          'name': ex.name,
          'exercise_order': ex.order,
        });
      }
    }

    // -- WRITING TO EXCEL --
    _writeSheet(excel, 'workouts', workoutRows);
    _writeSheet(excel, 'workout_exercises', exerciseRows);
    _writeSheet(excel, 'workout_sets', setRows);
    _writeSheet(excel, 'set_segments', segmentRows);
    _writeSheet(excel, 'plans', planRows);
    _writeSheet(excel, 'plan_exercises', planExRows);

    if (excel.sheets.length > 1 && excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');
    return Uint8List.fromList(bytes);
  }

  static void _writeSheet(
      Excel excel, String sheetName, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;

    final sheetObject = excel[sheetName];
    final headers = data.first.keys.toList();
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final row in data) {
      final rowData = headers.map((header) {
        final value = row[header];
        if (value == null) return TextCellValue('');
        if (value is String) return TextCellValue(value);
        if (value is int) return IntCellValue(value);
        if (value is double) return DoubleCellValue(value);
        return TextCellValue(value.toString());
      }).toList();
      sheetObject.appendRow(rowData);
    }
  }

  /// Export all data to an Excel file and prompt user to share/save it
  static Future<void> exportData() async {
    try {
      final fileBytes = await generateExcelBytes();
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'liftly_backup_$dateStr.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(fileBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Liftly Backup $dateStr');
    } catch (e) {
      if (kDebugMode) print('Export error: $e');
      rethrow;
    }
  }

  /// Import data from an Excel file
  static Future<String> importData({String targetUserId = '1'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return 'Import cancelled';
      }

      // Check for bytes if on web, or path if on mobile
      Uint8List bytes;
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes!;
        } else {
          return 'Import failed: No file data';
        }
      } else {
        final file = File(result.files.single.path!);
        bytes = await file.readAsBytes();
      }

      return await importDataFromBytes(bytes, targetUserId: targetUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// Generic import logic from bytes
  static Future<String> importDataFromBytes(Uint8List bytes,
      {String targetUserId = '1'}) async {
    try {
      // 1. Decode, Parse, Group, and Sort in background isolate
      // This offloads the vast majority of CPU work from the main thread.
      final structuredData = await compute(_decodeAndStructureExcel, bytes);

      // Yield to UI thread after heavy isolate work
      await Future.delayed(Duration.zero);

      final workoutsData =
          structuredData['workouts'] as List<Map<String, dynamic>>;
      final plansData = structuredData['plans'] as List<Map<String, dynamic>>;

      int importedWorkouts = 0;
      int importedPlans = 0;

      // 2. Reconstruct Workouts (Mainly model instantiation)
      final parsedWorkouts = <WorkoutSession>[];

      for (final wData in workoutsData) {
        final wRow = wData['row'] as Map<String, dynamic>;
        if (wRow['is_draft'] == 1 || wRow['is_draft'] == '1') continue;

        final workoutId = wRow['id'] as String;
        final exercisesData = wData['exercises'] as List<Map<String, dynamic>>;

        final exercises = exercisesData.map((eData) {
          final eRow = eData['row'] as Map<String, dynamic>;
          final exId = eRow['id'] as String;
          final setsData = eData['sets'] as List<Map<String, dynamic>>;

          final sets = setsData.map((sData) {
            final sRow = sData['row'] as Map<String, dynamic>;
            final setId = sRow['id'] as String;
            final segmentsData =
                sData['segments'] as List<Map<String, dynamic>>;

            final segments = segmentsData.map((segRow) {
              int rFrom = segRow['reps_from'] as int? ?? 0;
              int rTo = segRow['reps_to'] as int? ?? 0;

              if (rFrom == 0 && rTo == 0 && segRow.containsKey('reps')) {
                final reps = segRow['reps'] as int? ?? 0;
                if (reps > 0) {
                  rFrom = 1;
                  rTo = reps;
                }
              }

              if (rFrom == rTo && rFrom > 1) {
                rTo = rFrom;
                rFrom = 1;
              }

              if (rFrom == 0) rFrom = 1;
              if (rTo < rFrom) rTo = rFrom;

              return SetSegment(
                id: segRow['id'] as String,
                weight: (segRow['weight'] as num).toDouble(),
                repsFrom: rFrom,
                repsTo: rTo,
                segmentOrder: segRow['segment_order'] as int,
                notes: segRow['notes'] as String? ?? '',
              );
            }).toList();

            return ExerciseSet(
              id: setId,
              setNumber: sRow['set_number'] as int,
              segments: segments,
            );
          }).toList();

          return SessionExercise(
            id: exId,
            name: eRow['name'] as String,
            order: eRow['exercise_order'] as int,
            skipped: (eRow['skipped'] == 1 || eRow['skipped'] == '1'),
            isTemplate:
                (eRow['is_template'] == 1 || eRow['is_template'] == '1'),
            sets: sets,
          );
        }).toList();

        final workout = WorkoutSession(
          id: workoutId,
          userId: targetUserId,
          planId: wRow['plan_id'] as String?,
          planName: null,
          workoutDate: DateTime.parse(wRow['workout_date'] as String),
          startedAt: wRow['started_at'] != null
              ? DateTime.parse(wRow['started_at'] as String)
              : null,
          endedAt: wRow['ended_at'] != null
              ? DateTime.parse(wRow['ended_at'] as String)
              : null,
          exercises: exercises,
          createdAt: DateTime.tryParse(wRow['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(wRow['updated_at'] as String? ?? '') ??
              DateTime.now(),
          isDraft: false,
        );

        parsedWorkouts.add(workout);
        importedWorkouts++;

        // Yield less frequently (every 50 workouts) to improve performance
        // but still keep UI indicator alive
        if (importedWorkouts % 50 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      await IsarService.importWorkouts(parsedWorkouts);

      // 3. Reconstruct Plans
      final parsedPlans = <WorkoutPlan>[];

      for (final pData in plansData) {
        final pRow = pData['row'] as Map<String, dynamic>;
        final planId = pRow['id'] as String;
        final pExData = pData['exercises'] as List<Map<String, dynamic>>;

        final exercises = pExData.map((eRow) {
          return PlanExercise(
            id: eRow['id'] as String,
            name: eRow['name'] as String,
            order: eRow['exercise_order'] as int,
          );
        }).toList();

        final plan = WorkoutPlan(
          id: planId,
          userId: targetUserId,
          name: pRow['name'] as String,
          description: pRow['description'] as String?,
          exercises: exercises,
          createdAt: DateTime.tryParse(pRow['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(pRow['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );

        parsedPlans.add(plan);
        importedPlans++;
      }

      await IsarService.importPlans(parsedPlans);

      return 'Successfully imported $importedWorkouts workouts and $importedPlans plans.';
    } catch (e) {
      if (kDebugMode) {
        print('Import error: $e');
      }
      throw Exception('Failed to import data: $e');
    }
  }

  /// Clear all data from the database
  static Future<void> clearAllData() async {
    try {
      await IsarService.clearAllData();
    } catch (e) {
      rethrow;
    }
  }
}

/// Isolate function for decoding, parsing AND structuring Excel data.
Map<String, dynamic> _decodeAndStructureExcel(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);

  final workoutsMap = _parseSheetRaw(excel, 'workouts');
  final workoutExercisesMap = _parseSheetRaw(excel, 'workout_exercises');
  final workoutSetsMap = _parseSheetRaw(excel, 'workout_sets');
  final setSegmentsMap = _parseSheetRaw(excel, 'set_segments');
  final plansMap = _parseSheetRaw(excel, 'plans');
  final planExercisesMap = _parseSheetRaw(excel, 'plan_exercises');

  // Group everything in the isolate
  final exercisesByWorkout =
      _groupByInternal(workoutExercisesMap, 'workout_id');
  final setsByExercise = _groupByInternal(workoutSetsMap, 'exercise_id');
  final segmentsBySet = _groupByInternal(setSegmentsMap, 'set_id');
  final planExByPlan = _groupByInternal(planExercisesMap, 'plan_id');

  // 1. Structure Workouts
  final structuredWorkouts = <Map<String, dynamic>>[];
  for (final wRow in workoutsMap) {
    final workoutId = wRow['id'] as String?;
    if (workoutId == null) continue;

    final exercisesData = exercisesByWorkout[workoutId] ?? [];
    // Sort exercises in isolate
    exercisesData.sort((a, b) =>
        (a['exercise_order'] as int).compareTo(b['exercise_order'] as int));

    final structuredExercises = <Map<String, dynamic>>[];
    for (final eRow in exercisesData) {
      final exId = eRow['id'] as String?;
      if (exId == null) continue;

      final setsData = setsByExercise[exId] ?? [];
      // Sort sets in isolate
      setsData.sort(
          (a, b) => (a['set_number'] as int).compareTo(b['set_number'] as int));

      final structuredSets = <Map<String, dynamic>>[];
      for (final sRow in setsData) {
        final setId = sRow['id'] as String?;
        if (setId == null) continue;

        final segmentsData = segmentsBySet[setId] ?? [];
        // Sort segments in isolate
        segmentsData.sort((a, b) =>
            (a['segment_order'] as int).compareTo(b['segment_order'] as int));

        structuredSets.add({
          'row': sRow,
          'segments': segmentsData,
        });
      }

      structuredExercises.add({
        'row': eRow,
        'sets': structuredSets,
      });
    }

    structuredWorkouts.add({
      'row': wRow,
      'exercises': structuredExercises,
    });
  }

  // 2. Structure Plans
  final structuredPlans = <Map<String, dynamic>>[];
  for (final pRow in plansMap) {
    final planId = pRow['id'] as String?;
    if (planId == null) continue;

    final pExData = planExByPlan[planId] ?? [];
    pExData.sort((a, b) =>
        (a['exercise_order'] as int).compareTo(b['exercise_order'] as int));

    structuredPlans.add({
      'row': pRow,
      'exercises': pExData,
    });
  }

  return {
    'workouts': structuredWorkouts,
    'plans': structuredPlans,
  };
}

/// Internal helper for grouping within isolate
Map<String, List<Map<String, dynamic>>> _groupByInternal(
    List<Map<String, dynamic>> list, String key) {
  final map = <String, List<Map<String, dynamic>>>{};
  for (final item in list) {
    final val = item[key] as String?;
    if (val != null) {
      map.putIfAbsent(val, () => []).add(item);
    }
  }
  return map;
}

/// Raw sheet parsing helper for isolate.
List<Map<String, dynamic>> _parseSheetRaw(Excel excel, String sheetName) {
  if (!excel.tables.keys.contains(sheetName)) return [];

  final sheet = excel.tables[sheetName]!;
  if (sheet.maxRows <= 1) return [];

  final rows = <Map<String, dynamic>>[];
  final headerRow = sheet.rows.first;
  final headers = headerRow.map((e) => e?.value.toString() ?? '').toList();

  for (int i = 1; i < sheet.rows.length; i++) {
    final row = sheet.rows[i];
    final Map<String, dynamic> rowMap = {};

    for (int j = 0; j < headers.length; j++) {
      if (j < row.length) {
        final header = headers[j];
        if (header.isEmpty) continue;

        final cellValue = row[j]?.value;
        if (cellValue == null) {
          rowMap[header] = null;
        } else if (cellValue is TextCellValue) {
          final val = cellValue.value.toString();
          rowMap[header] = (val == 'null' || val.isEmpty) ? null : val;
        } else if (cellValue is IntCellValue) {
          rowMap[header] = cellValue.value;
        } else if (cellValue is DoubleCellValue) {
          rowMap[header] = cellValue.value;
        } else {
          rowMap[header] = cellValue.toString();
        }
      }
    }
    rows.add(rowMap);
  }
  return rows;
}
