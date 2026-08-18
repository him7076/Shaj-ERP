import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/core/utils/whatsapp_order_parser.dart';
import 'package:business_sahaj_erp/core/services/whatsapp_mapping_service.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';

class _MappedRowState {
  final ParsedWhatsappOrderItem rawParsedItem;
  Item? selectedItem;
  bool isSecondaryUnit;
  double quantity;
  double rate;

  _MappedRowState({
    required this.rawParsedItem,
    this.selectedItem,
    this.isSecondaryUnit = false,
    required this.quantity,
    required this.rate,
  });

  double get subtotal => quantity * rate;
}

class WhatsappOrderImporterScreen extends ConsumerStatefulWidget {
  const WhatsappOrderImporterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WhatsappOrderImporterScreen> createState() => _WhatsappOrderImporterScreenState();
}

class _WhatsappOrderImporterScreenState extends ConsumerState<WhatsappOrderImporterScreen> {
  final TextEditingController _textController = TextEditingController();

  ParsedWhatsappOrder? _parsedOrder;
  Party? _selectedParty;
  List<Party> _allParties = [];
  List<Item> _allItems = [];
  List<_MappedRowState> _mappedRows = [];

  bool _rememberMappings = true;
  bool _isLoading = false;
  bool _isParsing = false;

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static const String _sampleMessage = '''Shop: Shri Krishna Traders
Mob No: 9876543210
Order Id: WA-8812
SalesRep: Rahul Sharma
Date: 18-08-2026

Items:
1. Creamland Strawberry 5/ 144 (Quantity: 144)
2. Amul Butter 100g (Quantity: 50)
3. Parle-G 100g (Quantity: 100)

Amount: 2630.00
Location: https://maps.google.com/?q=23.1815,75.7860''';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _parseMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a WhatsApp order message first.')),
      );
      return;
    }

    setState(() => _isParsing = true);
    try {
      final isar = ref.read(isarProvider);
      _allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      _allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      final parsed = WhatsappOrderParser.parse(text);
      final mappingService = ref.read(whatsappMappingServiceProvider);

      final matchedParty = await mappingService.matchParty(
        shopName: parsed.shopName,
        mobileNumber: parsed.mobileNumber,
      );

      final mappedRows = <_MappedRowState>[];
      for (var parsedItem in parsed.items) {
        final matchedItem = await mappingService.matchItem(parsedItem.itemDescription);
        final rate = matchedItem?.sellRate ?? 0.0;

        mappedRows.add(_MappedRowState(
          rawParsedItem: parsedItem,
          selectedItem: matchedItem,
          isSecondaryUnit: false,
          quantity: parsedItem.quantity.toDouble(),
          rate: rate,
        ));
      }

      setState(() {
        _parsedOrder = parsed;
        _selectedParty = matchedParty;
        _mappedRows = mappedRows;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parsing error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  void _showCreatePartyDialog() {
    final nameCtrl = TextEditingController(text: _parsedOrder?.shopName ?? '');
    final mobCtrl = TextEditingController(text: _parsedOrder?.mobileNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create Customer Party', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Party / Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final isar = ref.read(isarProvider);
              final newParty = Party()
                ..uuid = const Uuid().v4()
                ..partyName = name
                ..mobileNumber = mobCtrl.text.trim()
                ..partyType = 'Customer'
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                await isar.partys.put(newParty);
              });

              Navigator.pop(ctx);
              final updatedList = await isar.partys.filter().isDeletedEqualTo(false).findAll();
              setState(() {
                _allParties = updatedList;
                _selectedParty = newParty;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Party "$name" created successfully!')),
              );
            },
            child: const Text('Create Party'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAndCreateOrder() async {
    if (_parsedOrder == null || _mappedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No order parsed yet.')),
      );
      return;
    }

    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a Customer Party first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final mappingService = ref.read(whatsappMappingServiceProvider);

      final nextOrderNumber = await orderRepo.generateNextOrderNumber();

      double subtotal = 0.0;
      final orderItems = <OrderItem>[];

      for (var row in _mappedRows) {
        if (row.selectedItem == null) continue;
        final item = row.selectedItem!;

        final unitName = row.isSecondaryUnit
            ? (item.secondaryUnitName ?? 'PCS')
            : (item.primaryUnitName ?? item.unit.value?.shortName ?? 'PCS');

        final lineTotal = row.subtotal;
        subtotal += lineTotal;

        final orderItem = OrderItem()
          ..uuid = const Uuid().v4()
          ..itemId = item.id
          ..itemName = item.itemName
          ..hsnCode = item.hsnCode
          ..quantity = row.quantity
          ..freeQuantity = 0.0
          ..unit = unitName
          ..rate = row.rate
          ..discountPercent = 0.0
          ..discountAmount = 0.0
          ..taxableAmount = lineTotal
          ..gstPercent = item.gstRate ?? 0.0
          ..gstAmount = 0.0
          ..totalAmount = lineTotal
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        orderItems.add(orderItem);

        if (_rememberMappings) {
          await mappingService.saveItemMapping(row.rawParsedItem.itemDescription, item.uuid!);
        }
      }

      if (_rememberMappings && _parsedOrder?.shopName != null) {
        await mappingService.savePartyMapping(_parsedOrder!.shopName!, _selectedParty!.uuid!);
      }

      final order = Order()
        ..uuid = const Uuid().v4()
        ..orderNumber = nextOrderNumber
        ..orderDate = DateTime.now()
        ..status = 'Pending'
        ..partyId = _selectedParty!.id
        ..partyName = _selectedParty!.partyName
        ..mobileNumber = _selectedParty!.mobileNumber
        ..gstNumber = _selectedParty!.gstNumber
        ..latitude = _parsedOrder?.latitude
        ..longitude = _parsedOrder?.longitude
        ..remarks = 'WhatsApp Order ID: ${_parsedOrder?.orderId ?? "N/A"} | WhatsApp Rep: ${_parsedOrder?.salesRep ?? "N/A"}'
        ..createdBy = _parsedOrder?.salesRep ?? 'WhatsApp Importer'
        ..subtotal = subtotal
        ..discountAmount = 0.0
        ..discountPercent = 0.0
        ..totalGST = 0.0
        ..roundOff = 0.0
        ..grandTotal = subtotal
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      order.party.value = _selectedParty;

      await orderRepo.saveOrder(order, orderItems);

      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      ref.invalidate(filteredOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sales Order ${order.orderNumber} created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderUuid: order.uuid!),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating sales order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double computedErpTotal = 0.0;
    for (var r in _mappedRows) {
      computedErpTotal += r.subtotal;
    }

    final double whatsappTotal = _parsedOrder?.messageAmount ?? 0.0;
    final bool isVerifiedMatch = whatsappTotal <= 0 || (whatsappTotal - computedErpTotal).abs() < 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('WhatsApp Order Importer', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Text Input Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PASTE RAW WHATSAPP ORDER MESSAGE',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.paste_rounded, size: 16),
                                label: const Text('Paste Sample Message', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  _textController.text = _sampleMessage;
                                  _parseMessage();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textController,
                            maxLines: 6,
                            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: 'Paste message string e.g. Shop: Shri Krishna Traders...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.clear_rounded),
                                label: const Text('Clear'),
                                onPressed: () {
                                  _textController.clear();
                                  setState(() {
                                    _parsedOrder = null;
                                    _mappedRows.clear();
                                    _selectedParty = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: _isParsing
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.bolt_rounded),
                                  label: const Text('Parse Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isParsing ? null : _parseMessage,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_parsedOrder != null) ...[
                    const SizedBox(height: 16),

                    // 2. Parsed Metadata Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PARSED MESSAGE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildMetaChip(Icons.store_rounded, 'Shop', _parsedOrder?.shopName ?? 'N/A'),
                              _buildMetaChip(Icons.phone_rounded, 'Mobile', _parsedOrder?.mobileNumber ?? 'N/A'),
                              _buildMetaChip(Icons.tag_rounded, 'Order ID', _parsedOrder?.orderId ?? 'N/A'),
                              _buildMetaChip(Icons.person_rounded, 'SalesRep', _parsedOrder?.salesRep ?? 'N/A'),
                              _buildMetaChip(Icons.calendar_today_rounded, 'Date', _parsedOrder?.dateStr ?? 'N/A'),
                              if (_parsedOrder?.locationUrl != null)
                                _buildMetaChip(
                                  Icons.location_on_rounded,
                                  'GPS Location',
                                  '${_parsedOrder?.latitude ?? 0.0}, ${_parsedOrder?.longitude ?? 0.0}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Customer Selection Dropdown
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('MAPPED CUSTOMER PARTY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                TextButton.icon(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('+ Create New Party', style: TextStyle(fontSize: 12)),
                                  onPressed: _showCreatePartyDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Party?>(
                              value: _selectedParty,
                              decoration: const InputDecoration(
                                labelText: 'Select Customer Account',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: [
                                const DropdownMenuItem<Party?>(value: null, child: Text('-- Select Customer --')),
                                ..._allParties.map((p) => DropdownMenuItem<Party?>(
                                      value: p,
                                      child: Text('${p.partyName ?? "Party"} (${p.mobileNumber ?? "No Mob"})'),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedParty = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Live Comparison Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isVerifiedMatch ? Colors.green.withOpacity(0.08) : Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isVerifiedMatch ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WhatsApp Total: ${currencyFormat.format(whatsappTotal)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Computed ERP Total: ${currencyFormat.format(computedErpTotal)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isVerifiedMatch ? Colors.green : Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(isVerifiedMatch ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  isVerifiedMatch ? 'Verified Match' : 'Total Mismatch / Review Needed',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Items Mapping Table
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ITEMS MAPPING & RATES TABLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('${_mappedRows.length} Items Parsed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _mappedRows.length,
                              separatorBuilder: (_, __) => const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final row = _mappedRows[index];
                                final item = row.selectedItem;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // WhatsApp line header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Line #${index + 1}: ${row.rawParsedItem.rawLine}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Product Dropdown
                                    DropdownButtonFormField<Item?>(
                                      value: row.selectedItem,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Mapped ERP Product',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: [
                                        const DropdownMenuItem<Item?>(value: null, child: Text('-- Select ERP Product --')),
                                        ..._allItems.map((i) => DropdownMenuItem<Item?>(
                                              value: i,
                                              child: Text('${i.itemName ?? "Item"} (Rate: ₹${i.sellRate ?? 0})'),
                                            )),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          row.selectedItem = val;
                                          row.rate = val?.sellRate ?? 0.0;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // Qty, Unit Toggle, Rate, Subtotal Row
                                    Row(
                                      children: [
                                        // Unit Toggle Button
                                        InkWell(
                                          onTap: item == null
                                              ? null
                                              : () {
                                                  setState(() {
                                                    row.isSecondaryUnit = !row.isSecondaryUnit;
                                                    final factor = item.conversionFactor ?? 1.0;
                                                    if (row.isSecondaryUnit && factor > 1) {
                                                      row.rate = (item.sellRate ?? 0.0) / factor;
                                                    } else {
                                                      row.rate = item.sellRate ?? 0.0;
                                                    }
                                                  });
                                                },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: row.isSecondaryUnit ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: row.isSecondaryUnit ? Colors.purple : Colors.blue),
                                            ),
                                            child: Text(
                                              row.isSecondaryUnit
                                                  ? (item?.secondaryUnitName ?? 'SEC')
                                                  : (item?.primaryUnitName ?? item?.unit.value?.shortName ?? 'PRI'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: row.isSecondaryUnit ? Colors.purple : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Qty Input
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: TextFormField(
                                              initialValue: row.quantity.toStringAsFixed(0),
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                labelText: 'Qty',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              ),
                                              onChanged: (val) {
                                                final q = double.tryParse(val) ?? 1.0;
                                                setState(() => row.quantity = q);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Rate Input
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: TextFormField(
                                              key: ValueKey('rate_${index}_${row.rate}'),
                                              initialValue: row.rate.toStringAsFixed(2),
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                labelText: 'Rate (₹)',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              ),
                                              onChanged: (val) {
                                                final r = double.tryParse(val) ?? 0.0;
                                                setState(() => row.rate = r);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Subtotal
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                            Text(
                                              currencyFormat.format(row.subtotal),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Remember Mappings Checkbox
                    CheckboxListTile(
                      value: _rememberMappings,
                      title: const Text('Remember Mappings for Future WhatsApp Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Saves shop name & item aliases to SharedPreferences memory for auto-recognition', style: TextStyle(fontSize: 11)),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _rememberMappings = val ?? true),
                    ),
                    const SizedBox(height: 16),

                    // 7. Approve & Create Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Approve & Create Sales Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _approveAndCreateOrder,
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
