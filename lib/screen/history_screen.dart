import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/category_service.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Expense> expenses = [];

  List<Expense> filteredExpenses = [];

  String searchText = "";

  String selectedCategory = "All";

  String sortOption = "Newest";

  List<String> categories = ["All"];

  @override
  void initState() {
    super.initState();

    loadExpenses();

    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await CategoryService.getCategories();

    if (!mounted) return;

    setState(() {
      categories = ["All", ...data.map((e) => e.name)];

      // Reset selection if category was deleted

      if (!categories.contains(selectedCategory)) {
        selectedCategory = "All";
      }
    });
  }

  Future<void> loadExpenses() async {
    final data = await DatabaseService.getExpenses();

    if (!mounted) return;

    setState(() {
      expenses = data;

      applyFilters();
    });
  }

  void applyFilters() {
    List<Expense> result = List.from(expenses);

    // Search filter

    if (searchText.isNotEmpty) {
      result = result.where((expense) {
        return expense.note.toLowerCase().contains(searchText.toLowerCase()) ||
            expense.category.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }

    // Category filter

    if (selectedCategory != "All") {
      result = result.where((expense) {
        return expense.category == selectedCategory;
      }).toList();
    }

    // Sorting

    switch (sortOption) {
      case "Newest":
        result.sort((a, b) => b.date.compareTo(a.date));

        break;

      case "Oldest":
        result.sort((a, b) => a.date.compareTo(b.date));

        break;

      case "Highest":
        result.sort((a, b) => b.amount.compareTo(a.amount));

        break;

      case "Lowest":
        result.sort((a, b) => a.amount.compareTo(b.amount));

        break;
    }

    filteredExpenses = result;
  }

  @override
  Widget build(BuildContext context) {
    applyFilters();

    return Scaffold(
      appBar: AppBar(title: const Text("Expenses")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search expenses",

                prefixIcon: Icon(Icons.search),

                border: OutlineInputBorder(),
              ),

              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),

            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,

                    isExpanded: true,

                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),

                    items: categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,

                        child: Text(c, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sortOption,

                    isExpanded: true,

                    decoration: const InputDecoration(labelText: "Sort", border: OutlineInputBorder()),

                    items: ["Newest", "Oldest", "Highest", "Lowest"].map((s) {
                      return DropdownMenuItem<String>(value: s, child: Text(s));
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        sortOption = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(child: Text("No expenses found", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: filteredExpenses.length,

                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: ExpenseCard(
                          expense: expense,

                          onDelete: () async {
                            await DatabaseService.deleteExpense(expense);

                            loadExpenses();
                          },

                          onEdit: () async {
                            final updated = await Navigator.push(
                              context,

                              MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
                            );

                            if (updated != null) {
                              await DatabaseService.updateExpense(updated);

                              loadExpenses();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
