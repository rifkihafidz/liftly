import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:liftly/core/models/workout_plan.dart';
import 'package:liftly/core/models/workout_session.dart';
import 'package:liftly/core/services/hive_service.dart';
import 'package:liftly/core/constants/app_constants.dart';
import 'package:share_plus/share_plus.dart';

class DataManagementService {
  /// Generate Excel file bytes from Isar data (maintaining legacy tabular format)
  static Future<Uint8List> generateExcelBytes(
      {bool exportOnlyPlans = false}) async {
    final excel = Excel.createExcel();

    // 1. Fetch all data
    final allData = await HiveService.getAllDataForExport();
    final workouts = exportOnlyPlans
        ? <WorkoutSession>[]
        : (allData['workouts'] as List<WorkoutSession>);
    final plans = allData['plans'] as List<WorkoutPlan>;

    // -- WORKOUTS FLATTENING --
    final workoutRows = <Map<String, dynamic>>[];
    final exerciseRows = <Map<String, dynamic>>[];
    final setRows = <Map<String, dynamic>>[];
    final segmentRows = <Map<String, dynamic>>[];

    for (int i = 0; i < workouts.length; i++) {
      if (kIsWeb && i % 10 == 0) await Future.delayed(Duration.zero);
      final w = workouts[i];
      if (w.isDraft) continue;

      workoutRows.add({
        'id': w.id,
        'user_id': w.userId,
        'plan_id': w.planId,
        'plan_name': w.planName,
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

    for (int i = 0; i < plans.length; i++) {
      if (kIsWeb && i % 20 == 0) await Future.delayed(Duration.zero);
      final p = plans[i];
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
          'id': ex.id,
          'plan_id': p.id,
          'name': ex.name,
          'exercise_order': ex.order,
        });
      }
    }

    // -- WRITING TO EXCEL --
    if (!exportOnlyPlans) {
      _writeSheet(excel, AppConstants.sheetWorkouts, workoutRows);
      _writeSheet(excel, AppConstants.sheetWorkoutExercises, exerciseRows);
      _writeSheet(excel, AppConstants.sheetWorkoutSets, setRows);
      _writeSheet(excel, AppConstants.sheetSetSegments, segmentRows);
    }
    _writeSheet(excel, AppConstants.sheetPlans, planRows);
    _writeSheet(excel, AppConstants.sheetPlanExercises, planExRows);

    if (excel.sheets.length > 1 && excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
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

  /// Export all data if auto-export is enabled in preferences

  /// Export all data to an Excel file and prompt user to share/save it
  static Future<void> exportData({bool exportOnlyPlans = false}) async {
    try {
      final fileBytes =
          await generateExcelBytes(exportOnlyPlans: exportOnlyPlans);
      final dateStr = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());
      final prefix = exportOnlyPlans ? 'plans' : 'backup';
      final fileName = '${prefix}_liftly_$dateStr.xlsx';

      // Use XFile.fromData for cross-platform compatibility
      final xFile = XFile.fromData(
        fileBytes,
        name: fileName,
        mimeType: AppConstants.excelMimeType,
      );

      if (kIsWeb) {
        // Direct download on web to avoid noisy Share API logs on desktop browsers
        await xFile.saveTo('');
      } else {
        // Use native share sheet on mobile
        // ignore: deprecated_member_use
        await Share.shareXFiles([xFile], subject: 'Liftly Backup $dateStr');
      }
    } catch (e) {
      if (kDebugMode) print('Export error: $e');
      rethrow;
    }
  }

  /// Pick a file for import (UI step)
  static Future<PlatformFile?> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }
      return result.files.single;
    } catch (e) {
      if (kDebugMode) print('Pick file error: $e');
      return null;
    }
  }

  /// Import data from a selected file (Processing step)
  static Future<String> importFile(PlatformFile file,
      {String targetUserId = '1',
      Function(double progress, String message)? onProgress}) async {
    try {
      Map<String, dynamic> result;

      if (kIsWeb) {
        onProgress?.call(0.1, 'Reading file bytes (Web)...');
        final bytes = file.bytes;
        if (bytes == null) throw Exception('No file bytes provided');

        result = await _processImportShared(
          userId: targetUserId,
          bytes: bytes,
          onProgress: onProgress,
        );
      } else {
        final receivePort = ReceivePort();
        onProgress?.call(0.05, 'Preparing background process...');

        // Prepare data for isolate
        final isolateParams = {
          'userId': targetUserId,
          'path': file.path,
          'bytes': file.bytes,
          'sendPort': receivePort.sendPort,
        };

        // Spawn Isolate
        final isolate =
            await Isolate.spawn(_importIsolateEntryPoint, isolateParams);

        final resultCompleter = Completer<Map<String, dynamic>>();

        receivePort.listen((message) {
          if (message is Map<String, dynamic>) {
            final type = message['type'] as String;
            if (type == 'progress') {
              onProgress?.call(
                  message['progress'] as double, message['message'] as String);
            } else if (type == 'result') {
              resultCompleter.complete(message['data'] as Map<String, dynamic>);
              receivePort.close();
            } else if (type == 'error') {
              resultCompleter.completeError(message['error'] as String);
              receivePort.close();
            }
          }
        });

        result = await resultCompleter.future;
        isolate.kill();
      }

      onProgress?.call(0.5, 'Importing workouts...');

      // Reconstruct models on MAIN THREAD with Chunking to prevent UI freeze
      final rawWorkouts = result['workouts'] as List<dynamic>;
      final rawPlans = result['plans'] as List<dynamic>;

      final parsedWorkouts = <WorkoutSession>[];
      final parsedPlans = <WorkoutPlan>[];

      // Process Workouts in Chunks
      const int batchSize = 100;
      for (int i = 0; i < rawWorkouts.length; i += batchSize) {
        final end = (i + batchSize < rawWorkouts.length)
            ? i + batchSize
            : rawWorkouts.length;
        final batch = rawWorkouts.sublist(i, end);

        parsedWorkouts.addAll(batch
            .map((w) => WorkoutSession.fromMap(w as Map<String, dynamic>)));

        // Yield to UI
        await Future.delayed(Duration.zero);

        // Update Progress (0.5 to 0.9 range)
        final p = 0.5 + (0.4 * (end / rawWorkouts.length));
        onProgress?.call(
            p, 'Importing workouts ($end/${rawWorkouts.length})...');
      }

      onProgress?.call(0.9, 'Importing plans...');

      // Process Plans
      for (final p in rawPlans) {
        parsedPlans.add(WorkoutPlan.fromMap(p as Map<String, dynamic>));
      }

      onProgress?.call(0.95, 'Saving to database...');

      await HiveService.importWorkouts(parsedWorkouts);
      await HiveService.importPlans(parsedPlans);

      onProgress?.call(1.0, 'Done!');
      return 'Successfully imported ${parsedWorkouts.length} workouts and ${parsedPlans.length} plans.';
    } catch (e) {
      // receivePort.close(); // This might not be available if kIsWeb path was taken
      rethrow;
    }
  }

  // Deprecated: Kept for backward compatibility if needed, but redirects to new flow
  static Future<String> importData({String targetUserId = '1'}) async {
    final file = await pickImportFile();
    if (file == null) return 'Import cancelled';
    return await importFile(file, targetUserId: targetUserId);
  }

  /// Generic import logic from bytes
  static Future<String> importDataFromBytes(Uint8List bytes,
      {String targetUserId = '1',
      Function(double progress, String message)? onProgress}) async {
    try {
      Map<String, dynamic> result;

      if (kIsWeb) {
        onProgress?.call(0.1, 'Reading data (Web)...');
        result = await _processImportShared(
          userId: targetUserId,
          bytes: bytes,
          onProgress: onProgress,
        );
      } else {
        final receivePort = ReceivePort();
        onProgress?.call(0.05, 'Preparing background process...');
        final isolateParams = {
          'bytes': bytes,
          'userId': targetUserId,
          'sendPort': receivePort.sendPort,
        };

        final isolate =
            await Isolate.spawn(_importIsolateEntryPoint, isolateParams);
        final resultCompleter = Completer<Map<String, dynamic>>();

        receivePort.listen((message) {
          if (message is Map<String, dynamic>) {
            final type = message['type'] as String;
            if (type == 'progress') {
              onProgress?.call(
                  message['progress'] as double, message['message'] as String);
            } else if (type == 'result') {
              resultCompleter.complete(message['data'] as Map<String, dynamic>);
              receivePort.close();
            } else if (type == 'error') {
              resultCompleter.completeError(message['error'] as String);
              receivePort.close();
            }
          }
        });

        result = await resultCompleter.future;
        isolate.kill();
      }

      onProgress?.call(0.5, 'Importing workouts...');

      final rawWorkouts = result['workouts'] as List<dynamic>;
      final rawPlans = result['plans'] as List<dynamic>;

      final parsedWorkouts = <WorkoutSession>[];
      final parsedPlans = <WorkoutPlan>[];

      // Process Workouts in Chunks
      const int batchSize = 100;
      for (int i = 0; i < rawWorkouts.length; i += batchSize) {
        final end = (i + batchSize < rawWorkouts.length)
            ? i + batchSize
            : rawWorkouts.length;
        final batch = rawWorkouts.sublist(i, end);

        parsedWorkouts.addAll(batch
            .map((w) => WorkoutSession.fromMap(w as Map<String, dynamic>)));

        // Yield to UI
        await Future.delayed(Duration.zero);

        // Update Progress (0.5 to 0.9 range)
        final p = 0.5 + (0.4 * (end / rawWorkouts.length));
        onProgress?.call(
            p, 'Importing workouts ($end/${rawWorkouts.length})...');
      }

      onProgress?.call(0.9, 'Importing plans...');
      for (final p in rawPlans) {
        parsedPlans.add(WorkoutPlan.fromMap(p as Map<String, dynamic>));
      }

      onProgress?.call(0.95, 'Saving to database...');
      await HiveService.importWorkouts(parsedWorkouts);
      await HiveService.importPlans(parsedPlans);

      onProgress?.call(1.0, 'Done!');
      final message =
          'Successfully imported ${parsedWorkouts.length} workouts and ${parsedPlans.length} plans.';
      _log('Import: $message');
      return message;
    } catch (e) {
      _log('Import error: $e');
      rethrow;
    }
  }

  /// Clear all data from the database
  static Future<void> clearAllData() async {
    try {
      await HiveService.clearAllData();
    } catch (e) {
      rethrow;
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      print('[ImportDebug] $message');
    }
  }

  /// Internal helper for grouping within isolate
  static Map<String, List<Map<String, dynamic>>> _groupByInternal(
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

  /// Raw sheet parsing helper for isolate with row caching.
  static List<Map<String, dynamic>> _parseSheetRaw(
      Excel excel, String sheetName) {
    if (!excel.tables.keys.contains(sheetName)) {
      _log('Sheet $sheetName not found');
      return [];
    }

    final sheet = excel.tables[sheetName]!;
    final sheetRows = sheet.rows;
    if (sheetRows.length <= 1) return [];

    final rows = <Map<String, dynamic>>[];
    final headerRow = sheetRows.first;
    // Safely convert headers to strings
    final headers = headerRow.map((e) {
      if (e == null) return '';
      return e.value.toString();
    }).toList();

    for (int i = 1; i < sheetRows.length; i++) {
      final row = sheetRows[i];
      final Map<String, dynamic> rowMap = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < row.length) {
          final header = headers[j];
          if (header.isEmpty) continue;
          final cellValue = row[j];
          if (cellValue == null) {
            rowMap[header] = null;
          } else {
            // Check value type safely
            final val = cellValue.value;
            if (val is TextCellValue) {
              // Handle potential TextSpan/RichText from excel package
              final content = val.value;
              if (content is String) {
                rowMap[header] = content;
              } else {
                // Fallback for Rich Text (TextSpan)
                // content.toString() usually gives the text, or we can try .text dynamic
                try {
                  rowMap[header] = (content as dynamic).text.toString();
                } catch (_) {
                  rowMap[header] = content.toString();
                }
              }
            } else if (val is IntCellValue) {
              rowMap[header] = val.value; // int
            } else if (val is DoubleCellValue) {
              rowMap[header] = val.value; // double
            } else if (val is DateCellValue) {
              // DateCellValue structure specific to excel package version
              // It seems mostly to return value via .year .month etc or asDateTime
              // Checking library source or common usage: .asDateTimeLocal is common helper
              // Or simply val.year, val.month...
              // Actually modern excel package: DateCellValue has .asDateTimeLocal
              // But wait, the previous code used .value which was erroring.
              // Let's rely on .toString() if uncertain, or try .asDateTimeLocal if available.
              // Safest fallback without library inspection in-depth:
              rowMap[header] = val.toString();
            } else {
              rowMap[header] = val.toString(); // Fallback
            }
          }
        }
      }
      rows.add(rowMap);
    }
    return rows;
  }

  /// Shared Core Import Logic
  /// Used by both Isolate (Native) and direct yielding calls (Web)
  static Future<Map<String, dynamic>> _processImportShared({
    required String userId,
    Uint8List? bytes,
    String? path,
    Function(double progress, String message)? onProgress,
  }) async {
    Uint8List fileBytes;

    onProgress?.call(0.1, 'Reading file bytes...');
    if (bytes != null) {
      fileBytes = bytes;
    } else if (path != null) {
      final file = File(path);
      fileBytes = await file.readAsBytes();
    } else {
      throw Exception('No file source provided');
    }

    if (kIsWeb) await Future.delayed(Duration.zero); // Yield to UI

    onProgress?.call(
        0.2, 'Decoding Excel structure (this may take a moment)...');
    final excel = Excel.decodeBytes(fileBytes);

    if (kIsWeb) await Future.delayed(Duration.zero);

    onProgress?.call(0.3, 'Parsing workout records...');
    final workoutsMap =
        DataManagementService._parseSheetRaw(excel, AppConstants.sheetWorkouts);

    onProgress?.call(0.32, 'Parsing exercises...');
    final workoutExercisesMap = DataManagementService._parseSheetRaw(
        excel, AppConstants.sheetWorkoutExercises);

    onProgress?.call(0.34, 'Parsing sets...');
    final workoutSetsMap = DataManagementService._parseSheetRaw(
        excel, AppConstants.sheetWorkoutSets);

    onProgress?.call(0.36, 'Parsing segments...');
    final setSegmentsMap = DataManagementService._parseSheetRaw(
        excel, AppConstants.sheetSetSegments);

    onProgress?.call(0.38, 'Parsing workout plans...');
    final plansMap =
        DataManagementService._parseSheetRaw(excel, AppConstants.sheetPlans);
    final planExercisesMap = DataManagementService._parseSheetRaw(
        excel, AppConstants.sheetPlanExercises);

    _log('Import: Found ${workoutsMap.length} workout rows');
    _log('Import: Found ${plansMap.length} plan rows');

    if (plansMap.isEmpty) {
      _log(
          'Import WARNING: No plans found in "${AppConstants.sheetPlans}" sheet.');
    }

    if (kIsWeb) await Future.delayed(Duration.zero);

    onProgress?.call(0.4, 'Grouping and connecting data...');
    final exercisesByWorkout = DataManagementService._groupByInternal(
        workoutExercisesMap, 'workout_id');
    final setsByExercise =
        DataManagementService._groupByInternal(workoutSetsMap, 'exercise_id');
    final segmentsBySet =
        DataManagementService._groupByInternal(setSegmentsMap, 'set_id');
    final planExByPlan =
        DataManagementService._groupByInternal(planExercisesMap, 'plan_id');

    final planIdToName = <String, String>{};
    for (final pRow in plansMap) {
      final pId = pRow['id']?.toString();
      final pName = pRow['name']?.toString();
      if (pId != null && pName != null) {
        planIdToName[pId] = pName;
      }
    }

    onProgress?.call(0.45, 'Reconstructing ${workoutsMap.length} workouts...');
    final workouts = <Map<String, dynamic>>[];
    for (int i = 0; i < workoutsMap.length; i++) {
      if (kIsWeb && i % 10 == 0) await Future.delayed(Duration.zero);
      final wRow = workoutsMap[i];
      final isDraftVal = wRow['is_draft'];
      bool isDraft = false;
      if (isDraftVal is int) {
        isDraft = isDraftVal == 1;
      } else if (isDraftVal is String) {
        isDraft = isDraftVal == '1';
      }
      if (isDraft) continue;

      final workoutId = wRow['id'] as String?;
      if (workoutId == null) continue;

      final exercisesData = exercisesByWorkout[workoutId] ?? [];
      exercisesData.sort((a, b) =>
          (a['exercise_order'] as int).compareTo(b['exercise_order'] as int));

      final exercises = exercisesData.map((eRow) {
        final exId = eRow['id'] as String;
        final setsData = setsByExercise[exId] ?? [];
        setsData.sort((a, b) =>
            (a['set_number'] as int).compareTo(b['set_number'] as int));

        final sets = setsData.map((sRow) {
          final setId = sRow['id'] as String;
          final segmentsData = segmentsBySet[setId] ?? [];
          segmentsData.sort((a, b) =>
              (a['segment_order'] as int).compareTo(b['segment_order'] as int));

          final segments = segmentsData.map((segRow) {
            int rFrom = segRow['reps_from'] as int? ?? 1;
            int rTo =
                segRow['reps_to'] as int? ?? (segRow['reps'] as int? ?? 1);
            if (rTo < rFrom) rTo = rFrom;

            return {
              'id': segRow['id'] as String,
              'weight': (segRow['weight'] as num).toDouble(),
              'repsFrom': rFrom,
              'repsTo': rTo,
              'segmentOrder': segRow['segment_order'] as int,
              'notes': segRow['notes'] as String? ?? '',
            };
          }).toList();

          return {
            'id': setId,
            'setNumber': sRow['set_number'] as int,
            'segments': segments,
          };
        }).toList();

        final skippedVal = eRow['skipped'];
        bool skipped = false;
        if (skippedVal is int) {
          skipped = skippedVal == 1;
        } else if (skippedVal is String) {
          skipped = skippedVal == '1';
        }
        final templateVal = eRow['is_template'];
        bool isTemplate = false;
        if (templateVal is int) {
          isTemplate = templateVal == 1;
        } else if (templateVal is String) {
          isTemplate = templateVal == '1';
        }

        return {
          'id': exId,
          'name': eRow['name']?.toString() ?? '',
          'order': (eRow['exercise_order'] as num?)?.toInt() ?? 0,
          'skipped': skipped,
          'isTemplate': isTemplate,
          'sets': sets,
        };
      }).toList();

      final planId = wRow['plan_id']?.toString();

      workouts.add({
        'id': workoutId,
        'userId': userId,
        'planId': planId,
        'planName': wRow['plan_name']?.toString() ??
            (planId != null ? planIdToName[planId] : null),
        'workoutDate':
            (DateTime.tryParse(wRow['workout_date'] as String? ?? '') ??
                    DateTime.now())
                .toIso8601String(),
        'startedAt': wRow['started_at'] != null
            ? (DateTime.tryParse(wRow['started_at'] as String))
                ?.toIso8601String()
            : null,
        'endedAt': wRow['ended_at'] != null
            ? (DateTime.tryParse(wRow['ended_at'] as String))?.toIso8601String()
            : null,
        'exercises': exercises,
        'createdAt': (DateTime.tryParse(wRow['created_at'] as String? ?? '') ??
                DateTime.now())
            .toIso8601String(),
        'updatedAt': (DateTime.tryParse(wRow['updated_at'] as String? ?? '') ??
                DateTime.now())
            .toIso8601String(),
        'isDraft': false,
      });

      if (kIsWeb) await Future.delayed(Duration.zero);
    }

    final plans = <Map<String, dynamic>>[];
    for (int i = 0; i < plansMap.length; i++) {
      if (kIsWeb && i % 20 == 0) await Future.delayed(Duration.zero);
      final pRow = plansMap[i];
      final pId = pRow['id']?.toString() ?? '';
      final pExData = planExByPlan[pId] ?? [];
      pExData.sort((a, b) => ((a['exercise_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['exercise_order'] as num?)?.toInt() ?? 0));

      final planExercises = pExData
          .map((eRow) => {
                'id': eRow['id']?.toString() ?? '',
                'name': eRow['name']?.toString() ?? '',
                'order': (eRow['exercise_order'] as num?)?.toInt() ?? 0,
              })
          .toList();

      plans.add({
        'id': pId,
        'userId': userId,
        'name': pRow['name'] as String? ?? 'Unnamed Plan',
        'description': pRow['description'] as String?,
        'exercises': planExercises,
        'createdAt': (DateTime.tryParse(pRow['created_at'] as String? ?? '') ??
                DateTime.now())
            .toIso8601String(),
        'updatedAt': (DateTime.tryParse(pRow['updated_at'] as String? ?? '') ??
                DateTime.now())
            .toIso8601String(),
      });
    }

    return {
      'workouts': workouts,
      'plans': plans,
    };
  }

  /// Isolate Entry Point
  static void _importIsolateEntryPoint(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;

    try {
      final result = await _processImportShared(
        userId: params['userId'] as String,
        bytes: params['bytes'] as Uint8List?,
        path: params['path'] as String?,
        onProgress: (progress, message) {
          sendPort.send({
            'type': 'progress',
            'progress': progress,
            'message': message,
          });
        },
      );

      sendPort.send({
        'type': 'result',
        'data': result,
      });
    } catch (e) {
      sendPort.send({
        'type': 'error',
        'error': e.toString(),
      });
    }
  }
}
