import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/core/services/whatsapp_mapping_service.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
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
  List<Party> _allParties = [];
  List<Item> _allItems = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      _partyMappings = mappingService.getAllPartyMappings();
      _itemMappings = mappingService.getAllItemMappings();
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
                DropdownButtonFormField<Party?>(
                  value: selectedParty,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mapped ERP Customer Party',
                    border: OutlineInputBorder(),
                  ),
                  items: _allParties
                      .map((p) => DropdownMenuItem<Party?>(
                            value: p,
                            child: Text('${p.partyName ?? "Party"} (${p.mobileNumber ?? ""})'),
                          ))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedParty = val),
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

    Item? selectedItem = existing != null
        ? _allItems.firstWhereOrNull((i) => i.uuid == existing.itemUuid)
        : (_allItems.isNotEmpty ? _allItems.first : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Add Item Mapping Rule' : 'Edit Item Mapping Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rawItemCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Raw WhatsApp Item String',
                    hintText: 'e.g. Creamland Strawberry 5/ 144',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Item?>(
                  value: selectedItem,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mapped ERP Product',
                    border: OutlineInputBorder(),
                  ),
                  items: _allItems
                      .map((i) => DropdownMenuItem<Item?>(
                            value: i,
                            child: Text('${i.itemName ?? "Item"} (Default Rate: ₹${i.sellRate ?? 0})'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedItem = val;
                      if (val?.sellRate != null && rateCtrl.text == '0.00') {
                        rateCtrl.text = val!.sellRate!.toStringAsFixed(2);
                      }
                      if (val?.conversionFactor != null && cartonCtrl.text == '1') {
                        cartonCtrl.text = val!.conversionFactor!.toStringAsFixed(0);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bundleCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pcs / Bundle',
                          hintText: 'e.g. 12',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cartonCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pcs / Carton',
                          hintText: 'e.g. 144',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custom WhatsApp Sale Rate (₹)',
                    hintText: 'Override sell rate (0 = use ERP rate)',
                    border: OutlineInputBorder(),
                  ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Mapping Master', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF25D366),
          labelColor: const Color(0xFF25D366),
          tabs: [
            Tab(icon: const Icon(Icons.store_rounded), text: 'Party Mappings (${_partyMappings.length})'),
            Tab(icon: const Icon(Icons.inventory_2_rounded), text: 'Item Mappings (${_itemMappings.length})'),
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
                      hintText: 'Search raw string, shop name, product...',
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
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'Add Party Rule' : 'Add Item Rule'),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditPartyMappingDialog();
          } else {
            _showAddEditItemMappingDialog();
          }
        },
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
                            child: Text('Bundle: ${mapping.pcsPerBundle.toStringAsFixed(0)} pcs', style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('Carton: ${mapping.pcsPerCarton.toStringAsFixed(0)} pcs', style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('Rate: ₹${mapping.customRate.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
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
}
