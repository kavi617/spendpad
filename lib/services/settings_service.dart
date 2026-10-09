import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String boxName = "settings";

  static Future<Box> openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }

  static Future<void> setValue(String key, Object value) async {
    final box = await openBox();
    await box.put(key, value);
  }
}
