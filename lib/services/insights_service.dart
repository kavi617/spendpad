import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';
import '../utils/icon_helper.dart';

enum InsightTone { positive, warning, neutral }

/// A tiny, fully local insights engine.
///
/// Pure Dart statistics over the month's aggregates — no network, no model
/// downloads, no storage footprint. Runs in microseconds.
///
/// Correctness rule: a running month is never compared against a *complete*
/// previous month. Partial months are compared against the same day range of
/// the previous month (month-to-date vs month-to-date).
class LocalInsightsEngine {
  LocalInsightsEngine._();

  static List<Insight> analyze({
    required List<Expense> allExpenses,
    required DateTime month,
    required List<({DateTime month, double total})> trend,
  }) {
    final insights = <Insight>[];
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = ExpenseHelper.daysInMonth(month);
    final daysElapsed = isCurrentMonth ? now.day : daysInMonth;

    final monthExpenses = ExpenseHelper.inMonth(allExpenses, month);
    final monthTotal = ExpenseHelper.totalOf(monthExpenses);
    final prevMonth = DateTime(month.year, month.month - 1);
    final prevFullTotal = ExpenseHelper.totalInMonth(allExpenses, prevMonth);

    // ---------------------------------------------------------------------
    // 1. Month over month — like-for-like period comparison.
    // ---------------------------------------------------------------------
    if (monthTotal > 0) {
      if (isCurrentMonth && daysElapsed <= 1) {
        // Too early in the month for a meaningful comparison.
      } else if (isCurrentMonth) {
        final prevElapsed =
            daysElapsed.clamp(1, ExpenseHelper.daysInMonth(prevMonth));
        final prevSamePeriod = ExpenseHelper.totalUpTo(
          allExpenses,
          prevMonth,
          prevElapsed,
        );
        final delta = ExpenseHelper.percentChange(monthTotal, prevSamePeriod);

        if (delta != null && prevSamePeriod > 0) {
          final periodLabel = 'through ${AppFormat.dayMonth(now)}';
          if (delta <= -5) {
            insights.add(Insight(
              tone: InsightTone.positive,
              icon: Icons.trending_down_rounded,
              title: 'Spending is running low',
              body:
                  'Through ${AppFormat.dayMonth(now)}, you have spent '
                  '${delta.abs().toStringAsFixed(0)}% less than the same '
                  'stretch last month (${AppFormat.money(monthTotal)} vs '
                  '${AppFormat.money(prevSamePeriod)}). Keep it going.',
            ));
          } else if (delta >= 15) {
            insights.add(Insight(
              tone: InsightTone.warning,
              icon: Icons.trending_up_rounded,
              title: 'Spending is running high',
              body:
                  '$periodLabel you are ${delta.toStringAsFixed(0)}% above the '
                  'same days last month. The category list below shows where '
                  'it went.',
            ));
          }
        } else if (prevSamePeriod <= 0) {
          insights.add(Insight(
            tone: InsightTone.neutral,
            icon: Icons.info_outline_rounded,
            title: 'New spending territory',
            body:
                'There was nothing recorded in the first $prevElapsed days of '
                '${AppFormat.shortMonth(prevMonth)}, so there is nothing to '
                'compare with yet. Trends unlock as both months fill in.',
          ));
        }
      } else {
        // Viewing a complete past month — full month vs full month is fair.
        final delta = ExpenseHelper.percentChange(monthTotal, prevFullTotal);
        if (delta != null && prevFullTotal > 0) {
          if (delta <= -5) {
            insights.add(Insight(
              tone: InsightTone.positive,
              icon: Icons.trending_down_rounded,
              title: 'Spending came down',
              body:
                  'You spent ${delta.abs().toStringAsFixed(0)}% less than '
                  '${AppFormat.shortMonth(prevMonth)} '
                  '(${AppFormat.money(monthTotal)} vs '
                  '${AppFormat.money(prevFullTotal)}).',
            ));
          } else if (delta >= 15) {
            insights.add(Insight(
              tone: InsightTone.warning,
              icon: Icons.trending_up_rounded,
              title: 'Spending went up',
              body:
                  '${delta.toStringAsFixed(0)}% more than '
                  '${AppFormat.shortMonth(prevMonth)} — '
                  '${AppFormat.money(monthTotal)} vs '
                  '${AppFormat.money(prevFullTotal)}.',
            ));
          }
        }
      }
    }

    // ---------------------------------------------------------------------
    // 2. End-of-month projection for the running month.
    // ---------------------------------------------------------------------
    if (isCurrentMonth && monthTotal > 0 && daysElapsed >= 2) {
      final projection = monthTotal / daysElapsed * daysInMonth;
      if (prevFullTotal > 0) {
        final over = projection > prevFullTotal;
        final pct = ExpenseHelper.percentChange(projection, prevFullTotal);
        insights.add(Insight(
          tone: over ? InsightTone.warning : InsightTone.positive,
          icon: Icons.online_prediction_rounded,
          title: 'Month-end projection',
          body: over
              ? 'At today\'s pace you are heading for about '
                  '${AppFormat.money(projection)} by month end — roughly '
                  '${pct?.toStringAsFixed(0)}% above '
                  '${AppFormat.shortMonth(prevMonth)}\'s '
                  '${AppFormat.money(prevFullTotal)}.'
              : 'At today\'s pace you will finish around '
                  '${AppFormat.money(projection)} — under '
                  '${AppFormat.shortMonth(prevMonth)}\'s '
                  '${AppFormat.money(prevFullTotal)}. Well paced.',
        ));
      } else {
        insights.add(Insight(
          tone: InsightTone.neutral,
          icon: Icons.online_prediction_rounded,
          title: 'Month-end projection',
          body:
              'At today\'s pace you are heading for about '
              '${AppFormat.money(projection)} this month.',
        ));
      }
    }

    // ---------------------------------------------------------------------
    // 3. Category concentration.
    // ---------------------------------------------------------------------
    final cats = ExpenseHelper.categoryTotals(monthExpenses);
    if (cats.isNotEmpty) {
      final sorted = cats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final share = monthTotal > 0 ? top.value / monthTotal : 0.0;
      if (share >= 0.45 && sorted.length > 1) {
        insights.add(Insight(
          tone: InsightTone.warning,
          icon: IconHelper.iconFor(top.key),
          title: '${top.key} dominates this month',
          body:
              'It took ${(share * 100).toStringAsFixed(0)}% of your spending '
              '(${AppFormat.money(top.value)}). Trimming it would move the '
              'needle fastest.',
        ));
      } else if (sorted.length >= 3 && share < 0.45) {
        insights.add(Insight(
          tone: InsightTone.positive,
          icon: Icons.donut_small_rounded,
          title: 'Nicely balanced',
          body:
              'Spending is spread across ${sorted.length} categories with '
              '${top.key} leading at ${(share * 100).toStringAsFixed(0)}%.',
        ));
      }
    }

    // ---------------------------------------------------------------------
    // 4. Biggest single expense.
    // ---------------------------------------------------------------------
    if (monthExpenses.isNotEmpty) {
      Expense biggest = monthExpenses.first;
      for (final e in monthExpenses) {
        if (e.amount > biggest.amount) biggest = e;
      }
      final share = monthTotal > 0 ? biggest.amount / monthTotal : 0.0;
      if (share >= 0.2) {
        insights.add(Insight(
          tone: InsightTone.neutral,
          icon: Icons.filter_center_focus_rounded,
          title: 'One big ticket',
          body:
              'A single ${biggest.category} expense of '
              '${AppFormat.money(biggest.amount)} was '
              '${(share * 100).toStringAsFixed(0)}% of the month'
              '${biggest.note.trim().isEmpty ? '.' : ' — “${biggest.note.trim()}”.'}',
        ));
      }
    }

    // ---------------------------------------------------------------------
    // 5. Small frequent spends ("leaky taps").
    // ---------------------------------------------------------------------
    if (monthExpenses.length >= 5) {
      final amounts = monthExpenses.map((e) => e.amount).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      final smalls = monthExpenses.where((e) => e.amount <= median).length;
      final smallSum = monthExpenses
          .where((e) => e.amount <= median)
          .fold<double>(0, (s, e) => s + e.amount);
      if (smalls >= 4 && smallSum > 0) {
        insights.add(Insight(
          tone: InsightTone.neutral,
          icon: Icons.water_drop_rounded,
          title: 'Small spends add up',
          body:
              '$smalls small expenses quietly added up to '
              '${AppFormat.money(smallSum)}. They are the easiest place to '
              'save without feeling it.',
        ));
      }
    }

    // ---------------------------------------------------------------------
    // 6. Weekend vs weekday rhythm.
    // ---------------------------------------------------------------------
    if (monthExpenses.length >= 8) {
      final byDay = ExpenseHelper.totalsByDay(monthExpenses);
      double weekend = 0, weekday = 0;
      var weekendDays = 0, weekdayDays = 0;
      byDay.forEach((day, total) {
        final isWeekend = day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday;
        if (isWeekend) {
          weekend += total;
          weekendDays++;
        } else {
          weekday += total;
          weekdayDays++;
        }
      });
      if (weekendDays > 0 && weekdayDays > 0 && weekday > 0) {
        final wkndAvg = weekend / weekendDays;
        final wdAvg = weekday / weekdayDays;
        final diff = ExpenseHelper.percentChange(wkndAvg, wdAvg);
        if (diff != null && diff >= 25) {
          insights.add(Insight(
            tone: InsightTone.neutral,
            icon: Icons.weekend_rounded,
            title: 'Weekends cost more',
            body:
                'Your weekend days average ${AppFormat.money(wkndAvg)} vs '
                '${AppFormat.money(wdAvg)} on weekdays — about '
                '${diff.toStringAsFixed(0)}% higher.',
          ));
        }
      }
    }

    // ---------------------------------------------------------------------
    // 7. Vs recent average — only for complete months, otherwise it would
    //    compare a slice against full months.
    // ---------------------------------------------------------------------
    if (!isCurrentMonth && trend.length >= 4) {
      final past = trend
          .where((t) => t.month.isBefore(month))
          .map((t) => t.total)
          .toList();
      if (past.length >= 3) {
        final avg = past.fold<double>(0, (s, v) => s + v) / past.length;
        if (avg > 0) {
          final diff = ExpenseHelper.percentChange(monthTotal, avg);
          if (diff != null && diff <= -10) {
            insights.add(Insight(
              tone: InsightTone.positive,
              icon: Icons.verified_rounded,
              title: 'Below your usual',
              body:
                  'This month is ${diff.abs().toStringAsFixed(0)}% under your '
                  'recent average of ${AppFormat.money(avg)}.',
            ));
          } else if (diff != null && diff >= 25) {
            insights.add(Insight(
              tone: InsightTone.warning,
              icon: Icons.timeline_rounded,
              title: 'Above your usual',
              body:
                  'This month is ${diff.toStringAsFixed(0)}% above your '
                  'recent average of ${AppFormat.money(avg)}.',
            ));
          }
        }
      }
    }

    // ---------------------------------------------------------------------
    // 8. Tracking habit nudge.
    // ---------------------------------------------------------------------
    if (monthExpenses.length >= 4) {
      final noNote = monthExpenses.where((e) => e.note.trim().isEmpty).length;
      if (noNote / monthExpenses.length >= 0.4) {
        insights.add(Insight(
          tone: InsightTone.neutral,
          icon: Icons.sticky_note_2_rounded,
          title: 'Add notes, get sharper insights',
          body:
              '$noNote of ${monthExpenses.length} expenses have no note. '
              'A word or two makes your history searchable and reports '
              'smarter.',
        ));
      }
    }

    // Order: warnings first, then positives, then neutrals. Cap at 5.
    int rank(InsightTone t) =>
        t == InsightTone.warning ? 0 : (t == InsightTone.positive ? 1 : 2);
    insights.sort((a, b) => rank(a.tone).compareTo(rank(b.tone)));
    return insights.take(5).toList();
  }
}

class Insight {
  const Insight({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
  });

  final InsightTone tone;
  final IconData icon;
  final String title;
  final String body;

  Color get color {
    switch (tone) {
      case InsightTone.positive:
        return const Color(0xFF2E9E4F);
      case InsightTone.warning:
        return const Color(0xFFF08C26);
      case InsightTone.neutral:
        return const Color(0xFF2E77D0);
    }
  }
}
