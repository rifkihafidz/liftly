enum TimePeriod {
  week('This Week'),
  month('This Month'),
  year('This Year'),
  allTime('All Time');

  final String label;

  const TimePeriod(this.label);
}

class StatsFilter {
  final TimePeriod timePeriod;
  final DateTime referenceDate;

  StatsFilter({required this.timePeriod, DateTime? referenceDate})
      : referenceDate = referenceDate ?? DateTime.now();

  /// Get start date based on time period
  DateTime? getStartDate() {
    final now = referenceDate;
    switch (timePeriod) {
      case TimePeriod.week:
        // Monday of the week (weekday 1 = Monday, 7 = Sunday)
        final dayOfWeek = now.weekday;
        final startDate = now.subtract(Duration(days: dayOfWeek - 1));
        return DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
      case TimePeriod.month:
        return DateTime(now.year, now.month, 1);
      case TimePeriod.year:
        return DateTime(now.year, 1, 1);
      case TimePeriod.allTime:
        return null; // No start date
    }
  }

  /// Get end date based on time period
  DateTime? getEndDate() {
    final now = referenceDate;
    switch (timePeriod) {
      case TimePeriod.week:
        // Sunday of the week (weekday 1 = Monday, 7 = Sunday)
        // Days until Sunday = (7 - weekday)
        final dayOfWeek = now.weekday;
        final endDate = now.add(Duration(days: 7 - dayOfWeek));
        return DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      case TimePeriod.month:
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case TimePeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case TimePeriod.allTime:
        return null; // No end date
    }
  }

  /// Check if a date falls within the period
  bool isInPeriod(DateTime date) {
    if (timePeriod == TimePeriod.allTime) return true;

    final start = getStartDate();
    final end = getEndDate();

    if (start == null || end == null) return true;

    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }
}
