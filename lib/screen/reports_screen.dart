import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/analytics_service.dart';
import '../services/category_service.dart';
import '../services/database_service.dart';
import '../utils/app_format.dart';
import '../utils/icon_helper.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Expense> _all = [];
  bool _loading = true;
  String? _error;
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DatabaseService.getExpenses();
      await CategoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your spending data could not be loaded. Please try again.';
      });
    }
  }

  AnalyticsSnapshot get _data =>
      AnalyticsSnapshot.calculate(_all, _period, today: _anchor);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _canGoBack =>
      _all.isNotEmpty &&
      _data.start.isAfter(
        _all
            .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
            .reduce((a, b) => a.isBefore(b) ? a : b),
      );
  bool get _canGoForward => _anchor.isBefore(_today);

  void _shiftPeriod(int direction) {
    final current = _data;
    DateTime next;
    if (direction < 0) {
      next = switch (_period) {
        AnalyticsPeriod.week => current.start.subtract(const Duration(days: 1)),
        AnalyticsPeriod.month => DateTime(
          current.start.year,
          current.start.month,
          0,
        ),
        AnalyticsPeriod.threeMonths => current.start.subtract(
          const Duration(days: 1),
        ),
        AnalyticsPeriod.year => DateTime(current.start.year - 1, 12, 31),
      };
    } else {
      next = switch (_period) {
        AnalyticsPeriod.week => _anchor.add(const Duration(days: 7)),
        AnalyticsPeriod.month => _addMonths(_anchor, 1),
        AnalyticsPeriod.threeMonths => _addMonths(_anchor, 3),
        AnalyticsPeriod.year => DateTime(
          _anchor.year + 1,
          _anchor.month,
          _anchor.day,
        ),
      };
      if (next.isAfter(_today)) next = _today;
    }
    setState(() => _anchor = next);
  }

  DateTime _addMonths(DateTime date, int count) {
    final first = DateTime(date.year, date.month + count);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, date.day.clamp(1, lastDay));
  }

  String _rangeLabel(AnalyticsSnapshot data) =>
      '${AppFormat.dayMonth(data.start)} – ${AppFormat.dayMonth(data.end)}';

  Future<void> _showCategoryTransactions(String category) async {
    final data = _data;
    final items =
        data.expenses
            .where(
              (e) =>
                  (e.category.trim().isEmpty ? 'Uncategorized' : e.category) ==
                  category,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.68,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      IconHelper.iconFor(category),
                      color: IconHelper.colorFor(category),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      AppFormat.money(
                        items.fold(0.0, (sum, e) => sum + e.amount),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ExpenseTile(
                      expense: item,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _editExpense(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editExpense(Expense expense) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    );
    if (edited == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _messageState(scheme, _error!, Icons.sync_problem_rounded, _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                children: [
                  _periodSelector(scheme),
                  const SizedBox(height: 10),
                  Text(
                    _rangeLabel(_data),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_all.isEmpty)
                    _messageState(
                      scheme,
                      'Add a few expenses to see your spending patterns here.',
                      Icons.insights_rounded,
                      null,
                    )
                  else ...[
                    _overview(scheme),
                    const SizedBox(height: 24),
                    _sectionTitle('Spending over time'),
                    const SizedBox(height: 10),
                    _chartCard(scheme),
                    const SizedBox(height: 24),
                    _sectionTitle('By category'),
                    const SizedBox(height: 10),
                    _categoryCard(scheme),
                    const SizedBox(height: 24),
                    _sectionTitle('Spending insights'),
                    const SizedBox(height: 10),
                    _insightsCard(scheme),
                    const SizedBox(height: 24),
                    _sectionTitle('Largest expenses'),
                    const SizedBox(height: 10),
                    _transactionsCard(scheme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _periodSelector(ColorScheme scheme) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous ${_periodLabel()}',
          onPressed: _canGoBack ? () => _shiftPeriod(-1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        for (final period in AnalyticsPeriod.values)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(switch (period) {
                AnalyticsPeriod.week => 'Week',
                AnalyticsPeriod.month => 'Month',
                AnalyticsPeriod.threeMonths => '3 months',
                AnalyticsPeriod.year => 'Year',
              }),
              selected: period == _period,
              onSelected: (_) => setState(() {
                _period = period;
                _anchor = _today;
              }),
              showCheckmark: false,
            ),
          ),
        IconButton(
          tooltip: 'Next ${_periodLabel()}',
          onPressed: _canGoForward ? () => _shiftPeriod(1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );

  Widget _overview(ColorScheme scheme) {
    final data = _data;
    final change = data.changePercent;
    final largest = data.largest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total spending',
                style: TextStyle(
                  color: scheme.onPrimaryContainer.withValues(alpha: .8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                AppFormat.money(data.total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    change == null
                        ? Icons.remove_rounded
                        : change <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      change == null
                          ? 'No previous-period spending to compare'
                          : '${change.abs().toStringAsFixed(1)}% ${change < 0 ? 'less' : 'more'} than previous period',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                scheme,
                'Daily average',
                AppFormat.money(data.averagePerDay),
                Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                scheme,
                'Transactions',
                '${data.expenses.length}',
                Icons.receipt_long_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _metricCard(
          scheme,
          'Largest expense',
          largest == null ? '—' : AppFormat.money(largest.amount),
          Icons.arrow_upward_rounded,
          subtitle: largest == null
              ? null
              : '${largest.category} · ${AppFormat.dayMonth(largest.date)}',
        ),
      ],
    );
  }

  Widget _metricCard(
    ColorScheme scheme,
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _chartCard(ColorScheme scheme) {
    final values = _data.series;
    final max = values.fold<double>(
      0,
      (m, point) => point.amount > m ? point.amount : m,
    );
    if (max == 0) return _emptyCard(scheme, 'No spending in this period yet.');
    final interval = max / 4;
    final step = (values.length / 5).ceil().clamp(1, values.length);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total ${AppFormat.money(_data.total)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: LineChart(
                  key: ValueKey(_period),
                  LineChartData(
                    minY: 0,
                    maxY: max == 0 ? 1 : max * 1.15,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval > 0 ? interval : 1,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: scheme.outlineVariant.withValues(alpha: .5),
                        strokeWidth: .7,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          interval: interval > 0 ? interval : 1,
                          getTitlesWidget: (value, _) => Text(
                            AppFormat.moneyCompact(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: step.toDouble(),
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= values.length) {
                              return const SizedBox.shrink();
                            }
                            final point = values[i];
                            final label =
                                _period == AnalyticsPeriod.year ||
                                    _period == AnalyticsPeriod.threeMonths
                                ? point.label
                                : (i == 0 ||
                                          i == values.length - 1 ||
                                          i % step == 0
                                      ? point.label
                                      : '');
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((spot) {
                          final point = values[spot.x.toInt()];
                          return LineTooltipItem(
                            '${point.label}\n${AppFormat.money(point.amount)}',
                            TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < values.length; i++)
                            FlSpot(i.toDouble(), values[i].amount),
                        ],
                        isCurved: values.length > 2,
                        curveSmoothness: .18,
                        color: scheme.primary,
                        barWidth: 2.5,
                        dotData: FlDotData(show: values.length <= 14),
                        belowBarData: BarAreaData(
                          show: true,
                          color: scheme.primary.withValues(alpha: .10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(ColorScheme scheme) {
    final data = _data;
    if (data.categoryTotals.isEmpty) {
      return _emptyCard(scheme, 'No spending in this period yet.');
    }
    final entries = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _categoryRow(
                scheme,
                entries[i].key,
                entries[i].value,
                data.total,
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap a category to see its transactions',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(
    ColorScheme scheme,
    String name,
    double total,
    double overall,
  ) {
    final color = IconHelper.colorFor(name);
    final pct = overall <= 0 ? 0.0 : (total / overall).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label:
          '$name, ${AppFormat.money(total)}, ${(pct * 100).round()} percent. Show transactions.',
      child: InkWell(
        onTap: () => _showCategoryTransactions(name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(IconHelper.iconFor(name), color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        color: color,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppFormat.money(total),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _insightsCard(ColorScheme scheme) {
    final data = _data;
    final topCategory = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final change = data.changePercent;
    final insights = <(IconData, String)>[];
    if (topCategory.isNotEmpty) {
      insights.add((
        Icons.pie_chart_outline_rounded,
        '${topCategory.first.key} is your largest category at ${AppFormat.money(topCategory.first.value)} (${(topCategory.first.value / data.total * 100).toStringAsFixed(1)}%).',
      ));
    }
    if (data.largest case final largest?) {
      insights.add((
        Icons.receipt_long_rounded,
        'Your largest purchase was ${AppFormat.money(largest.amount)} for ${largest.category} on ${AppFormat.dayMonth(largest.date)}.',
      ));
    }
    final previousByCategory = <String, double>{};
    for (final expense in data.previousExpenses) {
      final name = expense.category.trim().isEmpty
          ? 'Uncategorized'
          : expense.category;
      previousByCategory[name] =
          (previousByCategory[name] ?? 0) + expense.amount;
    }
    final increased =
        data.categoryTotals.entries
            .where(
              (entry) =>
                  previousByCategory[entry.key] != null &&
                  entry.value > previousByCategory[entry.key]!,
            )
            .toList()
          ..sort(
            (a, b) => (b.value - previousByCategory[b.key]!).compareTo(
              a.value - previousByCategory[a.key]!,
            ),
          );
    if (increased.isNotEmpty) {
      final item = increased.first;
      final before = previousByCategory[item.key]!;
      final delta = (item.value - before) / before * 100;
      insights.add((
        Icons.swap_vert_rounded,
        '${item.key} spending increased ${delta.toStringAsFixed(1)}% (${AppFormat.money(before)} to ${AppFormat.money(item.value)}) compared with the previous period.',
      ));
    }
    if (change != null) {
      insights.add((
        change <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        'Spending is ${change.abs().toStringAsFixed(1)}% ${change < 0 ? 'lower' : 'higher'} than the previous ${_periodLabel()} (${AppFormat.money(data.previousTotal)}).',
      ));
    } else {
      insights.add((
        Icons.history_rounded,
        'A previous-period comparison will appear after you have activity in both periods.',
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < insights.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 20,
                  color: scheme.outlineVariant.withValues(alpha: .5),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(insights[i].$1, color: scheme.primary, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insights[i].$2,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _periodLabel() => switch (_period) {
    AnalyticsPeriod.week => 'week',
    AnalyticsPeriod.month => 'month',
    AnalyticsPeriod.threeMonths => 'three months',
    AnalyticsPeriod.year => 'year',
  };

  Widget _transactionsCard(ColorScheme scheme) {
    final items = _data.expenses.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (items.isEmpty) {
      return _emptyCard(scheme, 'No transactions in this period yet.');
    }
    return Card(
      child: Column(
        children: [
          for (final expense in items.take(5))
            ExpenseTile(expense: expense, onTap: () => _editExpense(expense)),
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing 5 of ${items.length} transactions',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard(ColorScheme scheme, String text) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    ),
  );

  Widget _messageState(
    ColorScheme scheme,
    String message,
    IconData icon,
    VoidCallback? retry,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (retry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: retry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}
