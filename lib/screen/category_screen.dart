import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import '../utils/icon_helper.dart';
import 'category_editor_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await CategoryService.getCategories();

    if (!mounted) return;

    setState(() {
      categories = data;
    });
  }

  Future<void> deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    await CategoryService.deleteCategory(category);
    loadCategories();
  }

  Future<void> openEditor([Category? category]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryEditorScreen(category: category)),
    );

    if (result == true) {
      loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),

      floatingActionButton: FloatingActionButton(onPressed: () => openEditor(), child: const Icon(Icons.add)),

      body: categories.isEmpty
          ? const Center(child: Text("No Categories Found", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(IconHelper.getIcon(category.iconCode), color: Colors.blue),
                    ),

                    title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),

                    onTap: () => openEditor(category),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => openEditor(category)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteCategory(category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
