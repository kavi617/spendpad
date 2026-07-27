import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';

class DatabaseService {
  static const String expenseBox = "expenses";

  static Future<Box<Expense>> openExpenseBox() async {
    if (Hive.isBoxOpen(expenseBox)) {
      return Hive.box<Expense>(expenseBox);
    }

    return await Hive.openBox<Expense>(expenseBox);
  }

  static Future<void> addExpense(Expense expense) async {
    final box = await openExpenseBox();

    await box.put(expense.id, expense);
  }

  static Future<List<Expense>> getExpenses() async {
    final box = await openExpenseBox();

    return box.values.toList();
  }

  static Future<void> deleteExpense(Expense expense) async {
    final box = await openExpenseBox();

    await box.delete(expense.id);
  }

  static Future<void> updateExpense(Expense expense) async {
    final box = await openExpenseBox();

    await box.put(expense.id, expense);
  }
}
