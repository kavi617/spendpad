import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../utils/app_format.dart';

enum ExportFormat { csv, xlsx, json }

class BackupService {
  // ================================
  // Export (any format)
  // ================================

  static String _stamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<File> writeFile(
    List<Expense> expenses,
    ExportFormat format,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final ext = switch (format) {
      ExportFormat.csv => 'csv',
      ExportFormat.xlsx => 'xlsx',
      ExportFormat.json => 'json',
    };
    final file = File('${directory.path}/spendpad_expenses_${_stamp()}.$ext');

    switch (format) {
      case ExportFormat.csv:
        return file.writeAsString(_csvFor(expenses));
      case ExportFormat.xlsx:
        return file.writeAsBytes(_xlsxFor(expenses));
      case ExportFormat.json:
        return file.writeAsString(_jsonFor(expenses));
    }
  }

  static Future<void> exportExpenses(
    List<Expense> expenses,
    ExportFormat format,
  ) async {
    final file = await writeFile(expenses, format);
    final mime = switch (format) {
      ExportFormat.csv => 'text/csv',
      ExportFormat.xlsx =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ExportFormat.json => 'application/json',
    };
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        text: 'SpendPad export — ${expenses.length} transactions',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _csvFor(List<Expense> expenses) {
    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final buffer = StringBuffer()..writeln('Date,Category,Note,Amount');

    for (final e in sorted) {
      buffer.writeln([
        AppFormat.isoDate(e.date),
        _csvEscape(e.category),
        _csvEscape(e.note),
        e.amount.toStringAsFixed(2),
      ].join(','));
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Excel (.xlsx) — opens directly in Excel / Google Sheets / Numbers
  // ---------------------------------------------------------------------------

  static List<int> _xlsxFor(List<Expense> expenses) {
    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final excel = Excel.createExcel();
    final sheet = excel['Expenses'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Note'),
      TextCellValue('Amount'),
    ]);

    for (final e in sorted) {
      sheet.appendRow([
        TextCellValue(AppFormat.isoDate(e.date)),
        TextCellValue(e.category),
        TextCellValue(e.note),
        DoubleCellValue(e.amount),
      ]);
    }

    // Remove the default empty sheet created by the library.
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    excel.setDefaultSheet('Expenses');

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Could not generate the Excel file');
    }
    return bytes;
  }

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  static String _jsonFor(List<Expense> expenses) {
    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final data = sorted
        .map(
          (e) => {
            'id': e.id,
            'date': AppFormat.isoDate(e.date),
            'category': e.category,
            'note': e.note,
            'amount': e.amount,
          },
        )
        .toList();

    return const JsonEncoder.withIndent('  ').convert({
      'app': 'SpendPad',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': data.length,
      'expenses': data,
    });
  }

  // ================================
  // Full JSON Backup (legacy format, includes ids — used by Restore)
  // ================================

  static Future<void> exportExpensesBackup(List<Expense> expenses) async {
    final data = expenses.map((expense) {
      return {
        "id": expense.id,
        "category": expense.category,
        "note": expense.note,
        "amount": expense.amount,
        "date": expense.date.toIso8601String(),
      };
    }).toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final directory = await getApplicationDocumentsDirectory();

    final file = File("${directory.path}/spendpad_backup.json");

    await file.writeAsString(jsonString);

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: "SpendPad Expense Backup"));
  }

  // ================================
  // Import Expenses from JSON File
  // ================================

  static Future<List<Expense>> importExpenses(File file) async {
    final jsonString = await file.readAsString();

    final List<dynamic> data = jsonDecode(jsonString);

    return data.map((item) {
      return Expense(
        id: item["id"].toString(),

        category: item["category"] ?? "Other",

        note: item["note"] ?? "",

        amount: (item["amount"] as num).toDouble(),

        date: DateTime.parse(item["date"]),
      );
    }).toList();
  }

  // ================================
  // Pick Backup JSON File
  // ================================

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
