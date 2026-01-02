enum TimePeriod {
  week('This Week', 'W'),
  month('This Month', 'M'),
  year('This Year', 'A');

  final String label;
  final String shortCode;

  const TimePeriod(this.label, this.shortCode);
}

class StatsFilter {
  final TimePeriod timePeriod;
  final DateTime referenceDate;

  StatsFilter({
    required this.timePeriod,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();

  /// Get start date based on time period
  DateTime getStartDate() {
    final now = referenceDate;
    switch (timePeriod) {
      case TimePeriod.week:
        // Monday of the week (weekday 1 = Monday, 7 = Sunday)
        final dayOfWeek = now.weekday;
        final startDate = now.subtract(Duration(days: dayOfWeek - 1));
        return DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      case TimePeriod.month:
        return DateTime(now.year, now.month, 1);
      case TimePeriod.year:
        return DateTime(now.year, 1, 1);
    }
  }

  /// Get end date based on time period
  DateTime getEndDate() {
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
    }
  }

  /// Check if a date falls within the period
  bool isInPeriod(DateTime date) {
    return date.isAfter(getStartDate()) && date.isBefore(getEndDate());
  }
}
