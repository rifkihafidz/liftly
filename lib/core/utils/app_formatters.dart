import 'package:intl/intl.dart';

class AppFormatters {
  // Number Formatters
  static final NumberFormat weightFormatter = NumberFormat('#,##0.##', 'pt_BR');
  static final NumberFormat weightFormatterOneDecimal = NumberFormat('#,##0.#', 'pt_BR');
  
  // Date Formatters
  static final DateFormat dateFull = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat timeShort = DateFormat('HH:mm');
  static final DateFormat dateShort = DateFormat('dd MMM yyyy');
  static final DateFormat dateShortSingleDay = DateFormat('d MMM yyyy');
  static final DateFormat dateMonthYear = DateFormat('MMMM yyyy');
  static final DateFormat dateMonthShort = DateFormat('MMM');
  static final DateFormat dateDayMonth = DateFormat('dd MMM');
  static final DateFormat dateMonthDayShort = DateFormat('MMM d');
  static final DateFormat dateTimeShort = DateFormat('dd MMM yyyy, HH:mm');
  
  // Backup Formatters
  static final DateFormat backupTimestamp = DateFormat('yyyyMMdd_HHmmss');
  static final DateFormat legacyBackupTimestamp = DateFormat('ddMMyyyy_HHmmss');
}
