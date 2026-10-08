import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String boxName = "settings";

  static Future<Box> openBox() async {
    return await Hive.openBox(boxName);
  }
}