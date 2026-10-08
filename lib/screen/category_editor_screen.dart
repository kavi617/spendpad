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

  /// True once the user hand-picks an icon — the choice then sticks and is
  /// honored everywhere in the app (stored with the "manual" icon family).
  bool _manualIcon = false;

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      nameController.text = widget.category!.name;
      selectedIcon = widget.category!.iconCode;
      _manualIcon = widget.category!.iconFamily == 'manual';
    } else {
      selectedIcon =
          (IconHelper.availableIcons.first['icon'] as IconData).codePoint;
    }

    nameController.addListener(_syncSuggestedIcon);
  }

  void _syncSuggestedIcon() {
    // Never fight a manual choice.
    if (_manualIcon) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final suggested = IconHelper.iconFor(name).codePoint;
    if (selectedIcon != suggested) {
      setState(() => selectedIcon = suggested);
    }
  }

  Future<void> saveCategory() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name required')),
      );
      return;
    }

    final category = Category(
      name: name,
      iconCode: selectedIcon,
      iconFamily: _manualIcon ? 'manual' : 'material',
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
    final scheme = Theme.of(context).colorScheme;
    final name = nameController.text.trim();
    final previewIcon = name.isEmpty
        ? Icons.category_rounded
        : IconHelper.iconFor(name);
    final previewColor =
        name.isEmpty ? scheme.onSurfaceVariant : IconHelper.colorFor(name);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: previewColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(previewIcon, color: previewColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Category name',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Icon — auto-picked from the name, tap to override',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: IconHelper.availableIcons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final icon =
                    IconHelper.availableIcons[index]['icon'] as IconData;
                final isSelected = selectedIcon == icon.codePoint;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _manualIcon = true;
                      selectedIcon = icon.codePoint;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.14)
                          : scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: saveCategory,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save category',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.removeListener(_syncSuggestedIcon);
    nameController.dispose();
    super.dispose();
  }
}
