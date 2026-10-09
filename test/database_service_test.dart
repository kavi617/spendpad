import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendpad/models/expense.dart';
import 'package:spendpad/services/database_service.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('spendpad-hive-test-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'serialized add, edit, delete, and reopen retain the committed state',
    () async {
      final firstId = DatabaseService.newExpenseId();
      final secondId = DatabaseService.newExpenseId();
      expect(firstId, isNot(secondId));
      final first = Expense(
        id: firstId,
        category: 'Food',
        note: 'Lunch',
        amount: 12.5,
        date: DateTime(2026, 10, 9),
      );
      final second = Expense(
        id: secondId,
        category: 'Travel',
        note: 'Bus',
        amount: 4,
        date: DateTime(2026, 10, 9),
      );

      await Future.wait([
        DatabaseService.addExpense(first),
        DatabaseService.addExpense(second),
      ]);
      await DatabaseService.updateExpense(
        Expense(
          id: first.id,
          category: 'Food',
          note: 'Team lunch',
          amount: 18,
          date: first.date,
        ),
      );
      await DatabaseService.deleteExpense(second);
      await Hive.close();

      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
      final restored = await DatabaseService.getExpenses();
      expect(restored, hasLength(1));
      expect(restored.single.id, first.id);
      expect(restored.single.note, 'Team lunch');
      expect(restored.single.amount, 18);
    },
  );
}
