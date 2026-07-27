import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();

  final TextEditingController noteController = TextEditingController();

  List<Category> categories = [];

  String? selectedCategory;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    loadCategories();

    // Load existing expense when editing
    if (widget.expense != null) {
      amountController.text = widget.expense!.amount.toString();

      noteController.text = widget.expense!.note;

      selectedCategory = widget.expense!.category;

      selectedDate = widget.expense!.date;
    }
  }

  Future<void> loadCategories() async {
    final data = await CategoryService.getCategories();

    if (!mounted) return;

    setState(() {
      categories = data;

      // Only set default category for new expense
      if (widget.expense == null && selectedCategory == null && categories.isNotEmpty) {
        selectedCategory = categories.first.name;
      }
    });
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,

      initialDate: selectedDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  void dispose() {
    amountController.dispose();

    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.expense == null ? "Add Expense" : "Edit Expense")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: amountController,

              keyboardType: const TextInputType.numberWithOptions(decimal: true),

              decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ ", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),

            categories.isEmpty
                ? const Text(
                    "No categories available. Please add categories from Settings.",
                    style: TextStyle(color: Colors.red),
                  )
                : DropdownButtonFormField<String>(
                    value: selectedCategory,

                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),

                    items: categories.map((category) {
                      return DropdownMenuItem<String>(value: category.name, child: Text(category.name));
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),

            const SizedBox(height: 20),

            InkWell(
              onTap: selectDate,

              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date",

                  border: OutlineInputBorder(),

                  suffixIcon: Icon(Icons.calendar_today),
                ),

                child: Text(formatDate(selectedDate)),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: noteController,

              decoration: const InputDecoration(labelText: "Note", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(onPressed: saveExpense, child: const Text("SAVE")),
            ),
          ],
        ),
      ),
    );
  }

  void saveExpense() {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an amount")));

      return;
    }

    final amount = double.tryParse(amountController.text);

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));

      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Amount must be greater than zero")));

      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));

      return;
    }

    final expense = Expense(
      id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),

      category: selectedCategory!,

      note: noteController.text,

      amount: amount,

      date: selectedDate,
    );

    Navigator.pop(context, expense);
  }
}
