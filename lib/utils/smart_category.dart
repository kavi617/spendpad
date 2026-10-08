import '../models/expense.dart';

/// A tiny, fully on-device "AI" that suggests a category for a note.
///
/// It is deliberately simple (bag-of-words + user history + keywords):
///  - zero model downloads, zero added app size, runs instantly on any phone
///  - learns implicitly from the user's own past expenses
///  - only ever *suggests* — the user can always override manually
class SmartCategory {
  SmartCategory._();

  static const _minHistoryScore = 1.5;

  // Keyword roots mapped onto the *root* of a likely category name. The first
  // existing category whose name contains the root wins, so this adapts to
  // whatever the user named their categories ("Food", "food & drinks", ...).
  static const List<(List<String>, String)> _keywordRoots = [
    (['lunch', 'dinner', 'breakfast', 'food', 'meal', 'restaurant', 'dine', 'swiggy', 'zomato', 'pizza', 'burger', 'canteen'], 'food'),
    (['grocery', 'vegetable', 'veggie', 'fruit', 'groceries', 'milk', 'market'], 'grocer'),
    (['vegetable', 'veggie', 'sabzi'], 'vegetab'),
    (['snack', 'chocolate', 'dessert', 'ice cream', 'icecream', 'cake', 'bakery'], 'snack'),
    (['petrol', 'fuel', 'diesel', 'cng'], 'petrol'),
    (['cab', 'taxi', 'uber', 'ola', 'rickshaw'], 'cab'),
    (['bus', 'train', 'metro', 'commute', 'fare', 'transport'], 'transport'),
    (['school', 'tuition', 'fees', 'fee', 'exam', 'class'], 'school'),
    (['stationery', 'stationary', 'pen', 'notebook'], 'station'),
    (['haircut', 'salon', 'grooming', 'parlour'], 'groom'),
    (['cylinder', 'gas booking', 'lpg'], 'cylinder'),
    (['chess', 'game', 'gaming'], 'chess'),
    (['movie', 'cinema', 'entertainment', 'concert'], 'entertain'),
    (['meat', 'chicken', 'fish', 'mutton'], 'meat'),
    (['medicine', 'medical', 'pharmacy', 'doctor', 'hospital'], 'medic'),
    (['rent', 'maintenance'], 'rent'),
    (['bill', 'recharge', 'electricity', 'wifi', 'internet', 'mobile'], 'bill'),
    (['gift', 'birthday'], 'gift'),
    (['pooja', 'puja', 'temple', 'donation', 'charity'], 'pooja'),
  ];

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3)
        .toList();
  }

  /// Returns the suggested category name, or null when not confident enough.
  static String? suggest({
    required String note,
    required List<Expense> history,
    required List<String> categoryNames,
  }) {
    final cleanNote = note.trim().toLowerCase();
    if (cleanNote.length < 3 || categoryNames.isEmpty) return null;

    // 1) Memory: what categories did similar notes get before?
    final scores = <String, double>{};
    final tokens = _tokenize(cleanNote);
    final now = DateTime.now();

    if (tokens.isNotEmpty) {
      for (final e in history) {
        final pastTokens = _tokenize(e.note.toLowerCase());
        if (pastTokens.isEmpty) continue;

        var overlap = 0;
        for (final t in tokens) {
          if (pastTokens.contains(t)) overlap++;
        }
        if (overlap == 0) continue;

        // Recent entries teach more than old ones.
        final recency =
            e.date.isAfter(now.subtract(const Duration(days: 90))) ? 1.0 : 0.5;
        scores[e.category] = (scores[e.category] ?? 0) + overlap * recency;
      }

      String? best;
      var bestScore = 0.0;
      scores.forEach((category, score) {
        if (score > bestScore) {
          bestScore = score;
          best = category;
        }
      });

      if (best != null &&
          bestScore >= _minHistoryScore &&
          _exists(best!, categoryNames)) {
        return best;
      }
    }

    // 2) The note literally mentions a category ("Petrol fill", "grocery ...").
    for (final name in categoryNames) {
      final lowered = name.toLowerCase().trim();
      if (lowered.length >= 3 && cleanNote.contains(lowered)) {
        return name;
      }
    }

    // 3) Keyword roots mapped to an existing category name.
    for (final (keys, root) in _keywordRoots) {
      for (final k in keys) {
        if (RegExp('(^|[^a-z])$k([^a-z]|\$)').hasMatch(cleanNote)) {
          final match = _findByRoot(root, categoryNames);
          if (match != null) return match;
        }
      }
    }

    return null;
  }

  static bool _exists(String name, List<String> names) =>
      names.any((n) => n.toLowerCase() == name.toLowerCase());

  static String? _findByRoot(String root, List<String> names) {
    for (final n in names) {
      if (n.toLowerCase().contains(root)) return n;
    }
    return null;
  }
}
