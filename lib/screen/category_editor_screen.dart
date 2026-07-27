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

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      nameController.text = widget.category!.name;
      selectedIcon = widget.category!.iconCode;
    } else {
      selectedIcon = IconHelper.availableIcons.first.codePoint;
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
      iconFamily: "material",
      iconCode: selectedIcon,
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
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Choose Icon", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: IconHelper.availableIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final icon = IconHelper.availableIcons[index];

                  final isSelected = selectedIcon == icon.codePoint;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon.codePoint;
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
}
