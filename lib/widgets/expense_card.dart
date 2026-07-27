import 'package:flutter/material.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  final VoidCallback onDelete;

  final VoidCallback onEdit;

  const ExpenseCard({super.key, required this.expense, required this.onDelete, required this.onEdit});

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return Icons.restaurant;

      case "travel":
      case "transport":
        return Icons.directions_car;

      case "shopping":
        return Icons.shopping_cart;

      case "bills":
        return Icons.receipt_long;

      case "medical":
      case "health":
        return Icons.medical_services;

      case "entertainment":
        return Icons.movie;

      default:
        return Icons.category;
    }
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case "food":
        return Colors.orange;

      case "travel":
      case "transport":
        return Colors.blue;

      case "shopping":
        return Colors.purple;

      case "bills":
        return Colors.red;

      case "medical":
      case "health":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,

      margin: const EdgeInsets.symmetric(vertical: 6),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            Container(
              width: 50,

              height: 50,

              decoration: BoxDecoration(
                color: getCategoryColor(expense.category).withOpacity(0.15),

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(getCategoryIcon(expense.category), color: getCategoryColor(expense.category), size: 28),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(expense.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  if (expense.note.isNotEmpty)
                    Text(
                      expense.note,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),

                  const SizedBox(height: 4),

                  Text(formatDate(expense.date), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text(
                  "\$${expense.amount.toStringAsFixed(2)}",

                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),

                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),

                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
