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
    await CategoryService.deleteCategory(category);

    loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryEditorScreen()));

          if (result == true) {
            loadCategories();
          }
        },

        icon: const Icon(Icons.add),

        label: const Text("Category"),
      ),

      body: categories.isEmpty
          ? const Center(child: Text("No categories found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: categories.length,

              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  child: ListTile(
                    leading: Icon(IconHelper.getIcon(category.iconFamily, category.iconCode)),

                    title: Text(category.name),

                    trailing: category.isDefault
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () {
                              deleteCategory(category);
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}
