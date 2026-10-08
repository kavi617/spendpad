import 'package:flutter/material.dart';

import '../models/category.dart';

/// Automatically assigns an icon and color to a category based on its name.
///
/// Matching is keyword based ("petrol", "cab", "coffee", ...) and falls back to
/// a stable hash so every category always gets the same, distinct look —
/// without touching anything stored in the database.
class IconHelper {
  IconHelper._();

  // Distinct, muted palette used across lists, chips and charts.
  static const List<Color> palette = [
    Color(0xFFE5533C), // red
    Color(0xFFF08C26), // orange
    Color(0xFFC7A008), // amber
    Color(0xFF2E9E4F), // green
    Color(0xFF12A594), // teal
    Color(0xFF2E77D0), // blue
    Color(0xFF6A5ACD), // purple
    Color(0xFFD6409F), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF5C7080), // blue grey
    Color(0xFF7CB342), // light green
    Color(0xFF00A3BF), // cyan
  ];

  // Ordered rules — most specific keywords first so e.g. "petrol" wins over
  // "pet", "coffee" wins over "fee", "haircut" never hits "air".
  static const List<(List<String>, IconData, int)> _rules = [
    (['electricity', 'lightbill', 'light bill', 'power', 'current bill', 'ups', 'inverter'], Icons.bolt_rounded, 2),
    (['water', 'plumb'], Icons.water_drop_rounded, 5),
    (['wifi', 'internet', 'broadband', 'fiber'], Icons.wifi_rounded, 6),
    (['mobile', 'phone', 'recharge', 'postpaid', 'prepaid', 'airtel', 'jio', 'sim'], Icons.phone_iphone_rounded, 6),
    (['netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'ott', 'subscription', 'membership'], Icons.subscriptions_rounded, 7),
    (['petrol', 'diesel', 'fuel', 'cng', 'gas station', 'charging', 'cylinder', 'lpg', 'gas booking'], Icons.local_gas_station_rounded, 0),
    (['cab', 'taxi', 'uber', 'ola', 'auto fare', 'rickshaw', 'ride'], Icons.local_taxi_rounded, 5),
    (['bus', 'train', 'metro', 'tram', 'commute', 'conveyance', 'transport', 'fare'], Icons.directions_bus_rounded, 6),
    (['flight', 'airport', 'airline', 'travel', 'trip', 'vacation', 'holiday', 'tour', 'hotel', 'stay'], Icons.flight_rounded, 6),
    (['coffee', 'tea', 'cafe', 'juice', 'smoothie', 'shake'], Icons.local_cafe_rounded, 8),
    (['snack', 'chocolate', 'dessert', 'sweet', 'ice cream', 'icecream', 'bakery', 'cake'], Icons.icecream_rounded, 7),
    (['grocery', 'vegetable', 'veggie', 'fruit', 'market', 'kirana', 'provision', 'milk'], Icons.shopping_basket_rounded, 3),
    (['food', 'meal', 'lunch', 'dinner', 'breakfast', 'restaurant', 'dine', 'eat', 'canteen', 'mess', 'pizza', 'burger', 'swiggy', 'zomato', 'meat', 'chicken', 'fish', 'egg', 'mutton'], Icons.restaurant_rounded, 1),
    (['pet care', 'petcare', 'vet ', 'dog', 'puppy', 'kitten'], Icons.pets_rounded, 8),
    (['cloth', 'shirt', 'dress', 'footwear', 'shoe', 'sandal', 'fashion', 'myntra', 'amazon', 'flipkart', 'shopping', 'mall'], Icons.shopping_bag_rounded, 9),
    (['movie', 'cinema', 'film', 'concert', 'show'], Icons.movie_rounded, 7),
    (['game', 'gaming', 'chess', 'playstation', 'xbox', 'cricket', 'sport', 'toy'], Icons.sports_esports_rounded, 6),
    (['gym', 'fitness', 'yoga', 'workout'], Icons.fitness_center_rounded, 4),
    (['medical', 'medicine', 'pharmacy', 'doctor', 'hospital', 'clinic', 'tablet', 'dental', 'health'], Icons.medical_services_rounded, 0),
    (['salon', 'haircut', 'beauty', 'parlour', 'grooming'], Icons.content_cut_rounded, 7),
    (['school', 'college', 'tuition', 'course', 'study', 'exam', 'class fee', 'education', 'stationery', 'stationary', 'book'], Icons.school_rounded, 6),
    (['rent', 'house', 'home', 'flat', 'apartment', 'maintenance', 'repair', 'furniture', 'electrician', 'plumber'], Icons.home_rounded, 2),
    (['temple', 'pooja', 'puja', 'donation', 'charity', 'donate', 'offering', 'trust'], Icons.volunteer_activism_rounded, 1),
    (['gift', 'birthday', 'anniversary', 'festival', 'diwali'], Icons.card_giftcard_rounded, 7),
    (['insurance', 'policy', 'lic', 'premium'], Icons.verified_user_rounded, 4),
    (['salary', 'income', 'refund', 'cashback', 'bonus', 'interest'], Icons.savings_rounded, 3),
    (['bill', 'utility', 'emi', 'loan', 'due'], Icons.receipt_long_rounded, 9),
    (['other', 'misc', 'general', 'random', 'extra'], Icons.label_rounded, 9),
  ];

  static const List<IconData> _fallbackIcons = [
    Icons.category_rounded,
    Icons.receipt_long_rounded,
    Icons.shopping_bag_rounded,
    Icons.savings_rounded,
    Icons.local_offer_rounded,
    Icons.account_balance_wallet_rounded,
  ];

  /// Stable across restarts (unlike String.hashCode).
  static int _stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static String _normalize(String name) => ' ${name.toLowerCase().trim()} ';

  /// Auto icon for a category name. A manually picked icon (set in the
  /// category editor) always wins over the auto-match.
  static IconData iconFor(String categoryName) {
    final key = categoryName.toLowerCase().trim();
    final overrideCode = _manualOverrides[key];
    if (overrideCode != null) {
      final override = _iconFromCode(overrideCode);
      if (override != null) return override;
    }
    final n = _normalize(categoryName);
    for (final (keys, icon, _) in _rules) {
      for (final k in keys) {
        if (n.contains(' $k') || n.contains('$k ')) return icon;
      }
    }
    return _fallbackIcons[_stableHash(categoryName.toLowerCase()) % _fallbackIcons.length];
  }

  /// Auto color for a category name.
  static Color colorFor(String categoryName) {
    final n = _normalize(categoryName);
    for (final (keys, _, colorIndex) in _rules) {
      for (final k in keys) {
        if (n.contains(' $k') || n.contains('$k ')) return palette[colorIndex];
      }
    }
    return palette[_stableHash(categoryName.toLowerCase()) % palette.length];
  }

  // ---------------------------------------------------------------------------
  // Manual overrides (picked by the user in the category editor)
  // ---------------------------------------------------------------------------

  static final Map<String, int> _manualOverrides = {};

  /// Rebuilds the override registry from the stored categories. Categories
  /// saved through the editor with a hand-picked icon are marked with the
  /// "manual" icon family.
  static void syncOverrides(Iterable<Category> categories) {
    _manualOverrides.clear();
    for (final category in categories) {
      if (category.iconFamily == 'manual') {
        if (_iconFromCode(category.iconCode) != null) {
          _manualOverrides[category.name.toLowerCase().trim()] =
              category.iconCode;
        }
      }
    }
  }

  static IconData? _iconFromCode(int codePoint) {
    for (final item in availableIcons) {
      if ((item['icon'] as IconData).codePoint == codePoint) {
        return item['icon'] as IconData;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Legacy support (stored iconCode) + category editor icon set
  // ---------------------------------------------------------------------------

  static IconData getIcon(String family, int codePoint) {
    for (final item in availableIcons) {
      if ((item['icon'] as IconData).codePoint == codePoint) {
        return item['icon'] as IconData;
      }
    }
    return Icons.category_rounded;
  }

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Snacks', 'icon': Icons.icecream_rounded},
    {'name': 'Grocery', 'icon': Icons.shopping_basket_rounded},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Transport', 'icon': Icons.directions_bus_rounded},
    {'name': 'Cab', 'icon': Icons.local_taxi_rounded},
    {'name': 'Fuel', 'icon': Icons.local_gas_station_rounded},
    {'name': 'Flight', 'icon': Icons.flight_rounded},
    {'name': 'Rent', 'icon': Icons.home_rounded},
    {'name': 'Electricity', 'icon': Icons.bolt_rounded},
    {'name': 'Water', 'icon': Icons.water_drop_rounded},
    {'name': 'Internet', 'icon': Icons.wifi_rounded},
    {'name': 'Phone', 'icon': Icons.phone_iphone_rounded},
    {'name': 'Subscriptions', 'icon': Icons.subscriptions_rounded},
    {'name': 'Movies', 'icon': Icons.movie_rounded},
    {'name': 'Games', 'icon': Icons.sports_esports_rounded},
    {'name': 'Fitness', 'icon': Icons.fitness_center_rounded},
    {'name': 'Medical', 'icon': Icons.medical_services_rounded},
    {'name': 'Salon', 'icon': Icons.content_cut_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Donation', 'icon': Icons.volunteer_activism_rounded},
    {'name': 'Gifts', 'icon': Icons.card_giftcard_rounded},
    {'name': 'Insurance', 'icon': Icons.verified_user_rounded},
    {'name': 'Savings', 'icon': Icons.savings_rounded},
    {'name': 'Pets', 'icon': Icons.pets_rounded},
    {'name': 'Bills', 'icon': Icons.receipt_long_rounded},
    {'name': 'Other', 'icon': Icons.label_rounded},
  ];
}
