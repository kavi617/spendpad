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
    data.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    setState(() => categories = data);
  }

  Future<void> deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text(
          'Existing expenses in this category will be moved to Other.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await CategoryService.deleteCategory(category);
    loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryEditorScreen()),
          );
          if (result == true) loadCategories();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(
                'No categories yet',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final accent = IconHelper.colorFor(category.name);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        IconHelper.iconFor(category.name),
                        color: accent,
                        size: 21,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      category.isDefault ? 'Default' : 'Custom',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryEditorScreen(category: category),
                              ),
                            );
                            if (result == true) loadCategories();
                          },
                        ),
                        if (!category.isDefault)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Color(0xFFE5533C),
                            ),
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
