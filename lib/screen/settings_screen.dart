import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/database_service.dart';
import '../services/backup_service.dart';
import 'category_screen.dart';

class SettingsService {
  static const String boxName = "settings";

  static Future<Box> openBox() async {
    return await Hive.openBox(boxName);
  }

  static Future<bool> getDarkMode() async {
    final box = await openBox();

    return box.get("darkMode", defaultValue: false);
  }

  static Future<void> saveDarkMode(bool value) async {
    final box = await openBox();

    await box.put("darkMode", value);
  }
}

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;

  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.isDarkMode, required this.onThemeChanged});

  Future<void> clearExpenses(BuildContext context) async {
    try {
      final box = await DatabaseService.openExpenseBox();

      await box.clear();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All expenses cleared")));
    } catch (e) {
      showMessage(context, "Clear failed: $e");
    }
  }

  Future<void> exportBackup(BuildContext context) async {
    try {
      final expenses = await DatabaseService.getExpenses();

      await BackupService.exportExpenses(expenses);

      if (!context.mounted) return;

      showMessage(context, "Backup exported successfully");
    } catch (e) {
      showMessage(context, "Export failed: $e");
    }
  }

  Future<void> restoreBackup(BuildContext context) async {
    try {
      final importedExpenses = await BackupService.pickBackupFile();

      if (importedExpenses == null) {
        showMessage(context, "No backup selected");

        return;
      }

      for (var expense in importedExpenses) {
        await DatabaseService.addExpense(expense);
      }

      if (!context.mounted) return;

      showMessage(context, "Backup restored successfully");
    } catch (e) {
      showMessage(context, "Restore failed: $e");
    }
  }

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),

      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),

            child: Text("Preferences", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),

          ListTile(
            leading: const Icon(Icons.dark_mode),

            title: const Text("Dark Mode"),

            trailing: Switch(value: isDarkMode, onChanged: onThemeChanged),
          ),

          ListTile(
            leading: const Icon(Icons.category),

            title: const Text("Manage Categories"),

            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
            },
          ),

          const Padding(
            padding: EdgeInsets.all(16),

            child: Text("Data Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),

          ListTile(
            leading: const Icon(Icons.backup),

            title: const Text("Export Backup"),

            onTap: () {
              exportBackup(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.restore),

            title: const Text("Restore Backup"),

            onTap: () {
              restoreBackup(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),

            title: const Text("Clear All Expenses", style: TextStyle(color: Colors.red)),

            onTap: () {
              clearExpenses(context);
            },
          ),

          const Padding(
            padding: EdgeInsets.all(16),

            child: Text("About", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),

          const ListTile(leading: Icon(Icons.info), title: Text("SpendPad"), subtitle: Text("Version 1.0.0")),
        ],
      ),
    );
  }
}
