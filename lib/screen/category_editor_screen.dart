import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import '../utils/icon_helper.dart';

class CategoryEditorScreen extends StatefulWidget {
  final Category? category;

  const CategoryEditorScreen({super.key, this.category});

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  final TextEditingController nameController = TextEditingController();

  late int selectedIcon;

  String selectedIconFamily = "MaterialIcons";

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      nameController.text = widget.category!.name;

      selectedIcon = widget.category!.iconCode;

      selectedIconFamily = widget.category!.iconFamily;
    } else {
      selectedIcon = (IconHelper.availableIcons.first["icon"] as IconData).codePoint;
    }
  }

  Future<void> saveCategory() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category name required")));

      return;
    }

    final category = Category(
      name: name,
      iconCode: selectedIcon,
      iconFamily: selectedIconFamily,
      isDefault: widget.category?.isDefault ?? false,
    );

    if (widget.category == null) {
      await CategoryService.addCategory(category);
    } else {
      widget.category!.name = category.name;

      widget.category!.iconCode = category.iconCode;

      widget.category!.iconFamily = category.iconFamily;

      await widget.category!.save();
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category == null ? "Add Category" : "Edit Category")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            TextField(
              controller: nameController,

              decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 25),

            const Text("Choose Icon", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 15),

            Expanded(
              child: GridView.builder(
                itemCount: IconHelper.availableIcons.length,

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,

                  crossAxisSpacing: 12,

                  mainAxisSpacing: 12,
                ),

                itemBuilder: (context, index) {
                  final item = IconHelper.availableIcons[index];

                  final icon = item["icon"] as IconData;

                  final isSelected = selectedIcon == icon.codePoint;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon.codePoint;

                        selectedIconFamily = "MaterialIcons";
                      });
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                      ),

                      child: Icon(icon, size: 30, color: isSelected ? Colors.blue : Colors.black87),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(onPressed: saveCategory, child: const Text("Save")),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }
}
