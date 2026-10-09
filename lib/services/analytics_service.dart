import '../models/expense.dart';

enum AnalyticsPeriod { week, month, threeMonths, year }

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
    required this.expenses,
    required this.previousExpenses,
    required this.series,
    required this.categoryTotals,
  });

  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;
  final List<Expense> expenses;
  final List<Expense> previousExpenses;
  final List<({String label, DateTime date, double amount})> series;
  final Map<String, double> categoryTotals;

  double get total => expenses.fold(0, (sum, item) => sum + item.amount);
  double get previousTotal =>
      previousExpenses.fold(0, (sum, item) => sum + item.amount);
  double get averagePerDay => total / (end.difference(start).inDays + 1);
  Expense? get largest => expenses.isEmpty
      ? null
      : (expenses.toList()..sort((a, b) => b.amount.compareTo(a.amount))).first;
  double? get changePercent => previousTotal <= 0
      ? null
      : ((total - previousTotal) / previousTotal) * 100;

  static AnalyticsSnapshot calculate(
    List<Expense> all,
    AnalyticsPeriod period, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    late final DateTime start;
    switch (period) {
      case AnalyticsPeriod.week:
        start = date.subtract(Duration(days: date.weekday - DateTime.monday));
      case AnalyticsPeriod.month:
        start = DateTime(date.year, date.month);
      case AnalyticsPeriod.threeMonths:
        start = DateTime(date.year, date.month - 2);
      case AnalyticsPeriod.year:
        start = DateTime(date.year);
    }
    late final DateTime previousStart;
    late final DateTime previousEnd;
    switch (period) {
      case AnalyticsPeriod.week:
        previousStart = start.subtract(const Duration(days: 7));
        previousEnd = date.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        previousStart = DateTime(date.year, date.month - 1);
        previousEnd = date.day == DateTime(date.year, date.month + 1, 0).day
            ? DateTime(date.year, date.month, 0)
            : _shiftMonths(date, -1);
      case AnalyticsPeriod.threeMonths:
        previousStart = DateTime(start.year, start.month - 3);
        previousEnd = date.day == DateTime(date.year, date.month + 1, 0).day
            ? DateTime(start.year, start.month, 0)
            : _shiftMonths(date, -3);
      case AnalyticsPeriod.year:
        previousStart = DateTime(date.year - 1);
        previousEnd = date.month == 12 && date.day == 31
            ? DateTime(date.year - 1, 12, 31)
            : _shiftMonths(date, -12);
    }
    final current = all.where((e) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      return !day.isBefore(start) && !day.isAfter(date);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    final previous = all.where((e) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      return !day.isBefore(previousStart) && !day.isAfter(previousEnd);
    }).toList();
    final categoryTotals = <String, double>{};
    for (final expense in current) {
      final category = expense.category.trim().isEmpty
          ? 'Uncategorized'
          : expense.category;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + expense.amount;
    }
    final series = _series(current, start, date, period);
    return AnalyticsSnapshot(
      start: start,
      end: date,
      previousStart: previousStart,
      previousEnd: previousEnd,
      expenses: current,
      previousExpenses: previous,
      series: series,
      categoryTotals: categoryTotals,
    );
  }

  static List<({String label, DateTime date, double amount})> _series(
    List<Expense> expenses,
    DateTime start,
    DateTime end,
    AnalyticsPeriod period,
  ) {
    final weeklyOrMore =
        period == AnalyticsPeriod.threeMonths || period == AnalyticsPeriod.year;
    final buckets = <DateTime, double>{};
    if (weeklyOrMore && period == AnalyticsPeriod.threeMonths) {
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 7))) {
        buckets[d] = 0;
      }
      for (final expense in expenses) {
        final day = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        final index = day.difference(start).inDays ~/ 7;
        final key = start.add(Duration(days: index * 7));
        buckets[key] = (buckets[key] ?? 0) + expense.amount;
      }
      return buckets.entries
          .map(
            (entry) => (
              label: '${entry.key.day} ${_month(entry.key.month)}',
              date: entry.key,
              amount: entry.value,
            ),
          )
          .toList();
    }
    if (period == AnalyticsPeriod.year) {
      for (
        var month = DateTime(start.year, start.month);
        !month.isAfter(end);
        month = DateTime(month.year, month.month + 1)
      ) {
        buckets[month] = 0;
      }
      for (final expense in expenses) {
        final key = DateTime(expense.date.year, expense.date.month);
        buckets[key] = (buckets[key] ?? 0) + expense.amount;
      }
      return buckets.entries
          .map(
            (entry) => (
              label: _month(entry.key.month),
              date: entry.key,
              amount: entry.value,
            ),
          )
          .toList();
    }
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      buckets[d] = 0;
    }
    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      buckets[day] = (buckets[day] ?? 0) + expense.amount;
    }
    return buckets.entries
        .map(
          (entry) =>
              (label: '${entry.key.day}', date: entry.key, amount: entry.value),
        )
        .toList();
  }

  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  static DateTime _shiftMonths(DateTime date, int monthDelta) {
    final firstOfTarget = DateTime(date.year, date.month + monthDelta);
    final lastDay = DateTime(
      firstOfTarget.year,
      firstOfTarget.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfTarget.year,
      firstOfTarget.month,
      date.day.clamp(1, lastDay),
    );
  }
}
