import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String note;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  Expense({required this.id, required this.category, required this.note, required this.amount, required this.date});
}
