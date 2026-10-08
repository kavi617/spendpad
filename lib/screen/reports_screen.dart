import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/database_service.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';
import '../utils/icon_helper.dart';
import '../widgets/animations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Expense> _all = [];
  bool _loading = true;
  bool _chartsReady = false;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getExpenses();
    await CategoryService.getCategories(); // refreshes manual icon overrides
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
      if (data.isNotEmpty) {
        final earliest = data
            .map((e) => DateTime(e.date.year, e.date.month))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final nowMonth = DateTime(DateTime.now().year, DateTime.now().month);
        if (_month.isBefore(earliest)) _month = earliest;
        if (_month.isAfter(nowMonth)) _month = nowMonth;
      }
    });

    // Let the first frame paint with zeroed charts, then animate in.
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _chartsReady = true);
  }

  DateTime get _earliestMonth {
    if (_all.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - 5);
    }
    return _all
        .map((e) => DateTime(e.date.year, e.date.month))
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get _latestMonth => DateTime(DateTime.now().year, DateTime.now().month);

  bool get _canGoForward => _month.isBefore(_latestMonth);
  bool get _canGoBack => _month.isAfter(_earliestMonth);

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isBefore(_earliestMonth) || next.isAfter(_latestMonth)) return;
    setState(() => _month = next);
  }

  // ---------------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------------

  List<Expense> get _monthExpenses => ExpenseHelper.inMonth(_all, _month);

  double get _monthTotal => ExpenseHelper.totalOf(_monthExpenses);

  double get _prevMonthTotal =>
      ExpenseHelper.totalInMonth(_all, DateTime(_month.year, _month.month - 1));

  List<({DateTime month, double total})> get _trend =>
      ExpenseHelper.monthTotals(_all, count: 6);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  /// Fourth summary card.
  /// Running month -> pace-based end-of-month projection (changes with every
  /// expense). Completed month -> the single biggest spending day.
  String _fourthCardLabel() {
    if (_isCurrentMonth) return 'Projected total';
    final peak = _peakDay;
    return peak == null
        ? 'Peak day'
        : 'Peak day · ${AppFormat.dayMonth(peak.key)}';
  }

  Widget _fourthCardValue(ColorScheme scheme) {
    if (_isCurrentMonth) {
      final elapsed = DateTime.now().day;
      final daysInMonth = ExpenseHelper.daysInMonth(_month);
      final projection = elapsed > 0 ? _monthTotal / elapsed * daysInMonth : 0.0;
      final delta = ExpenseHelper.percentChange(projection, _prevMonthTotal);
      final color = _prevMonthTotal <= 0 || delta == null
          ? scheme.onSurface
          : (delta <= 0 ? const Color(0xFF2E9E4F) : const Color(0xFFE5533C));
      return Text(
        AppFormat.money(projection),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    final peak = _peakDay;
    return Text(
      peak == null ? '—' : AppFormat.money(peak.value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  /// The single biggest spending day of the selected month.
  MapEntry<DateTime, double>? get _peakDay {
    final byDay = ExpenseHelper.totalsByDay(_monthExpenses);
    if (byDay.isEmpty) return null;
    MapEntry<DateTime, double> peak = byDay.entries.first;
    for (final e in byDay.entries) {
      if (e.value > peak.value) peak = e;
    }
    return peak;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                _monthNavigator(scheme),
                const SizedBox(height: 20),
                if (_all.isEmpty)
                  _allEmptyState(scheme)
                else ...[
                  _summaryGrid(scheme),
                  const SizedBox(height: 24),
                  _sectionTitle('Where it went'),
                  const SizedBox(height: 10),
                  StaggerIn(index: 1, child: _categoryCard(scheme)),
                  const SizedBox(height: 24),
                  _sectionTitle('Top expenses'),
                  const SizedBox(height: 10),
                  StaggerIn(index: 2, child: _topExpensesCard(scheme)),
                  const SizedBox(height: 24),
                  _sectionTitle('Daily spending'),
                  const SizedBox(height: 10),
                  StaggerIn(index: 3, child: _dailyChartCard(scheme)),
                  const SizedBox(height: 24),
                  _sectionTitle('Spending by weekday'),
                  const SizedBox(height: 10),
                  StaggerIn(index: 4, child: _weekdayCard(scheme)),
                  const SizedBox(height: 24),
                  _sectionTitle('Last 6 months'),
                  const SizedBox(height: 10),
                  StaggerIn(index: 5, child: _trendCard(scheme)),
                ],
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      );

  // ---------------------------------------------------------------------------
  // Month navigator
  // ---------------------------------------------------------------------------

  Widget _monthNavigator(ColorScheme scheme) {
    final count = _monthExpenses.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  AppFormat.monthYear(_month),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count transaction${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _canGoForward ? () => _shiftMonth(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary grid
  // ---------------------------------------------------------------------------

  Widget _summaryGrid(ColorScheme scheme) {
    return Column(
      children: [
        StaggerIn(
          index: 0,
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  scheme,
                  label: _isCurrentMonth ? 'Spent so far' : 'Total spent',
                  valueWidget: Text(
                    AppFormat.money(_monthTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  scheme,
                  label: 'Avg per day',
                  valueWidget: Text(
                    AppFormat.money(
                      ExpenseHelper.averagePerDay(_monthExpenses, _month),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  icon: Icons.calendar_view_day_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StaggerIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  scheme,
                  label: 'Transactions',
                  valueWidget: Text(
                    '${_monthExpenses.length}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  icon: Icons.receipt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  scheme,
                  label: _fourthCardLabel(),
                  valueWidget: _fourthCardValue(scheme),
                  icon: _isCurrentMonth
                      ? Icons.online_prediction_rounded
                      : Icons.local_fire_department_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    ColorScheme scheme, {
    required String label,
    required Widget valueWidget,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            valueWidget,
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top expenses
  // ---------------------------------------------------------------------------

  Widget _topExpensesCard(ColorScheme scheme) {
    if (_monthExpenses.isEmpty) {
      return _noDataCard(scheme, 'No spending recorded this month.');
    }

    final top = [..._monthExpenses]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final shown = top.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: IconHelper.colorFor(shown[i].category)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconHelper.iconFor(shown[i].category),
                        size: 19,
                        color: IconHelper.colorFor(shown[i].category),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shown[i].note.trim().isEmpty
                                ? shown[i].category
                                : shown[i].note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${shown[i].category} · ${AppFormat.dayMonth(shown[i].date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormat.money(shown[i].amount),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            if (top.length > shown.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${top.length - shown.length} more expenses this month',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Spending by weekday
  // ---------------------------------------------------------------------------

  Widget _weekdayCard(ColorScheme scheme) {
    final byDay = ExpenseHelper.totalsByDay(_monthExpenses);
    if (byDay.isEmpty) {
      return _noDataCard(scheme, 'No spending recorded this month.');
    }

    final daysInMonth = ExpenseHelper.daysInMonth(_month);
    final totals = List<double>.filled(7, 0);
    final occurrences = List<int>.filled(7, 0);
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      final weekday = date.weekday - 1; // Monday = 0
      occurrences[weekday]++;
      totals[weekday] += byDay[date] ?? 0;
    }
    final avgs = [
      for (var i = 0; i < 7; i++)
        occurrences[i] > 0 ? totals[i] / occurrences[i] : 0.0,
    ];
    final maxAvg = avgs.reduce((a, b) => a > b ? a : b);
    if (maxAvg <= 0) {
      return _noDataCard(scheme, 'No spending recorded this month.');
    }

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fullNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final busiest = avgs.indexOf(maxAvg);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              maxY: maxAvg * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index > 6) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: index == busiest
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: index == busiest
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${fullNames[group.x.clamp(0, 6)]}\n'
                    '${AppFormat.money(rod.toY)} avg',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < 7; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _chartsReady ? avgs[i] : 0,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: i == busiest
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category donut + legend
  // ---------------------------------------------------------------------------

  Widget _categoryCard(ColorScheme scheme) {
    final cats = ExpenseHelper.categoryTotals(_monthExpenses).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (cats.isEmpty) {
      return _noDataCard(scheme, 'No spending recorded this month.');
    }

    final top = cats.take(6).toList();
    final othersTotal = cats.skip(6).fold<double>(0, (s, e) => s + e.value);
    final entries = [
      ...top.map((e) => MapEntry(e.key, e.value)),
      if (othersTotal > 0) const MapEntry('Others', 0.0),
    ];
    if (othersTotal > 0) {
      entries[entries.length - 1] = MapEntry('Others', othersTotal);
    }

    // Like-for-like previous period for per-category deltas.
    final now = DateTime.now();
    final prevMonth = DateTime(_month.year, _month.month - 1);
    final List<Expense> prevPeriodExpenses;
    if (_month.year == now.year && _month.month == now.month) {
      final elapsed = now.day.clamp(1, ExpenseHelper.daysInMonth(prevMonth));
      prevPeriodExpenses = ExpenseHelper.between(
        _all,
        prevMonth,
        DateTime(prevMonth.year, prevMonth.month, elapsed),
      );
    } else {
      prevPeriodExpenses = ExpenseHelper.inMonth(_all, prevMonth);
    }
    final prevCats = ExpenseHelper.categoryTotals(prevPeriodExpenses);

    final sections = <PieChartSectionData>[];
    for (final e in entries) {
      sections.add(
        PieChartSectionData(
          value: e.value,
          color: e.key == 'Others'
              ? scheme.outlineVariant
              : IconHelper.colorFor(e.key),
          radius: _chartsReady ? 26 : 0,
          showTitle: false,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: _chartsReady ? 62 : 0,
                      sectionsSpace: 2,
                    ),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormat.moneyCompact(_monthTotal),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'total',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...entries.map((e) {
              final color = e.key == 'Others'
                  ? scheme.outlineVariant
                  : IconHelper.colorFor(e.key);
              final pct =
                  _monthTotal > 0 ? (e.value / _monthTotal * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: e.key == 'Others'
                          ? Icon(Icons.more_horiz_rounded,
                              size: 16, color: color)
                          : Icon(IconHelper.iconFor(e.key),
                              size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (prevCats.isNotEmpty && e.key != 'Others')
                            Text(
                              _categoryDeltaLabel(e.value, prevCats[e.key]),
                              style: TextStyle(
                                fontSize: 11,
                                color: _categoryDeltaColor(
                                  e.value,
                                  prevCats[e.key],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppFormat.money(e.value),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _categoryDeltaLabel(double current, double? previous) {
    if (previous == null || previous <= 0) return 'new this month';
    final delta = ExpenseHelper.percentChange(current, previous);
    if (delta == null) return 'same as last month';
    if (delta >= 1) return '↑ ${delta.toStringAsFixed(0)}% vs last month';
    if (delta <= -1) return '↓ ${delta.abs().toStringAsFixed(0)}% vs last month';
    return 'same as last month';
  }

  Color _categoryDeltaColor(double current, double? previous) {
    if (previous == null || previous <= 0) return const Color(0xFF5C7080);
    final delta = ExpenseHelper.percentChange(current, previous);
    if (delta == null || (delta > -1 && delta < 1)) {
      return const Color(0xFF5C7080);
    }
    return delta > 0 ? const Color(0xFFE5533C) : const Color(0xFF2E9E4F);
  }

  // ---------------------------------------------------------------------------
  // Charts
  // ---------------------------------------------------------------------------

  Widget _dailyChartCard(ColorScheme scheme) {
    final byDay = ExpenseHelper.totalsByDay(_monthExpenses);
    if (byDay.isEmpty) {
      return _noDataCard(scheme, 'No spending recorded this month.');
    }

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final maxDaily = byDay.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxDaily * 1.15,
              alignment: BarChartAlignment.spaceBetween,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${AppFormat.dayMonth(DateTime(_month.year, _month.month, group.x + 1))}\n'
                    '${AppFormat.money(rod.toY)}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final day = value.toInt() + 1;
                      if (day == 1 || day % 5 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var day = 1; day <= daysInMonth; day++)
                  BarChartGroupData(
                    x: day - 1,
                    barRods: [
                      BarChartRodData(
                        toY: _chartsReady
                            ? (byDay[DateTime(_month.year, _month.month, day)] ?? 0)
                            : 0,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: scheme.primary.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  Widget _trendCard(ColorScheme scheme) {
    final trend = _trend;
    final maxTotal = trend
        .map((t) => t.total)
        .reduce((a, b) => a > b ? a : b);
    if (maxTotal <= 0) {
      return _noDataCard(scheme, 'Trend appears once you have a few months of data.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxTotal * 1.15,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    AppFormat.moneyCompact(rod.toY),
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AppFormat.shortMonth(trend[index].month),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                trend[index].month == _month
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                            color: trend[index].month == _month
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < trend.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _chartsReady ? trend[i].total : 0,
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                        color: trend[i].month == _month
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty states
  // ---------------------------------------------------------------------------

  Widget _noDataCard(ColorScheme scheme, String message) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _allEmptyState(ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 46,
              color: scheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            const Text(
              'Insights appear as you track',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Record a few expenses and this page will fill with charts, patterns and smart summaries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
