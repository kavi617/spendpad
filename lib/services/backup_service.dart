import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';

class BackupService {
  // Export expenses as JSON backup file
  static Future<void> exportExpenses(List<Expense> expenses) async {
    final data = expenses.map((expense) {
      return {
        "id": expense.id,
        "category": expense.category,
        "note": expense.note,
        "amount": expense.amount,
        "date": expense.date.toIso8601String(),
      };
    }).toList();

    final jsonString = jsonEncode(data);

    final directory = await getApplicationDocumentsDirectory();

    final file = File("${directory.path}/spendpad_backup.json");

    await file.writeAsString(jsonString);

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: "SpendPad Expense Backup"));
  }

  // Import expenses from JSON file
  static Future<List<Expense>> importExpenses(File file) async {
    final jsonString = await file.readAsString();

    final List<dynamic> data = jsonDecode(jsonString);

    return data.map((item) {
      return Expense(
        id: item["id"],
        category: item["category"],
        note: item["note"],
        amount: (item["amount"] as num).toDouble(),
        date: DateTime.parse(item["date"]),
      );
    }).toList();
  }

  // Pick backup JSON file
  static Future<List<Expense>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result == null) {
      return null;
    }

    final path = result.files.single.path;

    if (path == null) {
      return null;
    }

    final file = File(path);

    return await importExpenses(file);
  }
}
