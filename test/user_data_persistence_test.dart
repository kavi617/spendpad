import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendpad/models/category.dart';
import 'package:spendpad/models/expense.dart';
import 'package:spendpad/services/category_service.dart';
import 'package:spendpad/services/database_service.dart';
import 'package:spendpad/services/settings_service.dart';
import 'package:spendpad/utils/icon_helper.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('spendpad-user-data-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'categories, renamed transaction labels, and preferences survive reopen',
    () async {
      await CategoryService.getCategories();
      final category = Category(
        name: 'Coffee',
        iconCode: IconHelper.iconFor('Coffee').codePoint,
        iconFamily: 'MaterialIcons',
      );
      await CategoryService.addCategory(category);
      await DatabaseService.addExpense(
        Expense(
          id: DatabaseService.newExpenseId(),
          category: 'Coffee',
          note: 'Cafe',
          amount: 6,
          date: DateTime(2026, 10, 9),
        ),
      );

      await CategoryService.renameCategory(category, 'Cafe');
      expect((await DatabaseService.getExpenses()).single.category, 'Cafe');
      await SettingsService.setValue('currency', '€');

      await Hive.close();
      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());

      expect((await DatabaseService.getExpenses()).single.category, 'Cafe');
      expect(
        (await CategoryService.getCategories()).any((c) => c.name == 'Cafe'),
        isTrue,
      );
      expect((await SettingsService.openBox()).get('currency'), '€');

      final restoredCategory = (await CategoryService.getCategories())
          .singleWhere((c) => c.name == 'Cafe');
      await CategoryService.deleteCategory(restoredCategory);
      expect((await DatabaseService.getExpenses()).single.category, 'Other');
      expect(
        (await CategoryService.getCategories()).any((c) => c.name == 'Other'),
        isTrue,
      );
    },
  );
}
