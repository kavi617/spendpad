/// Central formatting helpers (currency + dates) so every screen looks
/// consistent. The currency symbol can be changed from Settings.
class AppFormat {
  AppFormat._();

  /// Loaded from the settings box at startup; changeable in Settings.
  static String symbol = '₹';

  // ---------------------------------------------------------------------------
  // Money
  // ---------------------------------------------------------------------------

  /// 1234567.5 -> "₹12,34,567.50" (Indian grouping)
  static String money(double amount) => '$symbol${_groupAmount(amount)}';

  /// 92200 -> "₹92.2K", 1234567 -> "₹12.3L", 25000000 -> "₹2.5Cr"
  static String moneyCompact(double amount) {
    final sign = amount < 0 ? '-' : '';
    final v = amount.abs();
    if (v >= 10000000) return '$sign$symbol${_trim(v / 10000000)}Cr';
    if (v >= 100000) return '$sign$symbol${_trim(v / 100000)}L';
    if (v >= 1000) return '$sign$symbol${_trim(v / 1000)}K';
    return '$sign$symbol${_trim(v)}';
  }

  static String _groupAmount(num amount) {
    final fixed = amount.toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final digits = dot == -1 ? fixed : fixed.substring(0, dot);
    final decimals = dot == -1 ? '' : fixed.substring(dot);
    return '${_groupIndian(digits)}$decimals';
  }

  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final buf = StringBuffer();
    // Indian system: groups of two after the first chunk.
    final headLen = rest.length % 2 == 0 ? 2 : 1;
    buf.write(rest.substring(0, headLen));
    for (var i = headLen; i < rest.length; i += 2) {
      buf.write(',${rest.substring(i, i + 2)}');
    }
    return '${buf.toString()},$last3';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  // ---------------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------------

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// "04 Sep"
  static String dayMonth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthsShort[d.month - 1]}';

  /// "04 Sep 2026"
  static String fullDate(DateTime d) => '${dayMonth(d)} ${d.year}';

  /// "September 2026"
  static String monthYear(DateTime m) => '${_monthsFull[m.month - 1]} ${m.year}';

  /// "Sep"
  static String shortMonth(DateTime m) => _monthsShort[m.month - 1];

  /// "Today", "Yesterday" or "04 Sep 2026"
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return fullDate(d);
  }

  /// "2026-09-04" — used for CSV export.
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
