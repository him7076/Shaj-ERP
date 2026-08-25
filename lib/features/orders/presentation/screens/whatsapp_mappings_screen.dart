import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/core/services/whatsapp_mapping_service.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/user_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

class WhatsAppMappingsScreen extends ConsumerStatefulWidget {
  const WhatsAppMappingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WhatsAppMappingsScreen> createState() => _WhatsAppMappingsScreenState();
}

class _WhatsAppMappingsScreenState extends ConsumerState<WhatsAppMappingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<WhatsAppPartyMapping> _partyMappings = [];
  List<WhatsAppItemMapping> _itemMappings = [];
  List<WhatsAppSalesmanMapping> _salesmanMappings = [];
  List<Party> _allParties = [];
  List<Item> _allItems = [];
  List<User> _allSalesmen = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadMappingsAndMasters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMappingsAndMasters() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(isarProvider);
      final mappingService = ref.read(whatsappMappingServiceProvider);

      _allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      _allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();
      _allSalesmen = await isar.users.filter().roleEqualTo('Salesman').isDeletedEqualTo(false).findAll();

      _partyMappings = mappingService.getAllPartyMappings();
      _itemMappings = mappingService.getAllItemMappings();
      _salesmanMappings = mappingService.getAllSalesmanMappings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading mappings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditPartyMappingDialog([WhatsAppPartyMapping? existing]) {
    final rawShopCtrl = TextEditingController(text: existing?.rawShopName ?? '');
    Party? selectedParty = existing != null
        ? _allParties.firstWhereOrNull((p) => p.uuid == existing.partyUuid)
        : (_allParties.isNotEmpty ? _allParties.first : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Party Mapping Rule' : 'Edit Party Mapping Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: rawShopCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Raw WhatsApp Shop Name',
                    hintText: 'e.g. Shri Krishna Traders',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Mapped ERP Customer Party:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Autocomplete<Party>(
                  initialValue: TextEditingValue(text: selectedParty?.partyName ?? ''),
                  displayStringForOption: (Party p) => '${p.partyName ?? "Party"} (${p.mobileNumber ?? "No Mob"})',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _allParties;
                    final q = textEditingValue.text.toLowerCase();
                    return _allParties.where((p) =>
                        (p.partyName ?? '').toLowerCase().contains(q) ||
                        (p.mobileNumber ?? '').contains(q));
                  },
                  onSelected: (Party selection) {
                    setModalState(() => selectedParty = selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search ERP Customer Party',
                        hintText: 'Type name or mobile to filter...',
                        suffixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              onPressed: () async {
                final raw = rawShopCtrl.text.trim();
                if (raw.isEmpty || selectedParty == null) return;

                final mappingService = ref.read(whatsappMappingServiceProvider);
                await mappingService.savePartyMapping(raw, selectedParty!.uuid!);

                Navigator.pop(ctx);
                _loadMappingsAndMasters();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Party mapping for "$raw" saved!')),
                );
              },
              child: const Text('Save Mapping'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditItemMappingDialog([WhatsAppItemMapping? existing]) {
    final rawItemCtrl = TextEditingController(text: existing?.rawItemLine ?? '');
    final bundleCtrl = TextEditingController(text: (existing?.pcsPerBundle ?? 1.0).toStringAsFixed(0));
    final cartonCtrl = TextEditingController(text: (existing?.pcsPerCarton ?? 1.0).toStringAsFixed(0));
    final rateCtrl = TextEditingController(text: (existing?.customRate ?? 0.0).toStringAsFixed(2));
    String selectedRateUnit = existing?.rateUnit ?? 'Carton';
    bool isTaxInclusive = existing?.isTaxInclusive ?? false;

    Item? selectedItem = existing != null
        ? _allItems.firstWhereOrNull((i) => i.uuid == existing.itemUuid)
        : (_allItems.isNotEmpty ? _allItems.first : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableUnits = <String>[
            selectedItem?.primaryUnitName ?? 'Carton',
            selectedItem?.secondaryUnit ?? 'Bundle',
            'PCS',
          ].where((u) => u.trim().isNotEmpty).toSet().toList();

          if (!availableUnits.contains(selectedRateUnit)) {
            selectedRateUnit = availableUnits.first;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing == null ? 'Add Item Mapping Rule' : 'Edit Item Mapping Rule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: rawItemCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Raw WhatsApp Item String',
                      hintText: 'e.g. Creamland Strawberry 5/ 144',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Mapped ERP Product:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Autocomplete<Item>(
                    initialValue: TextEditingValue(text: selectedItem?.itemName ?? ''),
                    displayStringForOption: (Item i) => '${i.itemName ?? "Item"} (Rate: ₹${i.sellRate ?? 0})',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _allItems;
                      final q = textEditingValue.text.toLowerCase();
                      return _allItems.where((i) => (i.itemName ?? '').toLowerCase().contains(q));
                    },
                    onSelected: (Item selection) {
                      setModalState(() {
                        selectedItem = selection;
                        if (selection.sellRate != null && rateCtrl.text == '0.00') {
                          rateCtrl.text = selection.sellRate!.toStringAsFixed(2);
                        }
                        if (selection.conversionFactor != null && cartonCtrl.text == '1') {
                          cartonCtrl.text = selection.conversionFactor!.toStringAsFixed(0);
                        }
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search ERP Product',
                          hintText: 'Type product name to filter...',
                          suffixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bundleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pcs / ${selectedItem?.secondaryUnit ?? "Bundle"}',
                            hintText: 'e.g. 12',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: cartonCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pcs / ${selectedItem?.primaryUnitName ?? "Carton"}',
                            hintText: 'e.g. 144',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Custom Sale Rate (₹)',
                            hintText: 'Override sell rate',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRateUnit,
                          decoration: const InputDecoration(
                            labelText: 'Rate Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: availableUnits
                              .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedRateUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<bool>(
                    value: isTaxInclusive,
                    decoration: const InputDecoration(
                      labelText: 'Tax Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Without Tax (Exclusive of GST)')),
                      DropdownMenuItem(value: true, child: Text('With Tax (Inclusive of GST)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => isTaxInclusive = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                onPressed: () async {
                  final raw = rawItemCtrl.text.trim();
                  if (raw.isEmpty || selectedItem == null) return;

                  final mapping = WhatsAppItemMapping(
                    rawItemLine: raw,
                    itemUuid: selectedItem!.uuid!,
                    pcsPerBundle: double.tryParse(bundleCtrl.text) ?? 1.0,
                    pcsPerCarton: double.tryParse(cartonCtrl.text) ?? 1.0,
                    customRate: double.tryParse(rateCtrl.text) ?? 0.0,
                    rateUnit: selectedRateUnit,
                    isTaxInclusive: isTaxInclusive,
                  );

                  final mappingService = ref.read(whatsappMappingServiceProvider);
                  await mappingService.saveItemMapping(mapping);

                  Navigator.pop(ctx);
                  _loadMappingsAndMasters();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item mapping for "$raw" saved!')),
                  );
                },
                child: const Text('Save Mapping'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEditSalesmanMappingDialog([WhatsAppSalesmanMapping? existing]) {
    final rawSalesmanCtrl = TextEditingController(text: existing?.rawSalesmanName ?? '');
    
    User? selectedTarget = existing != null
        ? _allSalesmen.firstWhereOrNull((u) => u.name?.toLowerCase() == existing.targetSalesmanName.toLowerCase())
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Salesman Mapping Rule' : 'Edit Salesman Mapping Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: rawSalesmanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Raw WhatsApp Sales Rep Name',
                    hintText: 'e.g. Rahul or Rahul Salesman',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Mapped ERP Salesman:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Autocomplete<User>(
                  initialValue: TextEditingValue(text: existing?.targetSalesmanName ?? ''),
                  displayStringForOption: (User u) => u.name ?? "Salesman",
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _allSalesmen;
                    final q = textEditingValue.text.toLowerCase();
                    return _allSalesmen.where((u) => (u.name ?? '').toLowerCase().contains(q));
                  },
                  onSelected: (User selection) {
                    setModalState(() => selectedTarget = selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search ERP Salesman',
                        hintText: 'Type salesman name to filter...',
                        suffixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              onPressed: () async {
                final raw = rawSalesmanCtrl.text.trim();
                final target = selectedTarget?.name?.trim();
                if (raw.isEmpty || target == null || target.isEmpty) return;
  
                final mappingService = ref.read(whatsappMappingServiceProvider);
                await mappingService.saveSalesmanMapping(raw, target);
  
                Navigator.pop(ctx);
                _loadMappingsAndMasters();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Salesman mapping for "$raw" saved!')),
                );
              },
              child: const Text('Save Mapping'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredParties = _partyMappings.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final party = _allParties.firstWhereOrNull((x) => x.uuid == p.partyUuid);
      return p.rawShopName.toLowerCase().contains(q) || (party?.partyName?.toLowerCase().contains(q) ?? false);
    }).toList();

    final filteredItems = _itemMappings.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final item = _allItems.firstWhereOrNull((x) => x.uuid == i.itemUuid);
      return i.rawItemLine.toLowerCase().contains(q) || (item?.itemName?.toLowerCase().contains(q) ?? false);
    }).toList();

    final filteredSalesmen = _salesmanMappings.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.rawSalesmanName.toLowerCase().contains(q) || s.targetSalesmanName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('WhatsApp Mapping Master', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF25D366),
          labelColor: const Color(0xFF25D366),
          tabs: [
            Tab(icon: const Icon(Icons.store_rounded), text: 'Party (${_partyMappings.length})'),
            Tab(icon: const Icon(Icons.inventory_2_rounded), text: 'Item (${_itemMappings.length})'),
            Tab(icon: const Icon(Icons.badge_rounded), text: 'Salesman (${_salesmanMappings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search raw string, shop name, product, salesman...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Party Mappings
                      _buildPartyMappingsTab(filteredParties, theme),

                      // Tab 2: Item Mappings
                      _buildItemMappingsTab(filteredItems, theme),

                      // Tab 3: Salesman Mappings
                      _buildSalesmanMappingsTab(filteredSalesmen, theme),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(_tabController.index == 0
              ? 'Add Party Rule'
              : _tabController.index == 1
                  ? 'Add Item Rule'
                  : 'Add Salesman Rule', style: const TextStyle(fontSize: 13)),
          onPressed: () {
            if (_tabController.index == 0) {
              _showAddEditPartyMappingDialog();
            } else if (_tabController.index == 1) {
              _showAddEditItemMappingDialog();
            } else {
              _showAddEditSalesmanMappingDialog();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPartyMappingsTab(List<WhatsAppPartyMapping> list, ThemeData theme) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No saved WhatsApp party mappings found.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Party Mapping Rule'),
              onPressed: () => _showAddEditPartyMappingDialog(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final mapping = list[index];
        final party = _allParties.firstWhereOrNull((p) => p.uuid == mapping.partyUuid);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1F25D366),
              child: Icon(Icons.store_rounded, color: Color(0xFF25D366)),
            ),
            title: Text(mapping.rawShopName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Mapped ERP Party: ${party?.partyName ?? "Unknown / Deleted"} (${party?.mobileNumber ?? "No Mob"})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showAddEditPartyMappingDialog(mapping),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final mappingService = ref.read(whatsappMappingServiceProvider);
                    await mappingService.deletePartyMapping(mapping.rawShopName);
                    _loadMappingsAndMasters();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemMappingsTab(List<WhatsAppItemMapping> list, ThemeData theme) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No saved WhatsApp item mappings found.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Item Mapping Rule'),
              onPressed: () => _showAddEditItemMappingDialog(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final mapping = list[index];
        final item = _allItems.firstWhereOrNull((i) => i.uuid == mapping.itemUuid);

        final secUnit = item?.secondaryUnit ?? "Bundle";
        final primUnit = item?.primaryUnitName ?? "Carton";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0x1F25D366),
                  child: Icon(Icons.inventory_2_rounded, color: Color(0xFF25D366)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mapping.rawItemLine, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('ERP Item: ${item?.itemName ?? "Unknown Item"}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('$secUnit: ${mapping.pcsPerBundle.toStringAsFixed(0)} pcs', style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('$primUnit: ${mapping.pcsPerCarton.toStringAsFixed(0)} pcs', style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('Rate: ₹${mapping.customRate.toStringAsFixed(2)} / ${mapping.rateUnit ?? primUnit}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: mapping.isTaxInclusive ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(mapping.isTaxInclusive ? 'With Tax (Incl)' : 'Without Tax (Excl)', style: TextStyle(fontSize: 10, color: mapping.isTaxInclusive ? Colors.orange.shade800 : Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showAddEditItemMappingDialog(mapping),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final mappingService = ref.read(whatsappMappingServiceProvider);
                    await mappingService.deleteItemMapping(mapping.rawItemLine);
                    _loadMappingsAndMasters();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesmanMappingsTab(List<WhatsAppSalesmanMapping> list, ThemeData theme) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No saved WhatsApp salesman mappings found.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Salesman Mapping Rule'),
              onPressed: () => _showAddEditSalesmanMappingDialog(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final mapping = list[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1F25D366),
              child: Icon(Icons.badge_rounded, color: Color(0xFF25D366)),
            ),
            title: Text(mapping.rawSalesmanName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Mapped ERP Salesman: ${mapping.targetSalesmanName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showAddEditSalesmanMappingDialog(mapping),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final mappingService = ref.read(whatsappMappingServiceProvider);
                    await mappingService.deleteSalesmanMapping(mapping.rawSalesmanName);
                    _loadMappingsAndMasters();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
