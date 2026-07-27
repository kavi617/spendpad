import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIcon(String family, int codePoint) {
    switch (codePoint) {
      case 0xe3af:
        return Icons.restaurant;

      case 0xe531:
        return Icons.directions_car;

      case 0xe59c:
        return Icons.shopping_cart;

      case 0xe8b0:
        return Icons.receipt_long;

      case 0xe3e9:
        return Icons.favorite;

      case 0xe40b:
        return Icons.movie;

      case 0xe539:
        return Icons.flight;

      case 0xe80c:
        return Icons.school;

      case 0xe88a:
        return Icons.home;

      default:
        return Icons.category;
    }
  }

  static const List<Map<String, dynamic>> availableIcons = [
    {"name": "Food", "icon": Icons.restaurant},

    {"name": "Transport", "icon": Icons.directions_car},

    {"name": "Shopping", "icon": Icons.shopping_cart},

    {"name": "Bills", "icon": Icons.receipt_long},

    {"name": "Health", "icon": Icons.favorite},

    {"name": "Entertainment", "icon": Icons.movie},

    {"name": "Travel", "icon": Icons.flight},

    {"name": "Education", "icon": Icons.school},

    {"name": "Home", "icon": Icons.home},

    {"name": "Other", "icon": Icons.more_horiz},
  ];
}
