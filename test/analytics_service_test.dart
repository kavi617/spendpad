import 'package:flutter_test/flutter_test.dart';
import 'package:spendpad/models/expense.dart';
import 'package:spendpad/services/analytics_service.dart';

Expense expense(String id, double amount, DateTime date, String category) =>
    Expense(id: id, amount: amount, date: date, category: category, note: '');

void main() {
  final today = DateTime(2026, 10, 9);

  test('week summary compares equal elapsed periods and fills zero days', () {
    final result = AnalyticsSnapshot.calculate(
      [
        expense('a', 100, DateTime(2026, 10, 9), 'Food'),
        expense('b', 50, DateTime(2026, 10, 7), 'Bills'),
        expense('c', 40, DateTime(2026, 10, 2), 'Food'),
      ],
      AnalyticsPeriod.week,
      today: today,
    );

    expect(result.start, DateTime(2026, 10, 5));
    expect(result.end, today);
    expect(result.total, 150);
    expect(result.previousStart, DateTime(2026, 9, 28));
    expect(result.previousEnd, DateTime(2026, 10, 2));
    expect(result.previousTotal, 40);
    expect(result.changePercent, 275);
    expect(result.averagePerDay, 30);
    expect(result.series, hasLength(5));
    expect(result.series[1].amount, 0);
    expect(result.categoryTotals, {'Food': 100, 'Bills': 50});
  });

  test('month and long periods aggregate true records into chart buckets', () {
    final expenses = [
      expense('a', 25, DateTime(2026, 10, 1), 'Food'),
      expense('b', 75, DateTime(2026, 10, 9), ''),
    ];
    final month = AnalyticsSnapshot.calculate(
      expenses,
      AnalyticsPeriod.month,
      today: today,
    );
    expect(month.total, 100);
    expect(month.series, hasLength(9));
    expect(month.categoryTotals['Uncategorized'], 75);

    final year = AnalyticsSnapshot.calculate(
      expenses,
      AnalyticsPeriod.year,
      today: today,
    );
    expect(year.series, hasLength(10));
    expect(year.series.last.amount, 100);
  });

  test(
    'comparison stays unavailable when the previous period has no spend',
    () {
      final result = AnalyticsSnapshot.calculate(
        [expense('a', 18, DateTime(2026, 10, 9), 'Food')],
        AnalyticsPeriod.month,
        today: today,
      );
      expect(result.changePercent, isNull);
      expect(result.previousTotal, 0);
      expect(result.largest?.amount, 18);
    },
  );

  test('calendar periods compare equivalent weekdays and dates', () {
    final records = [
      expense('current', 120, DateTime(2026, 10, 9), 'Food'),
      expense('month-before', 30, DateTime(2026, 9, 9), 'Food'),
      expense('month-outside', 900, DateTime(2026, 9, 10), 'Food'),
      expense('three-month-before', 40, DateTime(2026, 7, 9), 'Food'),
      expense('year-before', 50, DateTime(2025, 10, 9), 'Food'),
    ];

    final month = AnalyticsSnapshot.calculate(
      records,
      AnalyticsPeriod.month,
      today: today,
    );
    expect(month.previousStart, DateTime(2026, 9, 1));
    expect(month.previousEnd, DateTime(2026, 9, 9));
    expect(month.previousTotal, 30);

    final threeMonths = AnalyticsSnapshot.calculate(
      records,
      AnalyticsPeriod.threeMonths,
      today: today,
    );
    expect(threeMonths.previousStart, DateTime(2026, 5, 1));
    expect(threeMonths.previousEnd, DateTime(2026, 7, 9));
    expect(threeMonths.previousTotal, 40);

    final year = AnalyticsSnapshot.calculate(
      records,
      AnalyticsPeriod.year,
      today: today,
    );
    expect(year.previousStart, DateTime(2025, 1, 1));
    expect(year.previousEnd, DateTime(2025, 10, 9));
    expect(year.previousTotal, 50);
  });

  test('completed calendar windows compare with the complete prior window', () {
    final completedMonth = AnalyticsSnapshot.calculate(
      const [],
      AnalyticsPeriod.month,
      today: DateTime(2026, 9, 30),
    );
    expect(completedMonth.previousStart, DateTime(2026, 8, 1));
    expect(completedMonth.previousEnd, DateTime(2026, 8, 31));

    final completedThreeMonths = AnalyticsSnapshot.calculate(
      const [],
      AnalyticsPeriod.threeMonths,
      today: DateTime(2026, 7, 31),
    );
    expect(completedThreeMonths.start, DateTime(2026, 5, 1));
    expect(completedThreeMonths.previousStart, DateTime(2026, 2, 1));
    expect(completedThreeMonths.previousEnd, DateTime(2026, 4, 30));

    final completedYear = AnalyticsSnapshot.calculate(
      const [],
      AnalyticsPeriod.year,
      today: DateTime(2025, 12, 31),
    );
    expect(completedYear.previousStart, DateTime(2024, 1, 1));
    expect(completedYear.previousEnd, DateTime(2024, 12, 31));
  });
}
