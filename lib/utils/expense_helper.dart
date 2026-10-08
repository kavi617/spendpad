import '../models/expense.dart';

/// Pure (no Flutter) aggregation helpers over the expense list.
class ExpenseHelper {
  ExpenseHelper._();

  static double totalOf(List<Expense> expenses) {
    var total = 0.0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static List<Expense> inMonth(List<Expense> expenses, DateTime month) =>
      expenses.where((e) => _sameMonth(e.date, month)).toList();

  static List<Expense> between(
    List<Expense> expenses,
    DateTime start,
    DateTime endInclusive,
  ) {
    final end = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
      23,
      59,
      59,
    );
    final from = DateTime(start.year, start.month, start.day);
    return expenses
        .where((e) => !e.date.isBefore(from) && !e.date.isAfter(end))
        .toList();
  }

  static double totalInMonth(List<Expense> expenses, DateTime month) =>
      totalOf(inMonth(expenses, month));

  static double getTodayTotal(List<Expense> expenses) {
    final now = DateTime.now();
    return totalOf(expenses.where((e) => _sameDay(e.date, now)).toList());
  }

  static double getMonthTotal(List<Expense> expenses) {
    final now = DateTime.now();
    return totalInMonth(expenses, now);
  }

  static int getTotalExpenses(List<Expense> expenses) => expenses.length;

  static double getAverageExpense(List<Expense> expenses) =>
      expenses.isEmpty ? 0 : totalOf(expenses) / expenses.length;

  /// Total for days 1..lastDay of the given month.
  static double totalUpTo(List<Expense> expenses, DateTime month, int lastDay) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month, lastDay, 23, 59, 59);
    return totalOf(between(expenses, start, end));
  }

  static int daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  /// Average spent per day of the given month. For the running month the
  /// average only counts the days elapsed so far.
  static double averagePerDay(List<Expense> monthExpenses, DateTime month) {
    final now = DateTime.now();
    int days;
    if (_sameMonth(month, now)) {
      days = now.day;
    } else {
      days = DateTime(month.year, month.month + 1, 0).day;
    }
    if (days == 0) return 0;
    return totalOf(monthExpenses) / days;
  }

  static Map<String, double> categoryTotals(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// Totals keyed by date-only [DateTime].
  static Map<DateTime, double> totalsByDay(List<Expense> expenses) {
    final map = <DateTime, double>{};
    for (final e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      map[day] = (map[day] ?? 0) + e.amount;
    }
    return map;
  }

  /// Totals for the last [count] months ending this month (oldest first).
  static List<({DateTime month, double total})> monthTotals(
    List<Expense> expenses, {
    int count = 6,
  }) {
    final now = DateTime.now();
    final result = <({DateTime month, double total})>[];
    for (var i = count - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      result.add((month: month, total: totalInMonth(expenses, month)));
    }
    return result;
  }

  /// Percentage change from [previous] to [current], e.g. -18.4 means 18.4%
  /// less spending. Returns null when it can't be computed.
  static double? percentChange(double current, double previous) {
    if (previous <= 0) return null;
    return ((current - previous) / previous) * 100;
  }
}
