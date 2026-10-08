import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/database_service.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';
import '../widgets/animations.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onSeeAll;

  const HomePage({super.key, this.onSeeAll});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _all = [];
  List<Expense> _recent = [];

  double _monthTotal = 0;
  double _todayTotal = 0;
  double _avgPerDay = 0;
  int _monthCount = 0;
  double? _monthDelta; // % vs the same days of the previous month
  String _prevMonthLabel = '';
  String _topCategory = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getExpenses();
    await CategoryService.getCategories(); // refreshes manual icon overrides
    data.sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final monthExpenses = ExpenseHelper.inMonth(data, now);

    // Fair comparison: month-to-date vs the SAME days of the previous month.
    final prevMonth = DateTime(now.year, now.month - 1);
    final prevElapsed = now.day.clamp(1, ExpenseHelper.daysInMonth(prevMonth));
    final prevSamePeriod = ExpenseHelper.totalUpTo(data, prevMonth, prevElapsed);

    var topCategory = '';
    var topAmount = 0.0;
    ExpenseHelper.categoryTotals(monthExpenses).forEach((name, value) {
      if (value > topAmount) {
        topAmount = value;
        topCategory = name;
      }
    });

    if (!mounted) return;
    setState(() {
      _all = data;
      _recent = data.take(8).toList();
      _monthTotal = ExpenseHelper.totalOf(monthExpenses);
      _todayTotal = ExpenseHelper.getTodayTotal(data);
      _avgPerDay = ExpenseHelper.averagePerDay(monthExpenses, now);
      _monthCount = monthExpenses.length;
      _monthDelta = ExpenseHelper.percentChange(_monthTotal, prevSamePeriod);
      _prevMonthLabel = AppFormat.shortMonth(prevMonth);
      _topCategory = topCategory;
      _loading = false;
    });
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result is Expense) {
      await DatabaseService.addExpense(result);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Expense saved')));
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    );
    if (result is Expense) {
      await DatabaseService.updateExpense(result);
      await _load();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    await DatabaseService.deleteExpense(expense);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Expense deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseService.addExpense(expense);
              await _load();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 12),
            Text(
              AppFormat.greeting(),
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'SpendPad',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            StaggerIn(index: 0, child: _monthCard(scheme)),
            const SizedBox(height: 12),
            StaggerIn(index: 1, child: _statsRow(scheme)),
            const SizedBox(height: 24),
            StaggerIn(
              index: 2,
              child: _sectionHeader(
                title: 'Recent activity',
                actionLabel: _all.length > _recent.length ? 'View all' : null,
                onAction: widget.onSeeAll,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recent.isEmpty)
              StaggerIn(index: 3, child: _emptyState(scheme))
            else
              ...[
                for (var i = 0; i < _recent.length; i++)
                  StaggerIn(
                    index: 3 + i,
                    child: _dismissibleTile(_recent[i]),
                  ),
              ],
            if (_all.length > _recent.length) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: widget.onSeeAll,
                  child: Text('View all ${_all.length} transactions'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthCard(ColorScheme scheme) {
    final delta = _monthDelta;
    final tooEarly = DateTime.now().day <= 1;
    final deltaText = (delta == null || tooEarly)
        ? null
        : '${delta <= 0 ? '↓' : '↑'} ${delta.abs().toStringAsFixed(0)}% vs $_prevMonthLabel so far';
    final deltaColor = delta != null && delta > 0 ? scheme.error : scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT THIS MONTH',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormat.money(_monthTotal),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
              letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.today_rounded,
                  size: 15, color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                '${AppFormat.money(_todayTotal)} today',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.insights_rounded,
                  size: 15, color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                '${AppFormat.money(_avgPerDay)}/day avg',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: deltaText == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(deltaText),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      deltaText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: deltaColor),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            scheme,
            icon: Icons.receipt_rounded,
            label: 'Transactions',
            value: '$_monthCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            scheme,
            icon: Icons.star_rounded,
            label: 'Top category',
            value: _topCategory.isEmpty ? '—' : _topCategory,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }

  Widget _dismissibleTile(Expense expense) {
    return Dismissible(
      key: ValueKey('home-${expense.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteExpense(expense),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5533C),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: ExpenseTile(expense: expense, onTap: () => _editExpense(expense)),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.savings_rounded,
              size: 44,
              color: scheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'No expenses yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap “Add” to record your first expense.\nSmall habits, big clarity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
