import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'sqlite_service.dart';

class DataManagementService {
  static const List<String> _tables = [
    'workouts',
    'workout_exercises',
    'workout_sets',
    'set_segments',
    'plans',
    'plan_exercises',
  ];

  /// Generate Excel file bytes from database data
  static Future<Uint8List> generateExcelBytes() async {
    final db = SQLiteService.database;
    final excel = Excel.createExcel();

    for (final table in _tables) {
      List<Map<String, dynamic>> data;

      if (table == 'workouts') {
        data = await db.query(table, where: 'is_draft = 0');
      } else if (table == 'workout_exercises') {
        data = await db.rawQuery(
          'SELECT * FROM workout_exercises WHERE workout_id IN (SELECT id FROM workouts WHERE is_draft = 0)',
        );
      } else if (table == 'workout_sets') {
        data = await db.rawQuery(
          'SELECT * FROM workout_sets WHERE exercise_id IN (SELECT id FROM workout_exercises WHERE workout_id IN (SELECT id FROM workouts WHERE is_draft = 0))',
        );
      } else if (table == 'set_segments') {
        data = await db.rawQuery(
          'SELECT * FROM set_segments WHERE set_id IN (SELECT id FROM workout_sets WHERE exercise_id IN (SELECT id FROM workout_exercises WHERE workout_id IN (SELECT id FROM workouts WHERE is_draft = 0)))',
        );
      } else {
        data = await db.query(table);
      }

      if (data.isNotEmpty) {
        final sheetObject = excel[table];
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
    }

    if (excel.sheets.length > 1 && excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');
    return Uint8List.fromList(bytes);
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
  static Future<String> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return 'Import cancelled';
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      return await importDataFromBytes(bytes);
    } catch (e) {
      rethrow;
    }
  }

  /// Generic import logic from bytes
  static Future<String> importDataFromBytes(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final db = SQLiteService.database;

      int importedTables = 0;
      int importedRows = 0;

      await db.transaction((txn) async {
        for (final table in _tables) {
          if (excel.tables.keys.contains(table)) {
            final sheet = excel.tables[table]!;
            if (sheet.maxRows > 1) {
              // Header + at least 1 row
              importedTables++;

              // Get headers from first row
              final headerRow = sheet.rows.first;
              final headers = headerRow
                  .map((e) => e?.value.toString() ?? '')
                  .toList();

              // Process content rows
              for (int i = 1; i < sheet.rows.length; i++) {
                final row = sheet.rows[i];
                final Map<String, dynamic> rowMap = {};

                for (int j = 0; j < headers.length; j++) {
                  if (j < row.length) {
                    final header = headers[j];
                    if (header.isNotEmpty) {
                      final cellValue = row[j]?.value;
                      if (cellValue is TextCellValue) {
                        final val = cellValue.value.toString();
                        rowMap[header] = val.isEmpty ? null : val;
                      } else if (cellValue is IntCellValue) {
                        rowMap[header] = cellValue.value;
                      } else if (cellValue is DoubleCellValue) {
                        rowMap[header] = cellValue.value;
                      } else {
                        rowMap[header] = cellValue.toString();
                      }

                      if (rowMap[header] == 'null') {
                        rowMap[header] = null;
                      }
                    }
                  }
                }

                if (rowMap.isNotEmpty && rowMap.containsKey('id')) {
                  if (table == 'workouts' &&
                      (rowMap['is_draft'] == 1 || rowMap['is_draft'] == '1')) {
                    continue;
                  }

                  await txn.insert(
                    table,
                    rowMap,
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                  importedRows++;
                }
              }
            }
          }
        }
      });

      return 'Successfully imported $importedRows records from $importedTables tables.';
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
      final db = SQLiteService.database;
      await db.transaction((txn) async {
        for (final table in _tables) {
          await txn.delete(table);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Clear data error: $e');
      }
      rethrow;
    }
  }
}
