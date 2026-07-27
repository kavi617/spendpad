import '../models/expense.dart';

class ExpenseHelper {
  static double getTodayTotal(List<Expense> expenses) {
    double total = 0;

    final now = DateTime.now();

    for (var expense in expenses) {
      if (expense.date.day == now.day && expense.date.month == now.month && expense.date.year == now.year) {
        total += expense.amount;
      }
    }

    return total;
  }

  static double getMonthTotal(List<Expense> expenses) {
    double total = 0;

    final now = DateTime.now();

    for (var expense in expenses) {
      if (expense.date.month == now.month && expense.date.year == now.year) {
        total += expense.amount;
      }
    }

    return total;
  }

  static int getTotalExpenses(List<Expense> expenses) {
    return expenses.length;
  }

  static double getAverageExpense(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return 0;
    }

    return getMonthTotal(expenses) / expenses.length;
  }
}
