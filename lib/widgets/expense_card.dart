import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/app_format.dart';
import '../utils/icon_helper.dart';

/// A clean, minimal expense row used on the dashboard and history list.
///
/// Tap to edit. Delete is handled by the parent (swipe-to-dismiss).
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const ExpenseTile({super.key, required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = IconHelper.colorFor(expense.category);
    final hasNote = expense.note.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  IconHelper.iconFor(expense.category),
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNote ? expense.note : expense.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasNote
                          ? '${expense.category} · ${AppFormat.dayMonth(expense.date)}'
                          : AppFormat.dayMonth(expense.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormat.money(expense.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
