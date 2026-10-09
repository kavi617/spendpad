import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense.dart';

class DatabaseService {
  static const String expenseBox = "expenses";
  static Future<void> _pendingWrites = Future<void>.value();
  static int _lastId = 0;

  /// Monotonic within the process, so two quick saves never overwrite one key.
  static String newExpenseId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastId = now > _lastId ? now : _lastId + 1;
    return '$_lastId';
  }

  static Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pendingWrites.then((_) => operation());
    _pendingWrites = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  static Future<Box<Expense>> openExpenseBox() async {
    if (Hive.isBoxOpen(expenseBox)) {
      return Hive.box<Expense>(expenseBox);
    }

    return await Hive.openBox<Expense>(expenseBox);
  }

  static Future<void> addExpense(Expense expense) async {
    await _serialize(() async {
      final box = await openExpenseBox();
      await box.put(expense.id, expense);
    });
  }

  static Future<List<Expense>> getExpenses() async {
    await _pendingWrites;
    final box = await openExpenseBox();

    return box.values.toList();
  }

  static Future<void> deleteExpense(Expense expense) async {
    await _serialize(() async {
      final box = await openExpenseBox();
      await box.delete(expense.id);
    });
  }

  static Future<void> updateExpense(Expense expense) async {
    await addExpense(expense);
  }

  /// Reassigns all matching records as one serialized box write. If Hive
  /// reports a failed batch, put the original records back before surfacing
  /// the error to the caller.
  static Future<void> replaceExpenseCategory(String from, String to) async {
    await _serialize(() async {
      final box = await openExpenseBox();
      final originals = <dynamic, Expense>{};
      final replacements = <dynamic, Expense>{};
      for (final expense in box.values) {
        if (expense.category != from) continue;
        final key = expense.key;
        if (key == null) continue;
        originals[key] = expense;
        replacements[key] = Expense(
          id: expense.id,
          category: to,
          note: expense.note,
          amount: expense.amount,
          date: expense.date,
        );
      }
      if (replacements.isEmpty) return;
      try {
        await box.putAll(replacements);
      } catch (_) {
        await box.putAll(originals);
        rethrow;
      }
    });
  }
}
