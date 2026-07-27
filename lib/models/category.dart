import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int iconCode;

  @HiveField(2)
  String iconFamily;

  @HiveField(3)
  bool isDefault;

  Category({required this.name, required this.iconCode, required this.iconFamily, this.isDefault = false});
}
