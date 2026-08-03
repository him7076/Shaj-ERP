import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:isar/isar.dart';

class BatchItemRecord {
  final String itemName;
  final String batchNumber;
  final String expiryDate;
  final String mfgDate;
  final double qty;
  final String unit;
  final String source; // Purchase or Invoice
  final DateTime recordDate;

  BatchItemRecord({
    required this.itemName,
    required this.batchNumber,
    required this.expiryDate,
    required this.mfgDate,
    required this.qty,
    required this.unit,
    required this.source,
    required this.recordDate,
  });
}

final batchReportProvider = FutureProvider.autoDispose<List<BatchItemRecord>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  final isar = dbService.isar;

  final purchaseItems = await isar.purchaseItems.filter().idGreaterThan(-1).findAll();
  final invoiceItems = await isar.invoiceItems.filter().idGreaterThan(-1).findAll();

  final List<BatchItemRecord> list = [];

  for (var pi in purchaseItems) {
    if (pi.batchNumber != null && pi.batchNumber!.trim().isNotEmpty) {
      list.add(BatchItemRecord(
        itemName: pi.itemName ?? 'Unnamed Product',
        batchNumber: pi.batchNumber!.trim(),
        expiryDate: pi.expiryDate ?? 'N/A',
        mfgDate: pi.mfgDate ?? 'N/A',
        qty: pi.quantity ?? 0.0,
        unit: pi.unit ?? 'PCS',
        source: 'Purchase Inward',
        recordDate: pi.createdAt,
      ));
    }
  }

  for (var ii in invoiceItems) {
    if (ii.batchNumber != null && ii.batchNumber!.trim().isNotEmpty) {
      list.add(BatchItemRecord(
        itemName: ii.itemName ?? 'Unnamed Product',
        batchNumber: ii.batchNumber!.trim(),
        expiryDate: ii.expiryDate ?? 'N/A',
        mfgDate: ii.mfgDate ?? 'N/A',
        qty: ii.quantity ?? 0.0,
        unit: ii.unit ?? 'PCS',
        source: 'Sales Outward',
        recordDate: ii.createdAt,
      ));
    }
  }

  list.sort((a, b) => b.recordDate.compareTo(a.recordDate));
  return list;
});

class BatchReportScreen extends ConsumerStatefulWidget {
  const BatchReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BatchReportScreen> createState() => _BatchReportScreenState();
}

class _BatchReportScreenState extends ConsumerState<BatchReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(batchReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Tracking & Expiry Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(batchReportProvider),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Batch No, Product Name, Expiry Date...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Main List
          Expanded(
            child: reportAsync.when(
              data: (items) {
                final filtered = items.where((b) {
                  if (_searchQuery.isEmpty) return true;
                  return b.batchNumber.toLowerCase().contains(_searchQuery) ||
                      b.itemName.toLowerCase().contains(_searchQuery) ||
                      b.expiryDate.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          items.isEmpty ? 'No batch numbers recorded in transactions yet.' : 'No matching batch records found.',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final dateStr = DateFormat('dd MMM yyyy').format(item.recordDate);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.source.contains('Purchase') ? Colors.blue.shade50 : Colors.green.shade50,
                          child: Icon(
                            item.source.contains('Purchase') ? Icons.archive_outlined : Icons.unarchive_outlined,
                            color: item.source.contains('Purchase') ? Colors.blue : Colors.green,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Text(
                                'Batch: ${item.batchNumber}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade900, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text('Type: ${item.source}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text('Qty: ${item.qty} ${item.unit}', style: const TextStyle(fontSize: 12)),
                              Text('Exp: ${item.expiryDate}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                              Text('Date: $dateStr', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading batch report: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
