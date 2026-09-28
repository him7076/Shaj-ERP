import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_item_dropdown.dart';

class FullScreenItemEntryData {
  final Item item;
  final double quantity;
  final double rate;
  final double discountAmount;
  final double gstRate;

  FullScreenItemEntryData({
    required this.item,
    required this.quantity,
    required this.rate,
    required this.discountAmount,
    required this.gstRate,
  });
}

class FullScreenItemEntry extends ConsumerStatefulWidget {
  final bool isPurchase;
  final bool isFixedAsset;
  final bool onlyBundles;
  final bool excludeBundles;
  final Function(FullScreenItemEntryData) onAdd;

  const FullScreenItemEntry({
    Key? key,
    this.isPurchase = false,
    this.isFixedAsset = false,
    this.onlyBundles = false,
    this.excludeBundles = false,
    required this.onAdd,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {bool isPurchase = false, bool isFixedAsset = false, bool onlyBundles = false, bool excludeBundles = false, required Function(FullScreenItemEntryData) onAdd}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenItemEntry(isPurchase: isPurchase, isFixedAsset: isFixedAsset, onlyBundles: onlyBundles, excludeBundles: excludeBundles, onAdd: onAdd),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<FullScreenItemEntry> createState() => _FullScreenItemEntryState();
}

class _FullScreenItemEntryState extends ConsumerState<FullScreenItemEntry> {
  Item? _selectedItem;
  final TextEditingController _qtyController = TextEditingController(text: '1.0');
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _gstController = TextEditingController(text: '18.0');

  final FocusNode _qtyFocus = FocusNode();
  int _resetKey = 0;

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _gstController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  void _onItemSelect(Item item) {
    setState(() {
      _selectedItem = item;
      _rateController.text = (widget.isPurchase ? (item.buyRate ?? item.sellRate ?? 0.0) : (item.sellRate ?? 0.0)).toString();
      _gstController.text = (item.gstRate ?? 18.0).toString();
    });
    FocusScope.of(context).requestFocus(_qtyFocus);
  }

  void _save() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an item first.')));
      return;
    }
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 18.0;

    widget.onAdd(
      FullScreenItemEntryData(
        item: _selectedItem!,
        quantity: qty,
        rate: rate,
        discountAmount: discount,
        gstRate: gst,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedItem!.itemName} added!')));
    
    setState(() {
      _selectedItem = null;
      _qtyController.text = '1.0';
      _rateController.clear();
      _discountController.text = '0.0';
      _gstController.text = '18.0';
      _resetKey++;
    });
    FocusScope.of(context).requestFocus(); // Reset focus to the dropdown if possible
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFixedAsset ? 'Add Fixed Asset' : 'Add Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (allItems) {
          final items = allItems.where((i) {
            if (widget.isFixedAsset) {
              return i.category.value?.categoryName == 'Fixed Assets';
            }
            if (widget.onlyBundles && !i.isBundle) return false;
            if (widget.excludeBundles && i.isBundle) return false;
            return i.category.value?.categoryName != 'Fixed Assets';
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchableItemDropdown(
                  isFixedAsset: widget.isFixedAsset,
                  autofocus: true,
                  key: ValueKey(_resetKey),
                  items: items,
                  labelText: widget.isFixedAsset ? 'Search or add Fixed Asset...' : 'Search or add Product...',
                  onSelected: _onItemSelect,
                ),
                const SizedBox(height: 24),
                if (_selectedItem != null) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Selected: ${_selectedItem!.itemName}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qtyController,
                                  focusNode: _qtyFocus,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _rateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Rate', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _discountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Discount Amt', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _gstController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _cancel,
                          child: const Text('CANCEL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _save,
                          child: const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

