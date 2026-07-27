import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/expense.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Expense> allExpenses = [];

  DateTime? selectedMonth;

  double total = 0;
  double average = 0;
  double highest = 0;

  int transactionCount = 0;

  Map<String, double> categoryTotals = {};

  String topCategory = "";
  double topCategoryAmount = 0;

  @override
  void initState() {
    super.initState();

    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final data = await DatabaseService.getExpenses();

    setState(() {
      allExpenses = data;

      final months = getAvailableMonths();

      if (months.isNotEmpty) {
        selectedMonth = months.first;
      }
    });

    calculateReport();
  }

  List<DateTime> getAvailableMonths() {
    final Set<DateTime> months = {};

    for (var expense in allExpenses) {
      months.add(DateTime(expense.date.year, expense.date.month));
    }

    final result = months.toList();

    result.sort((a, b) => b.compareTo(a));

    return result;
  }

  void calculateReport() {
    if (selectedMonth == null) {
      return;
    }

    final monthlyExpenses = allExpenses.where((expense) {
      return expense.date.month == selectedMonth!.month && expense.date.year == selectedMonth!.year;
    }).toList();

    double sum = 0;

    double max = 0;

    Map<String, double> categories = {};

    for (var expense in monthlyExpenses) {
      sum += expense.amount;

      if (expense.amount > max) {
        max = expense.amount;
      }

      categories[expense.category] = (categories[expense.category] ?? 0) + expense.amount;
    }

    String highestCategory = "";

    double highestAmount = 0;

    categories.forEach((key, value) {
      if (value > highestAmount) {
        highestAmount = value;

        highestCategory = key;
      }
    });

    setState(() {
      total = sum;

      highest = max;

      transactionCount = monthlyExpenses.length;

      average = monthlyExpenses.isEmpty ? 0 : sum / monthlyExpenses.length;

      categoryTotals = categories;

      topCategory = highestCategory;

      topCategoryAmount = highestAmount;
    });
  }

  String monthName(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${months[date.month - 1]} ${date.year}";
  }

  List<Expense> getLast7Days() {
    final now = DateTime.now();

    final start = now.subtract(const Duration(days: 7));

    return allExpenses.where((expense) {
      return expense.date.isAfter(start);
    }).toList();
  }

  Map<String, double> getLastSixMonths() {
    Map<String, double> result = {};

    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);

      double amount = 0;

      for (var expense in allExpenses) {
        if (expense.date.month == month.month && expense.date.year == month.year) {
          amount += expense.amount;
        }
      }

      result["${month.month}/${month.year}"] = amount;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final months = getAvailableMonths();

    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          if (months.isNotEmpty)
            DropdownButtonFormField<DateTime>(
              value: selectedMonth,

              decoration: const InputDecoration(labelText: "Select Month", border: OutlineInputBorder()),

              items: months.map((month) {
                return DropdownMenuItem(value: month, child: Text(monthName(month)));
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                });

                calculateReport();
              },
            ),

          const SizedBox(height: 20),

          const Text("Monthly Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          reportCard(Icons.money, "Total Spending", "₹${total.toStringAsFixed(2)}"),

          reportCard(Icons.receipt, "Transactions", "$transactionCount"),

          reportCard(Icons.calculate, "Average Expense", "₹${average.toStringAsFixed(2)}"),

          reportCard(Icons.trending_up, "Highest Expense", "₹${highest.toStringAsFixed(2)}"),

          const SizedBox(height: 20),

          if (topCategory.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.star),

                title: const Text("Top Spending Category"),

                subtitle: Text(topCategory),

                trailing: Text(
                  "₹${topCategoryAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 20),

          const Text("Category Chart", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          SizedBox(
            height: 250,

            child: categoryTotals.isEmpty
                ? const Center(child: Text("No data"))
                : PieChart(
                    PieChartData(
                      sections: categoryTotals.entries.map((e) {
                        return PieChartSectionData(value: e.value, title: e.key, radius: 80);
                      }).toList(),
                    ),
                  ),
          ),

          const SizedBox(height: 30),

          const Text("Last 6 Months Trend", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          SizedBox(
            height: 250,

            child: BarChart(
              BarChartData(
                barGroups: getLastSixMonths().entries.toList().asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,

                    barRods: [BarChartRodData(toY: e.value.value, width: 18)],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Last 7 Days Spending", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          ...getLast7Days().map((expense) {
            return Card(
              child: ListTile(
                title: Text(expense.note.isEmpty ? expense.category : expense.note),

                subtitle: Text(expense.category),

                trailing: Text("₹${expense.amount.toStringAsFixed(2)}"),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget reportCard(IconData icon, String title, String value) {
    return Card(
      elevation: 3,

      child: ListTile(
        leading: Icon(icon),

        title: Text(title),

        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
