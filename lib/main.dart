import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/expense.dart';
import 'models/category.dart';
import 'services/category_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_format.dart';
import 'screen/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());

  // Load user preferences (safe: plain key/value box, never touches data).
  final settings = await SettingsService.openBox();
  AppFormat.symbol = settings.get('currency', defaultValue: '₹') as String;

  // Warm up categories so manual icon overrides are ready app-wide.
  await CategoryService.getCategories();

  runApp(const SpendPad());
}

class SpendPad extends StatelessWidget {
  const SpendPad({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SpendPad",
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
