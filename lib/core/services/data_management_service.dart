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

  /// Export all data to an Excel file and prompt user to share/save it
  static Future<void> exportData() async {
    try {
      final db = SQLiteService.database;
      final excel = Excel.createExcel();

      // Remove default 'Sheet1' if possible, or just ignore it
      // excel.delete('Sheet1'); // Excel package creates default Sheet1

      for (final table in _tables) {
        final data = await db.query(table);
        if (data.isNotEmpty) {
          final sheetObject = excel[table];

          // Add Headers
          final headers = data.first.keys.toList();
          sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

          // Add Rows
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

      // Delete the default sheet if we added others and it's empty/unused
      if (excel.sheets.length > 1 && excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'liftly_backup_$dateStr.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(fileBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Liftly Backup $dateStr');
    } catch (e) {
      if (kDebugMode) {
        print('Export error: $e');
      }
      rethrow;
    }
  }

  /// Import data from an Excel file
  /// Returns a summary message of the operation
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
              // The excel package returns List<Data?> for row
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
                      // Handle cell values (convert back to primitive types expected by DB)
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

                      // Handle nulls string "null" if accidentally exported that way (defensive)
                      if (rowMap[header] == 'null') {
                        rowMap[header] = null;
                      }
                    }
                  }
                }

                if (rowMap.isNotEmpty && rowMap.containsKey('id')) {
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
