import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String boxName = "settings";

  static const String darkModeKey = "darkMode";

  // Open settings storage
  static Future<Box> openBox() async {
    return await Hive.openBox(boxName);
  }

  // Read dark mode setting
  static Future<bool> getDarkMode() async {
    final box = await openBox();

    return box.get(darkModeKey, defaultValue: false);
  }

  // Save dark mode setting
  static Future<void> saveDarkMode(bool value) async {
    final box = await openBox();

    await box.put(darkModeKey, value);
  }
}
