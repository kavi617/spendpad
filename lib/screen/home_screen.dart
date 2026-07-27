import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import 'add_expense_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> expenses = [];

  double monthlyTotal = 0;

  double todayTotal = 0;

  int monthlyTransactionCount = 0;

  String topCategory = "";

  double topCategoryAmount = 0;

  double topCategoryPercentage = 0;

  @override
  void initState() {
    super.initState();

    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final data = await DatabaseService.getExpenses();

    final now = DateTime.now();

    double monthTotal = 0;

    double today = 0;

    int monthTransactions = 0;

    Map<String, double> categoryMap = {};

    for (final expense in data) {
      if (expense.date.year == now.year && expense.date.month == now.month) {
        monthTotal += expense.amount;

        monthTransactions++;

        categoryMap[expense.category] = (categoryMap[expense.category] ?? 0) + expense.amount;
      }

      if (expense.date.year == now.year && expense.date.month == now.month && expense.date.day == now.day) {
        today += expense.amount;
      }
    }

    String category = "";

    double highest = 0;

    categoryMap.forEach((key, value) {
      if (value > highest) {
        highest = value;

        category = key;
      }
    });

    if (!mounted) return;

    setState(() {
      expenses = data;

      monthlyTotal = monthTotal;

      todayTotal = today;

      monthlyTransactionCount = monthTransactions;

      topCategory = category;

      topCategoryAmount = highest;

      topCategoryPercentage = monthlyTotal == 0 ? 0 : (highest / monthlyTotal) * 100;
    });
  }

  Future<void> addExpense() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen()));

    if (result != null && result is Expense) {
      await DatabaseService.addExpense(result);

      await loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expense saved successfully")));
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    await DatabaseService.deleteExpense(expense);

    await loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SpendPad")),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addExpense,

        icon: const Icon(Icons.add),

        label: const Text("Expense"),
      ),

      body: RefreshIndicator(
        onRefresh: loadExpenses,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            const Text("Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: dashboardCard(Icons.calendar_month, "This Month", "\$${monthlyTotal.toStringAsFixed(2)}"),
                ),

                const SizedBox(width: 12),

                Expanded(child: dashboardCard(Icons.today, "Today", "\$${todayTotal.toStringAsFixed(2)}")),
              ],
            ),

            const SizedBox(height: 15),

            dashboardCard(Icons.receipt_long, "Transactions", "$monthlyTransactionCount this month"),

            const SizedBox(height: 15),

            if (topCategory.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),

                  title: const Text("Top Spending Category"),

                  subtitle: Text("$topCategory (${topCategoryPercentage.toStringAsFixed(1)}%)"),

                  trailing: Text(
                    "\$${topCategoryAmount.toStringAsFixed(2)}",

                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Text("Recent Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            if (expenses.isEmpty)
              const Center(
                child: Padding(padding: EdgeInsets.all(40), child: Text("No expenses yet")),
              )
            else
              ...expenses.reversed.map((expense) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(expense.category[0].toUpperCase())),

                    title: Text(expense.category),

                    subtitle: Text(expense.note.isEmpty ? expense.date.toString().split(" ").first : expense.note),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Text(
                          "\$${expense.amount.toStringAsFixed(2)}",

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),

                          onPressed: () {
                            deleteExpense(expense);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(IconData icon, String title, String value) {
    return Card(
      elevation: 3,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(icon, size: 30),

            const SizedBox(height: 10),

            Text(title),

            const SizedBox(height: 5),

            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
