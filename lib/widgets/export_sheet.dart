import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';

enum ExportPeriod { thisMonth, lastMonth, last3Months, thisYear, allTime, custom }

class ExportSheet extends StatefulWidget {
  const ExportSheet({super.key});

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  List<Expense> _all = [];
  ExportPeriod _period = ExportPeriod.thisMonth;
  ExportFormat _format = ExportFormat.csv;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getExpenses();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  (DateTime, DateTime) _rangeFor(ExportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ExportPeriod.thisMonth:
        return (DateTime(now.year, now.month), now);
      case ExportPeriod.lastMonth:
        final m = DateTime(now.year, now.month - 1);
        return (m, DateTime(m.year, m.month + 1, 0));
      case ExportPeriod.last3Months:
        final m = DateTime(now.year, now.month - 2);
        return (DateTime(m.year, m.month), now);
      case ExportPeriod.thisYear:
        return (DateTime(now.year, 1), now);
      case ExportPeriod.allTime:
        return (DateTime(2000), now);
      case ExportPeriod.custom:
        return (
          _customStart ?? DateTime(now.year, now.month),
          _customEnd ?? now,
        );
    }
  }

  String get _label {
    switch (_period) {
      case ExportPeriod.thisMonth:
        return 'This month';
      case ExportPeriod.lastMonth:
        return 'Last month';
      case ExportPeriod.last3Months:
        return 'Last 3 months';
      case ExportPeriod.thisYear:
        return 'This year';
      case ExportPeriod.allTime:
        return 'All time';
      case ExportPeriod.custom:
        if (_customStart == null || _customEnd == null) return 'Custom range';
        return '${AppFormat.dayMonth(_customStart!)} – ${AppFormat.fullDate(_customEnd!)}';
    }
  }

  List<Expense> get _filtered {
    final (start, end) = _rangeFor(_period);
    return ExpenseHelper.between(_all, start, end);
  }

  Future<void> _pickCustomDates() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart ?? DateTime(now.year, now.month),
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Start date',
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? now,
      firstDate: start,
      lastDate: now,
      helpText: 'End date',
    );
    if (end == null || !mounted) return;
    setState(() {
      _customStart = start;
      _customEnd = end;
      _period = ExportPeriod.custom;
    });
  }

  Future<void> _export() async {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export in this period')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await BackupService.exportExpenses(filtered, _format);
    navigator.pop();
    final formatName = switch (_format) {
      ExportFormat.csv => 'CSV',
      ExportFormat.xlsx => 'Excel',
      ExportFormat.json => 'JSON',
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text('Exported ${filtered.length} transactions as $formatName'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _loading ? <Expense>[] : _filtered;
    final total = ExpenseHelper.totalOf(filtered);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Export expenses',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Pick a period and a file format',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),

            // File format
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(
                    value: ExportFormat.csv,
                    icon: Icon(Icons.table_view_rounded, size: 18),
                    label: Text('CSV'),
                  ),
                  ButtonSegment(
                    value: ExportFormat.xlsx,
                    icon: Icon(Icons.grid_on_rounded, size: 18),
                    label: Text('Excel'),
                  ),
                  ButtonSegment(
                    value: ExportFormat.json,
                    icon: Icon(Icons.data_object_rounded, size: 18),
                    label: Text('JSON'),
                  ),
                ],
                selected: {_format},
                onSelectionChanged: (selection) =>
                    setState(() => _format = selection.first),
              ),
            ),
            const SizedBox(height: 14),

            // Period options
            RadioGroup<ExportPeriod>(
              groupValue: _period,
              onChanged: (value) {
                if (value == ExportPeriod.custom) {
                  _pickCustomDates();
                } else if (value != null) {
                  setState(() => _period = value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._options,
                  InkWell(
                    onTap: _pickCustomDates,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Radio<ExportPeriod>(
                            value: ExportPeriod.custom,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.date_range_rounded, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _label == 'Custom range'
                                  ? 'Custom range — tap to pick'
                                  : _label,
                              style: const TextStyle(fontSize: 14.5),
                            ),
                          ),
                          if (_period == ExportPeriod.custom)
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Color(0xFF2E9E4F),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppFormat.money(total),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _loading || filtered.isEmpty ? null : _export,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _options {
    Widget option(ExportPeriod period, String label, IconData icon) {
      return InkWell(
        onTap: () => setState(() => _period = period),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Radio<ExportPeriod>(value: period),
              const SizedBox(width: 6),
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14.5)),
            ],
          ),
        ),
      );
    }

    return [
      option(ExportPeriod.thisMonth, 'This month', Icons.calendar_today_rounded),
      option(ExportPeriod.lastMonth, 'Last month', Icons.calendar_month_rounded),
      option(ExportPeriod.last3Months, 'Last 3 months', Icons.view_timeline_rounded),
      option(ExportPeriod.thisYear, 'This year', Icons.event_rounded),
      option(ExportPeriod.allTime, 'All time', Icons.all_inclusive_rounded),
    ];
  }
}
