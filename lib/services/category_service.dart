import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../utils/icon_helper.dart';
import 'database_service.dart';

class CategoryService {
  static const String boxName = "categories";

  static Future<Box<Category>> openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<Category>(boxName);
    return await Hive.openBox<Category>(boxName);
  }

  static Future<List<Category>> getCategories() async {
    final box = await openBox();

    await syncWithExpenses(box);

    if (box.isEmpty) {
      await createDefaultCategories();
    }

    final categories = box.values.toList();

    // Keep the app-wide manual icon overrides in sync.
    IconHelper.syncOverrides(categories);

    return categories;
  }

  /// Makes sure every category name referenced by an expense exists in the
  /// categories list.
  ///
  /// Strictly ADDITIVE: it only creates missing entries, never renames or
  /// deletes. So categories from an older install — or from a restored
  /// backup — always reappear in the pickers, even if the categories list
  /// was lost or cleared at some point.
  static Future<void> syncWithExpenses([Box<Category>? categoryBox]) async {
    final box = categoryBox ?? await openBox();
    final expenseBox = await DatabaseService.openExpenseBox();

    final existing = box.values.map((c) => c.name.trim().toLowerCase()).toSet();

    final missing = <String>[];
    for (final expense in expenseBox.values) {
      final name = expense.category.trim();
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (!existing.contains(key)) {
        existing.add(key);
        missing.add(name);
      }
    }

    for (final name in missing) {
      await box.add(
        Category(
          name: name,
          iconCode: IconHelper.iconFor(name).codePoint,
          iconFamily: 'MaterialIcons',
          isDefault: false,
        ),
      );
    }
  }

  static Future<void> addCategory(Category category) async {
    final box = await openBox();
    final normalized = category.name.trim().toLowerCase();
    if (box.values.any(
      (existing) => existing.name.trim().toLowerCase() == normalized,
    )) {
      throw ArgumentError('A category with this name already exists.');
    }
    await box.add(category);
  }

  static Future<void> renameCategory(Category category, String name) async {
    final oldName = category.name;
    final newName = name.trim();
    if (newName.isEmpty) throw ArgumentError('Category name is required.');
    final box = await openBox();
    if (box.values.any(
      (other) =>
          !identical(other, category) &&
          other.name.trim().toLowerCase() == newName.toLowerCase(),
    )) {
      throw ArgumentError('A category with this name already exists.');
    }
    try {
      await DatabaseService.replaceExpenseCategory(oldName, newName);
      category.name = newName;
      await category.save();
    } catch (_) {
      // Keep transaction labels aligned if saving the category record fails.
      category.name = oldName;
      await DatabaseService.replaceExpenseCategory(newName, oldName);
      rethrow;
    }
  }

  static Future<void> deleteCategory(Category category) async {
    final expenseBox = await DatabaseService.openExpenseBox();
    final hasAffected = expenseBox.values.any(
      (e) => e.category == category.name,
    );
    if (hasAffected) {
      final box = await openBox();
      if (!box.values.any((c) => c.name.toLowerCase() == 'other')) {
        await box.add(
          Category(
            name: 'Other',
            iconCode: IconHelper.iconFor('Other').codePoint,
            iconFamily: 'MaterialIcons',
          ),
        );
      }
      await DatabaseService.replaceExpenseCategory(category.name, 'Other');
    }
    try {
      await category.delete();
    } catch (_) {
      if (hasAffected) {
        await DatabaseService.replaceExpenseCategory('Other', category.name);
      }
      rethrow;
    }
  }

  static Future<void> createDefaultCategories() async {
    final box = await openBox();

    final defaults = [
      Category(
        name: "Food",
        iconCode: Icons.restaurant_rounded.codePoint,
        iconFamily: "MaterialIcons",
        isDefault: true,
      ),

      Category(
        name: "Transport",
        iconCode: Icons.directions_car_rounded.codePoint,
        iconFamily: "MaterialIcons",
        isDefault: true,
      ),

      Category(
        name: "Shopping",
        iconCode: Icons.shopping_bag_rounded.codePoint,
        iconFamily: "MaterialIcons",
        isDefault: true,
      ),

      Category(
        name: "Bills",
        iconCode: Icons.receipt_long_rounded.codePoint,
        iconFamily: "MaterialIcons",
        isDefault: true,
      ),

      Category(
        name: "Medical",
        iconCode: Icons.medical_services_rounded.codePoint,
        iconFamily: "MaterialIcons",
        isDefault: true,
      ),
    ];

    await box.addAll(defaults);
  }
}
