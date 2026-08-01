import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> _partyTypes = [];
  List<String> _salesmen = [];
  List<String> _localities = [];
  List<String> _businessCategories = [];
  List<Unit> _units = [];

  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCategories() async {
    setState(() => _isLoading = true);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;

      // 1. Party Types
      final customPT = prefs.getStringList('custom_party_types_list') ?? [];
      _partyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier', ...customPT].toSet().toList();

      // 2. Salesmen
      final customS = prefs.getStringList('custom_salesmen_list') ?? [];
      _salesmen = ['Default Salesman', 'Salesperson 1', 'Salesperson 2', ...customS].toSet().toList();

      // 3. Localities
      final customL = prefs.getStringList('custom_localities_list') ?? [];
      _localities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines', ...customL].toSet().toList();

      // 4. Business Categories
      final customBC = prefs.getStringList('party_business_categories') ?? [];
      _businessCategories = ['Retail', 'Wholesale', 'Contractor', 'Manufacturing', 'Services', ...customBC].toSet().toList();

      // 5. Units
      _units = await isar.units.filter().isDeletedEqualTo(false).findAll();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Category Handlers ---
  Future<void> _addOrEditItemDialog({
    required String title,
    required String labelText,
    String? initialValue,
    required Function(String text) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await onSave(result);
      await _loadAllCategories();
    }
  }

  Future<void> _deletePrefItem(String prefKey, String item, List<String> defaultItems) async {
    if (defaultItems.contains(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete system default item "$item".')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
        title: const Text('Manage Categories & Master Lists'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'Party Types'),
            Tab(icon: Icon(Icons.person_pin), text: 'Salesmen'),
            Tab(icon: Icon(Icons.square_foot), text: 'Units & Dual Units'),
            Tab(icon: Icon(Icons.location_city), text: 'Localities & Areas'),
            Tab(icon: Icon(Icons.category), text: 'Business Categories'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSimpleCategoryTab(
                  title: 'Party Types',
                  items: _partyTypes,
                  defaultItems: ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier'],
                  prefKey: 'custom_party_types_list',
                  onAdd: () => _addOrEditItemDialog(
                    title: 'Add Party Type',
                    labelText: 'Party Type Name',
                    onSave: (text) async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      final list = prefs.getStringList('custom_party_types_list') ?? [];
                      if (!list.contains(text)) list.add(text);
                      await prefs.setStringList('custom_party_types_list', list);
                    },
                  ),
                ),
                _buildSalesmenTab(),
                _buildUnitsTab(),
                _buildSimpleCategoryTab(
                  title: 'Localities / Areas',
                  items: _localities,
                  defaultItems: ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines'],
                  prefKey: 'custom_localities_list',
                  onAdd: () => _addOrEditItemDialog(
                    title: 'Add Locality / Area',
                    labelText: 'Locality Name',
                    onSave: (text) async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      final list = prefs.getStringList('custom_localities_list') ?? [];
                      if (!list.contains(text)) list.add(text);
                      await prefs.setStringList('custom_localities_list', list);
                    },
                  ),
                ),
                _buildSimpleCategoryTab(
                  title: 'Business Categories',
                  items: _businessCategories,
                  defaultItems: ['Retail', 'Wholesale', 'Contractor', 'Manufacturing', 'Services'],
                  prefKey: 'party_business_categories',
                  onAdd: () => _addOrEditItemDialog(
                    title: 'Add Business Category',
                    labelText: 'Category Name',
                    onSave: (text) async {
                      final prefs = ref.read(sharedPreferencesProvider);
                      final list = prefs.getStringList('party_business_categories') ?? [];
                      if (!list.contains(text)) list.add(text);
                      await prefs.setStringList('party_business_categories', list);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // --- 1. Generic Simple Category Tab ---
  Widget _buildSimpleCategoryTab({
    required String title,
    required List<String> items,
    required List<String> defaultItems,
    required String prefKey,
    required VoidCallback onAdd,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text('Add $title'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isDefault = defaultItems.contains(item);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDefault ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                child: Icon(isDefault ? Icons.lock_outline : Icons.category, color: isDefault ? Colors.blue : Colors.green),
              ),
              title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isDefault ? 'System Default Category' : 'Custom Added'),
              trailing: isDefault
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletePrefItem(prefKey, item, defaultItems),
                    ),
            ),
          );
        },
      ),
    );
  }

  // --- 2. Salesmen Tab with Detailed View ---
  Widget _buildSalesmenTab() {
    final defaultSalesmen = ['Default Salesman', 'Salesperson 1', 'Salesperson 2'];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditItemDialog(
          title: 'Add New Salesman',
          labelText: 'Salesman Name',
          onSave: (text) async {
            final prefs = ref.read(sharedPreferencesProvider);
            final list = prefs.getStringList('custom_salesmen_list') ?? [];
            if (!list.contains(text)) list.add(text);
            await prefs.setStringList('custom_salesmen_list', list);
          },
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Salesman'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _salesmen.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final salesman = _salesmen[index];
          final isDefault = defaultSalesmen.contains(salesman);

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: ListTile(
              onTap: () => _openSalesmanDetailModal(salesman),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8EAF6),
                child: Icon(Icons.person, color: Colors.indigo),
              ),
              title: Text(salesman, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tap to view assigned transactions & performance'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: Colors.indigo),
                    onPressed: () => _openSalesmanDetailModal(salesman),
                  ),
                  if (!isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deletePrefItem('custom_salesmen_list', salesman, defaultSalesmen),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 3. Salesman Detailed Modal ---
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orders Value', style: TextStyle(fontSize: 12, color: Colors.blue)),
                          Text(currencyFormat.format(ordersVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoices Value', style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text(currencyFormat.format(invoicesVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Transaction Activity History:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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

  // --- 4. Units & Dual Units Tab ---
  Widget _buildUnitsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUnitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _units.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final unit = _units[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.square_foot, color: Colors.orange),
              ),
              title: Text('${unit.unitName ?? "Unit"} (${unit.shortName ?? ""})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Symbol: ${unit.shortName ?? "N/A"}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final isar = ref.read(databaseServiceProvider).isar;
                  await isar.writeTxn(() async {
                    unit.isDeleted = true;
                    await isar.units.put(unit);
                  });
                  _loadAllCategories();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddUnitDialog() async {
    final nameController = TextEditingController();
    final shortController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Measurement Unit'),
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
              decoration: const InputDecoration(labelText: 'Short Name / Symbol (e.g. Pcs, Kg)', border: OutlineInputBorder()),
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
                _loadAllCategories();
              }
            },
            child: const Text('Save Unit'),
          ),
        ],
      ),
    );
  }
}
