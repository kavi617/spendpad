import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/database_service.dart';
import '../utils/app_format.dart';
import '../utils/icon_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note;
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
  }

  Future<void> _loadCategories() async {
    final data = await CategoryService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = data;
      if (_selectedCategory == null && _categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) {
      _showMessage('Please enter an amount');
      return;
    }

    final amount = double.tryParse(raw);
    if (amount == null || !amount.isFinite) {
      _showMessage('Enter a valid amount');
      return;
    }
    if (amount <= 0) {
      _showMessage('Amount must be greater than zero');
      return;
    }
    if (_selectedCategory == null) {
      _showMessage('Please select a category');
      return;
    }

    final expense = Expense(
      id: widget.expense?.id ?? DatabaseService.newExpenseId(),
      category: _selectedCategory!,
      note: _noteController.text.trim(),
      amount: amount,
      date: _selectedDate,
    );

    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await DatabaseService.updateExpense(expense);
      } else {
        await DatabaseService.addExpense(expense);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        'Could not save this expense. Your entry is still here; please try again.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'Add expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            TextField(
              controller: _amountController,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '${AppFormat.symbol} ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Quick dates
            Row(
              children: [
                _quickDateChip('Today', 0),
                const SizedBox(width: 8),
                _quickDateChip('Yesterday', -1),
                const Spacer(),
                Flexible(
                  child: TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _compactDate(_selectedDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category dropdown
            Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (_categories.isEmpty)
              Text(
                'No categories yet — add one from Settings → Manage categories.',
                style: TextStyle(fontSize: 13, color: scheme.error),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: _selectedCategory == null
                      ? const Icon(Icons.category_rounded, size: 20)
                      : Icon(
                          IconHelper.iconFor(_selectedCategory!),
                          size: 20,
                          color: IconHelper.colorFor(_selectedCategory!),
                        ),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem<String>(
                      value: category.name,
                      child: Row(
                        children: [
                          Icon(
                            IconHelper.iconFor(category.name),
                            size: 18,
                            color: IconHelper.colorFor(category.name),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            const SizedBox(height: 20),

            // Note
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Note (optional) — e.g. lunch with team',
                prefixIcon: const Icon(Icons.sticky_note_2_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving
                      ? 'Saving…'
                      : _isEditing
                      ? 'Update expense'
                      : 'Save expense',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year) return AppFormat.dayMonth(d);
    return '${AppFormat.dayMonth(d)} ${d.year % 100}';
  }

  Widget _quickDateChip(String label, int dayOffset) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day + dayOffset);
    final isSelected =
        _selectedDate.year == target.year &&
        _selectedDate.month == target.month &&
        _selectedDate.day == target.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedDate = target),
    );
  }
}
