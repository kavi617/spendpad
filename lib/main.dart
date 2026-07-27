import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/expense.dart';
import 'models/category.dart';

import 'services/settings_service.dart';

import 'screen/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Hive adapters
  Hive.registerAdapter(ExpenseAdapter());

  Hive.registerAdapter(CategoryAdapter());

  final isDarkMode = await SettingsService.getDarkMode();

  runApp(SpendPad(isDarkMode: isDarkMode));
}

class SpendPad extends StatefulWidget {
  final bool isDarkMode;

  const SpendPad({super.key, required this.isDarkMode});

  @override
  State<SpendPad> createState() => _SpendPadState();
}

class _SpendPadState extends State<SpendPad> {
  late bool isDark;

  @override
  void initState() {
    super.initState();

    isDark = widget.isDarkMode;
  }

  Future<void> changeTheme(bool value) async {
    await SettingsService.saveDarkMode(value);

    setState(() {
      isDark = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "SpendPad",

      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),

      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      home: MainScreen(isDarkMode: isDark, onThemeChanged: changeTheme),
    );
  }
}
