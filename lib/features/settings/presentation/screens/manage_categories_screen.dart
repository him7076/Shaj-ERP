import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';

import 'package:business_sahaj_erp/features/expenses/presentation/widgets/expense_category_dialog.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  List<String> _partyTypes = [];
  List<String> _salesmen = [];
  List<String> _localities = [];
  List<String> _businessCategories = [];
  List<ExpenseCategoryItem> _expenseCategories = [];
  List<Unit> _units = [];

  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  final List<String> _defaultPartyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier'];
  final List<String> _defaultSalesmen = ['Default Salesman', 'Salesperson 1', 'Salesperson 2'];
  final List<String> _defaultLocalities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines'];
  final List<String> _defaultCategories = ['Retail', 'Wholesale', 'Contractor', 'Manufacturing', 'Services'];

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
  }
  Future<void> _loadAllCategories() async {
    setState(() => _isLoading = true);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;

      if (!prefs.containsKey('custom_party_types_list')) {
        await prefs.setStringList('custom_party_types_list', _defaultPartyTypes);
      }
      if (!prefs.containsKey('custom_salesmen_list')) {
        await prefs.setStringList('custom_salesmen_list', _defaultSalesmen);
      }
      if (!prefs.containsKey('custom_localities_list')) {
        await prefs.setStringList('custom_localities_list', _defaultLocalities);
      }
      if (!prefs.containsKey('party_business_categories')) {
        await prefs.setStringList('party_business_categories', _defaultCategories);
      }

      _partyTypes = prefs.getStringList('custom_party_types_list') ?? _defaultPartyTypes;
      _salesmen = prefs.getStringList('custom_salesmen_list') ?? _defaultSalesmen;
      _localities = prefs.getStringList('custom_localities_list') ?? _defaultLocalities;
      _businessCategories = prefs.getStringList('party_business_categories') ?? _defaultCategories;
      _expenseCategories = await ExpenseCategoryItem.getCategories(prefs);

      _units = await isar.units.filter().isDeletedEqualTo(false).findAll();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Preference List Handlers ---
  Future<void> _addPrefItem({
    required String title,
    required String labelText,
    required String prefKey,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Value is required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList(prefKey) ?? [];
      if (!list.contains(result)) {
        list.add(result);
        await prefs.setStringList(prefKey, list);
      }
      await _loadAllCategories();
    }
  }

  Future<void> _editPrefItem({
    required String title,
    required String oldItem,
    required String prefKey,
    required List<String> defaultItems,
  }) async {
    final controller = TextEditingController(text: oldItem);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Updated Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Value is required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != oldItem) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList(prefKey) ?? [];

      final index = list.indexOf(oldItem);
      if (index != -1) {
        list[index] = result;
      } else {
        list.add(result);
      }
      await prefs.setStringList(prefKey, list);
      await _loadAllCategories();
    }
  }

  Future<void> _deletePrefItem(String prefKey, String item, List<String> defaultItems) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$item"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList(prefKey) ?? [];
      list.remove(item);
      await prefs.setStringList(prefKey, list);
      await _loadAllCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories & Masters', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Category Management Center',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Configure party types, salesmen, units, localities, and business categories for your ERP.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('CATEGORIES & MASTER LISTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  // Menu Category Cards List
                  _buildCategoryMenuCard(
                    title: 'Party Types',
                    subtitle: 'Manage party roles (Customer, Wholesaler, Supplier, etc.)',
                    itemCount: _partyTypes.length,
                    icon: Icons.badge_rounded,
                    iconColor: const Color(0xFF673AB7),
                    iconBg: const Color(0xFFEDE7F6),
                    onTap: () => _openCategorySubScreen(
                      title: 'Manage Party Types',
                      items: _partyTypes,
                      defaultItems: _defaultPartyTypes,
                      prefKey: 'custom_party_types_list',
                      onAdd: () => _addPrefItem(title: 'Add Party Type', labelText: 'Party Type Name', prefKey: 'custom_party_types_list'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCategoryMenuCard(
                    title: 'Salesmen Directory',
                    subtitle: 'Manage sales representatives & track assigned transactions',
                    itemCount: _salesmen.length,
                    icon: Icons.person_pin_rounded,
                    iconColor: const Color(0xFF00897B),
                    iconBg: const Color(0xFFE0F2F1),
                    onTap: _openSalesmenSubScreen,
                  ),
                  const SizedBox(height: 12),

                  _buildCategoryMenuCard(
                    title: 'Measurement Units & Dual Units',
                    subtitle: 'Manage product measurement units (Pcs, Kg, Box, Ltr, etc.)',
                    itemCount: _units.length,
                    icon: Icons.square_foot_rounded,
                    iconColor: const Color(0xFFFB8C00),
                    iconBg: const Color(0xFFFFF3E0),
                    onTap: _openUnitsSubScreen,
                  ),
                  const SizedBox(height: 12),

                  _buildCategoryMenuCard(
                    title: 'Localities & Areas',
                    subtitle: 'Manage party location zones & market areas',
                    itemCount: _localities.length,
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFF1E88E5),
                    iconBg: const Color(0xFFE3F2FD),
                    onTap: () => _openCategorySubScreen(
                      title: 'Manage Localities & Areas',
                      items: _localities,
                      defaultItems: _defaultLocalities,
                      prefKey: 'custom_localities_list',
                      onAdd: () => _addPrefItem(title: 'Add Locality / Area', labelText: 'Locality Name', prefKey: 'custom_localities_list'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCategoryMenuCard(
                    title: 'Business Categories',
                    subtitle: 'Manage party industry sectors (Retail, Wholesale, Pharma, etc.)',
                    itemCount: _businessCategories.length,
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFFE91E63),
                    iconBg: const Color(0xFFFCE4EC),
                    onTap: () => _openCategorySubScreen(
                      title: 'Manage Business Categories',
                      items: _businessCategories,
                      defaultItems: _defaultCategories,
                      prefKey: 'party_business_categories',
                      onAdd: () => _addPrefItem(title: 'Add Business Category', labelText: 'Category Name', prefKey: 'party_business_categories'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCategoryMenuCard(
                    title: 'Expense Categories',
                    subtitle: 'Manage direct & indirect operational expense heads (Rent, Freight, Salaries, etc.)',
                    itemCount: _expenseCategories.length,
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFFD81B60),
                    iconBg: const Color(0xFFFCE4EC),
                    onTap: _openExpenseCategoriesSubScreen,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // --- Category Card Builder ---
  Widget _buildCategoryMenuCard({
    required String title,
    required String subtitle,
    required int itemCount,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: iconBg,
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$itemCount Items',
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  // --- Sub-Screen List View (With Edit & Delete buttons + FAB bottom padding) ---
  void _openCategorySubScreen({
    required String title,
    required List<String> items,
    required List<String> defaultItems,
    required String prefKey,
    required VoidCallback onAdd,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSubState) {
            return Scaffold(
              appBar: AppBar(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  onAdd();
                  await _loadAllCategories();
                  setSubState(() {});
                },
                icon: const Icon(Icons.add),
                label: Text('Add Item'),
              ),
              body: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90), // Prevent FAB overlap!
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isDefault = defaultItems.contains(item);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDefault ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                        child: Icon(isDefault ? Icons.star_border : Icons.category, color: isDefault ? Colors.blue : Colors.purple),
                      ),
                      title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(isDefault ? 'System Default Item' : 'Custom Category'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit Item',
                            onPressed: () async {
                              await _editPrefItem(title: 'Edit Item', oldItem: item, prefKey: prefKey, defaultItems: defaultItems);
                              setSubState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Item',
                            onPressed: () async {
                              await _deletePrefItem(prefKey, item, defaultItems);
                              setSubState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Salesmen Sub-Screen ---
  void _openSalesmenSubScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSubState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Manage Salesmen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await _addPrefItem(title: 'Add New Salesman', labelText: 'Salesman Name', prefKey: 'custom_salesmen_list');
                  setSubState(() {});
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Salesman'),
              ),
              body: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90), // Prevent FAB overlap!
                itemCount: _salesmen.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final salesman = _salesmen[index];
                  final isDefault = _defaultSalesmen.contains(salesman);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () => _openSalesmanDetailModal(salesman),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2F1),
                        child: Icon(Icons.person, color: Color(0xFF00897B)),
                      ),
                      title: Text(salesman, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text('Tap to view assigned orders & revenue performance'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, color: Colors.indigo),
                            tooltip: 'View Performance',
                            onPressed: () => _openSalesmanDetailModal(salesman),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit Salesman',
                            onPressed: () async {
                              await _editPrefItem(title: 'Edit Salesman Name', oldItem: salesman, prefKey: 'custom_salesmen_list', defaultItems: _defaultSalesmen);
                              setSubState(() {});
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: isDefault ? Colors.grey : Colors.red),
                            tooltip: isDefault ? 'Cannot delete default salesman' : 'Delete Salesman',
                            onPressed: isDefault
                                ? null
                                : () async {
                                    await _deletePrefItem('custom_salesmen_list', salesman, _defaultSalesmen);
                                    setSubState(() {});
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Units Sub-Screen ---
  void _openUnitsSubScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSubState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Manage Measurement Units', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  await _showAddUnitDialog();
                  setSubState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Unit'),
              ),
              body: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90), // Prevent FAB overlap!
                itemCount: _units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.square_foot, color: Colors.orange),
                      ),
                      title: Text('${unit.unitName ?? "Unit"} (${unit.shortName ?? ""})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('Short Symbol: ${unit.shortName ?? "N/A"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit Unit',
                            onPressed: () async {
                              await _showEditUnitDialog(unit);
                              setSubState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Unit',
                            onPressed: () async {
                              final isar = ref.read(databaseServiceProvider).isar;
                              final short = unit.shortName ?? '';
                              final usedItems = await isar.collection<Item>().filter().isDeletedEqualTo(false).and().group((q) => q.unit((u) => u.shortNameEqualTo(short))).findAll();

                              if (usedItems.isNotEmpty) {
                                final otherUnits = _units.where((u) => u.shortName != short && !u.isDeleted).toList();
                                String? replacementUnit = otherUnits.isNotEmpty ? otherUnits.first.shortName : null;

                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => StatefulBuilder(
                                    builder: (ctx, setDlgState) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Row(
                                        children: const [
                                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                          SizedBox(width: 10),
                                          Text('Unit Currently In Use!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Unit "$short" is used in ${usedItems.length} product item(s).'),
                                          const SizedBox(height: 12),
                                          const Text('Select a replacement unit to migrate existing records before deleting:'),
                                          const SizedBox(height: 10),
                                          DropdownButtonFormField<String>(
                                            value: replacementUnit,
                                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Replacement Unit'),
                                            items: otherUnits.map((u) => DropdownMenuItem(value: u.shortName, child: Text('${u.unitName ?? u.shortName} (${u.shortName})'))).toList(),
                                            onChanged: (val) => setDlgState(() => replacementUnit = val),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                                          child: const Text('Migrate & Delete Unit'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (proceed != true) return;
                                if (replacementUnit != null) {
                                  final newUnitObj = otherUnits.firstWhere((u) => u.shortName == replacementUnit);
                                  await isar.writeTxn(() async {
                                    for (var it in usedItems) {
                                      it.unit.value = newUnitObj;
                                      await isar.collection<Item>().put(it);
                                    }
                                  });
                                }
                              } else {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Unit'),
                                    content: Text('Are you sure you want to delete unit "${unit.unitName}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }

                              await isar.writeTxn(() async {
                                unit.isDeleted = true;
                                await isar.units.put(unit);
                              });
                              await _loadAllCategories();
                              setSubState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Add & Edit Unit Dialogs ---
  Future<void> _showAddUnitDialog() async {
    final nameController = TextEditingController();
    final shortController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Measurement Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Unit Full Name (e.g. Pieces, Kilograms)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortController,
              decoration: const InputDecoration(labelText: 'Short Symbol (e.g. Pcs, Kg)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (shortController.text.trim().isNotEmpty) {
                final isar = ref.read(databaseServiceProvider).isar;
                final unit = Unit()
                  ..uuid = DateTime.now().millisecondsSinceEpoch.toString()
                  ..unitName = nameController.text.trim().isEmpty ? shortController.text.trim() : nameController.text.trim()
                  ..shortName = shortController.text.trim()
                  ..isDeleted = false;

                await isar.writeTxn(() async {
                  await isar.units.put(unit);
                });
                Navigator.pop(ctx);
                await _loadAllCategories();
              }
            },
            child: const Text('Save Unit'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUnitDialog(Unit unit) async {
    final nameController = TextEditingController(text: unit.unitName);
    final shortController = TextEditingController(text: unit.shortName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Measurement Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Unit Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortController,
              decoration: const InputDecoration(labelText: 'Short Symbol', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (shortController.text.trim().isNotEmpty) {
                final isar = ref.read(databaseServiceProvider).isar;
                await isar.writeTxn(() async {
                  unit.unitName = nameController.text.trim();
                  unit.shortName = shortController.text.trim();
                  unit.updatedAt = DateTime.now();
                  await isar.units.put(unit);
                });
                Navigator.pop(ctx);
                await _loadAllCategories();
              }
            },
            child: const Text('Update Unit'),
          ),
        ],
      ),
    );
  }

  // --- Salesman Detailed Performance Modal ---
  void _openSalesmanDetailModal(String salesman) async {
    final isar = ref.read(databaseServiceProvider).isar;
    final orders = await isar.orders.filter().isDeletedEqualTo(false).and().createdByEqualTo(salesman).findAll();
    final invoices = await isar.invoices.filter().isDeletedEqualTo(false).and().createdByEqualTo(salesman).findAll();

    final double ordersVal = orders.fold(0.0, (sum, o) => sum + (o.grandTotal ?? 0.0));
    final double invoicesVal = invoices.fold(0.0, (sum, i) => sum + (i.grandTotal ?? 0.0));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salesman, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Assigned Orders: ${orders.length} | Invoices: ${invoices.length}', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orders Revenue', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(ordersVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoices Revenue', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(invoicesVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Assigned Transaction History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Expanded(
                child: (orders.isEmpty && invoices.isEmpty)
                    ? const Center(child: Text('No transactions recorded by this salesman yet.'))
                    : ListView(
                        children: [
                          ...orders.map((o) => ListTile(
                                leading: const Icon(Icons.shopping_cart, color: Colors.teal),
                                title: Text('Order #${o.orderNumber} - ${o.partyName ?? "Party"}'),
                                subtitle: Text('Date: ${o.orderDate != null ? DateFormat('dd-MM-yyyy').format(o.orderDate!) : "N/A"}'),
                                trailing: Text(currencyFormat.format(o.grandTotal ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold)),
                              )),
                          ...invoices.map((i) => ListTile(
                                leading: const Icon(Icons.receipt_long, color: Colors.purple),
                                title: Text('Invoice #${i.invoiceNumber} - ${i.partyName ?? "Party"}'),
                                subtitle: Text('Date: ${i.invoiceDate != null ? DateFormat('dd-MM-yyyy').format(i.invoiceDate!) : "N/A"}'),
                                trailing: Text(currencyFormat.format(i.grandTotal ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold)),
                              )),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Expense Categories Sub-Screen ---
  void _openExpenseCategoriesSubScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSubState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Manage Expense Categories', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  final newCat = await showDialog<ExpenseCategoryItem>(
                    context: context,
                    builder: (_) => const ExpenseCategoryDialog(),
                  );
                  if (newCat != null && newCat.name.isNotEmpty) {
                    final prefs = ref.read(sharedPreferencesProvider);
                    if (!_expenseCategories.any((c) => c.name.toLowerCase() == newCat.name.toLowerCase())) {
                      _expenseCategories.add(newCat);
                      await ExpenseCategoryItem.saveCategories(prefs, _expenseCategories);
                      await _loadAllCategories();
                      setSubState(() {});
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
              body: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                itemCount: _expenseCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cat = _expenseCategories[index];
                  final isDirect = cat.type == 'Direct Expense';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDirect ? Colors.orange.withOpacity(0.12) : Colors.indigo.withOpacity(0.12),
                        child: Icon(
                          isDirect ? Icons.inventory_2_outlined : Icons.receipt_long_outlined,
                          color: isDirect ? Colors.orange.shade800 : Colors.indigo,
                        ),
                      ),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDirect ? Colors.orange.withOpacity(0.15) : Colors.indigo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cat.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDirect ? Colors.orange.shade900 : Colors.indigo.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            tooltip: 'Edit Category',
                            onPressed: () async {
                              final updated = await showDialog<ExpenseCategoryItem>(
                                context: context,
                                builder: (_) => ExpenseCategoryDialog(initialCategory: cat),
                              );
                              if (updated != null && updated.name.isNotEmpty) {
                                final prefs = ref.read(sharedPreferencesProvider);
                                _expenseCategories[index] = updated;
                                await ExpenseCategoryItem.saveCategories(prefs, _expenseCategories);
                                await _loadAllCategories();
                                setSubState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Category',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete expense category "${cat.name}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final prefs = ref.read(sharedPreferencesProvider);
                                _expenseCategories.removeAt(index);
                                await ExpenseCategoryItem.saveCategories(prefs, _expenseCategories);
                                await _loadAllCategories();
                                setSubState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
