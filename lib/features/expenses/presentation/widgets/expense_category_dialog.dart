import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';

class ExpenseCategoryItem {
  final String name;
  final String type; // 'Indirect Expense' or 'Direct Expense'

  ExpenseCategoryItem({
    required this.name,
    this.type = 'Indirect Expense',
  });

  Map<String, dynamic> toJson() => {'name': name, 'type': type};

  factory ExpenseCategoryItem.fromJson(Map<String, dynamic> json) => ExpenseCategoryItem(
        name: json['name'] ?? '',
        type: json['type'] ?? 'Indirect Expense',
      );

  static final List<ExpenseCategoryItem> defaultCategories = [
    ExpenseCategoryItem(name: 'Rent', type: 'Indirect Expense'),
    ExpenseCategoryItem(name: 'Salaries', type: 'Indirect Expense'),
    ExpenseCategoryItem(name: 'Utilities', type: 'Indirect Expense'),
    ExpenseCategoryItem(name: 'Tea & Snacks', type: 'Indirect Expense'),
    ExpenseCategoryItem(name: 'Office Expense', type: 'Indirect Expense'),
    ExpenseCategoryItem(name: 'Freight & Carriage', type: 'Direct Expense'),
    ExpenseCategoryItem(name: 'Raw Material Transport', type: 'Direct Expense'),
    ExpenseCategoryItem(name: 'Other Expense', type: 'Indirect Expense'),
  ];

  static Future<List<ExpenseCategoryItem>> getCategories(SharedPreferences prefs) async {
    final rawList = prefs.getStringList('custom_expense_categories_v2');
    if (rawList == null || rawList.isEmpty) {
      // Seed default categories if not present
      await saveCategories(prefs, defaultCategories);
      return defaultCategories;
    }
    try {
      return rawList.map((str) => ExpenseCategoryItem.fromJson(jsonDecode(str))).toList();
    } catch (_) {
      return defaultCategories;
    }
  }

  static Future<void> saveCategories(SharedPreferences prefs, List<ExpenseCategoryItem> categories, [Isar? isar]) async {
    final rawList = categories.map((cat) => jsonEncode(cat.toJson())).toList();
    await prefs.setStringList('custom_expense_categories_v2', rawList);

    // Also update legacy string list for backward compatibility
    final legacyList = categories.map((cat) => cat.name).toList();
    await prefs.setStringList('expense_categories', legacyList);

    // Sync categories into Isar Category collection if Isar is available
    if (isar != null) {
      try {
        await isar.writeTxn(() async {
          for (var cat in categories) {
            final existing = await isar.categorys.filter().categoryNameEqualTo(cat.name).findFirst();
            if (existing == null) {
              final newCat = Category()
                ..uuid = 'cat_${DateTime.now().millisecondsSinceEpoch}_${cat.name.hashCode}'
                ..categoryName = cat.name
                ..description = cat.type
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();
              await isar.categorys.put(newCat);
            }
          }
        });
      } catch (_) {}
    }
  }
}

/// 2-Input Dialog for Adding / Editing Expense Categories
class ExpenseCategoryDialog extends StatefulWidget {
  final ExpenseCategoryItem? initialCategory;
  const ExpenseCategoryDialog({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<ExpenseCategoryDialog> createState() => _ExpenseCategoryDialogState();
}

class _ExpenseCategoryDialogState extends State<ExpenseCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    _selectedType = widget.initialCategory?.type ?? 'Indirect Expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.initialCategory != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Expense Category' : 'Add Expense Category',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input 1: Category Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. Office Rent, Freight, Refreshments',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input 2: Expense Type Selection (Indirect Expense vs Direct Expense)
              const Text(
                'Expense Type *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Indirect Expense'),
                      selected: _selectedType == 'Indirect Expense',
                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'Indirect Expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Direct Expense'),
                      selected: _selectedType == 'Direct Expense',
                      selectedColor: Colors.orange.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'Direct Expense');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _selectedType == 'Direct Expense'
                    ? '• Direct Expenses are directly related to production/goods (e.g., Freight, Factory Power).'
                    : '• Indirect Expenses are general overheads (e.g., Office Rent, Salaries, Stationery).',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = ExpenseCategoryItem(
                name: _nameController.text.trim(),
                type: _selectedType,
              );
              Navigator.pop(context, result);
            }
          },
          child: Text(isEdit ? 'Update' : 'Save Category'),
        ),
      ],
    );
  }
}
