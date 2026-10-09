import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/category_service.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Expense> _expenses = [];

  String _searchText = '';
  String _selectedCategory = 'All';
  String _sortOption = 'Newest';
  DateTime? _selectedMonth; // null = all months

  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getExpenses();
    final cats = await CategoryService.getCategories();

    if (!mounted) return;
    setState(() {
      _expenses = data;
      _categories = ['All', ...cats.map((c) => c.name)];
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }
    });
  }

  List<DateTime> get _availableMonths {
    final months = <DateTime>{};
    for (final e in _expenses) {
      months.add(DateTime(e.date.year, e.date.month));
    }
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Expense> get _filtered {
    var result = List<Expense>.from(_expenses);

    if (_selectedMonth != null) {
      result = ExpenseHelper.inMonth(result, _selectedMonth!);
    }

    if (_searchText.trim().isNotEmpty) {
      final q = _searchText.toLowerCase();
      result = result
          .where(
            (e) =>
                e.note.toLowerCase().contains(q) ||
                e.category.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_selectedCategory != 'All') {
      result = result.where((e) => e.category == _selectedCategory).toList();
    }

    switch (_sortOption) {
      case 'Oldest':
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest':
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest':
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        result.sort((a, b) => b.date.compareTo(a.date));
    }

    return result;
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    );
    if (result == true) {
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

  String _monthChipLabel(DateTime month) {
    final now = DateTime.now();
    if (month.year == now.year) return AppFormat.shortMonth(month);
    return '${AppFormat.shortMonth(month)} ${month.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final months = _availableMonths;

    if (_selectedMonth != null && !months.any((m) => m == _selectedMonth)) {
      _selectedMonth = null;
    }

    // Flatten into day-groups: headers + tiles for ListView.builder.
    final entries = <_Entry>[];
    if (filtered.isNotEmpty && _sortOption == 'Newest') {
      final seen = <DateTime>{};
      for (final e in filtered) {
        final day = DateTime(e.date.year, e.date.month, e.date.day);
        if (seen.add(day)) {
          final dayTotal = filtered
              .where(
                (x) =>
                    x.date.year == day.year &&
                    x.date.month == day.month &&
                    x.date.day == day.day,
              )
              .fold<double>(0, (sum, x) => sum + x.amount);
          entries.add(_Entry.header(day, dayTotal));
        }
        entries.add(_Entry.item(e));
      }
    } else {
      for (final e in filtered) {
        entries.add(_Entry.item(e));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search note or category',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
          if (months.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All time'),
                      selected: _selectedMonth == null,
                      onSelected: (_) => setState(() => _selectedMonth = null),
                    ),
                  ),
                  for (final month in months)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_monthChipLabel(month)),
                        selected: _selectedMonth == month,
                        onSelected: (_) =>
                            setState(() => _selectedMonth = month),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortOption,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: ['Newest', 'Oldest', 'Highest', 'Lowest']
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _sortOption = value!),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormat.money(ExpenseHelper.totalOf(filtered)),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? _emptyState(scheme)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.isHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                AppFormat.relativeDay(entry.day!),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                AppFormat.money(entry.dayTotal!),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final expense = entry.expense!;
                      return Dismissible(
                        key: ValueKey('history-${expense.id}'),
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
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        child: ExpenseTile(
                          expense: expense,
                          onTap: () => _editExpense(expense),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing matches your filters',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different month or category',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  _Entry.item(this.expense) : isHeader = false, day = null, dayTotal = null;

  _Entry.header(this.day, this.dayTotal) : isHeader = true, expense = null;

  final bool isHeader;
  final Expense? expense;
  final DateTime? day;
  final double? dayTotal;
}
