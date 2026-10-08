import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../utils/app_format.dart';
import '../utils/expense_helper.dart';

/// Excel (.xlsx) and PDF analytics report generation.
/// Both libraries are pure Dart — no native code, works on every phone.
class ReportService {
  ReportService._();

  static String _stamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<File> _writeFile(String name, List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$name');
    return file.writeAsBytes(bytes);
  }

  static Future<void> _share(File file, String text) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  // ---------------------------------------------------------------------------
  // Excel
  // ---------------------------------------------------------------------------

  static Future<void> exportExcel(List<Expense> expenses) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Expenses');
    final sheet = excel['Expenses'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Note'),
      TextCellValue('Amount'),
    ]);

    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      sheet.appendRow([
        TextCellValue(AppFormat.isoDate(e.date)),
        TextCellValue(e.category),
        TextCellValue(e.note),
        DoubleCellValue(e.amount),
      ]);
    }

    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Total'),
      DoubleCellValue(ExpenseHelper.totalOf(expenses)),
    ]);

    final bytes = excel.encode()!;
    final file = await _writeFile('spendpad_expenses_${_stamp()}.xlsx', bytes);
    await _share(file, 'SpendPad export — ${expenses.length} transactions');
  }

  // ---------------------------------------------------------------------------
  // PDF analytics report
  // ---------------------------------------------------------------------------

  /// The built-in PDF font only covers Latin-1, so map a few symbols.
  static String _money(double v) {
    final symbol = AppFormat.symbol;
    final prefix = switch (symbol) {
      '₹' => 'Rs.',
      '€' => 'EUR',
      _ => symbol,
    };
    return '$prefix ${AppFormat.money(v).substring(symbol.length)}';
  }

  static String _safe(String s) =>
      s.replaceAll(RegExp(r'[^\x00-\xFF]'), '').trim();

  static pw.Widget _heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1F7A4D'),
          ),
        ),
      );

  static Future<void> exportPdf({
    required List<Expense> expenses,
    required String periodLabel,
    DateTimeRange? range,
  }) async {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final total = ExpenseHelper.totalOf(expenses);

    // Days covered by the period (for avg/day).
    int days;
    if (range != null) {
      days = range.end.difference(range.start).inDays + 1;
    } else if (sorted.isNotEmpty) {
      final first = sorted.last.date;
      final last = sorted.first.date;
      days = last.difference(first).inDays + 1;
    } else {
      days = 1;
    }
    if (days < 1) days = 1;

    // Category breakdown.
    final catTotals = ExpenseHelper.categoryTotals(expenses).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Monthly overview (only when the period spans several months).
    final monthMap = <DateTime, double>{};
    for (final e in expenses) {
      final m = DateTime(e.date.year, e.date.month);
      monthMap[m] = (monthMap[m] ?? 0) + e.amount;
    }
    final months = monthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'SpendPad — Expense Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F7A4D'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _safe(periodLabel),
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Generated on ${AppFormat.fullDate(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#777777'),
            ),
          ),

          _heading('Summary'),
          pw.TableHelper.fromTextArray(
            headers: const ['Metric', 'Value'],
            data: [
              ['Total spent', _money(total)],
              ['Transactions', '${expenses.length}'],
              ['Average per day', _money(expenses.isEmpty ? 0 : total / days)],
              [
                'Average per transaction',
                _money(expenses.isEmpty ? 0 : total / expenses.length),
              ],
              [
                'Top category',
                catTotals.isEmpty ? '-' : _safe(catTotals.first.key),
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1F7A4D'),
            ),
            cellStyle: pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.all(6),
          ),

          _heading('Category breakdown'),
          catTotals.isEmpty
              ? pw.Text('No expenses in this period.')
              : pw.TableHelper.fromTextArray(
                  headers: const ['Category', 'Amount', 'Share'],
                  data: [
                    for (final e in catTotals)
                      [
                        _safe(e.key),
                        _money(e.value),
                        total == 0
                            ? '0%'
                            : '${((e.value / total) * 100).toStringAsFixed(1)}%',
                      ],
                    [
                      'Total',
                      _money(total),
                      total == 0 ? '0%' : '100%',
                    ],
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1F7A4D'),
                  ),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.all(6),
                ),

          if (months.length > 1) ...[
            _heading('Monthly overview'),
            pw.TableHelper.fromTextArray(
              headers: const ['Month', 'Amount'],
              data: [
                for (final m in months)
                  [AppFormat.monthYear(m.key), _money(m.value)],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1F7A4D'),
              ),
              cellStyle: pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ],

          _heading('Top expenses'),
          sorted.isEmpty
              ? pw.Text('No expenses in this period.')
              : pw.TableHelper.fromTextArray(
                  headers: const ['Date', 'Category', 'Note', 'Amount'],
                  data: [
                    for (final e in sorted.take(10))
                      [
                        AppFormat.isoDate(e.date),
                        _safe(e.category),
                        _safe(e.note.isEmpty ? '-' : e.note),
                        _money(e.amount),
                      ],
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1F7A4D'),
                  ),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.all(6),
                ),

          pw.SizedBox(height: 16),
          pw.Text(
            'Generated by SpendPad',
            style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#999999')),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final file = await _writeFile('spendpad_report_${_stamp()}.pdf', bytes);
    await _share(file, 'SpendPad analytics report — $periodLabel');
  }
}
