import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';

class CategoryService {
  static const String boxName = "categories";

  static Future<Box<Category>> openBox() async {
    return await Hive.openBox<Category>(boxName);
  }

  static Future<List<Category>> getCategories() async {
    final box = await openBox();

    if (box.isEmpty) {
      await createDefaultCategories();
    }

    return box.values.toList();
  }

  static Future<void> addCategory(Category category) async {
    final box = await openBox();

    await box.add(category);
  }

  static Future<void> deleteCategory(Category category) async {
    await category.delete();
  }

  static Future<void> createDefaultCategories() async {
    final box = await openBox();

    final defaults = [
      Category(name: "Food", iconCode: Icons.restaurant.codePoint, iconFamily: "material", isDefault: true),

      Category(name: "Transport", iconCode: Icons.directions_car.codePoint, iconFamily: "material", isDefault: true),

      Category(name: "Shopping", iconCode: Icons.shopping_cart.codePoint, iconFamily: "material", isDefault: true),

      Category(name: "Bills", iconCode: Icons.receipt.codePoint, iconFamily: "material", isDefault: true),

      Category(name: "Medical", iconCode: Icons.medical_services.codePoint, iconFamily: "material", isDefault: true),
    ];

    await box.addAll(defaults);
  }
}
