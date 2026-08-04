import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:isar/isar.dart';

enum ExpiryStatus { expired, expiringSoon, fresh, unknown }

class BatchItemRecord {
  final String itemName;
  final String batchNumber;
  final String expiryDate;
  final String mfgDate;
  final double qty;
  final String unit;
  final String source;
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

  ExpiryStatus get expiryStatus {
    if (expiryDate.isEmpty || expiryDate == 'N/A') return ExpiryStatus.unknown;
    try {
      DateTime? parsed;
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 1;
          final y = int.tryParse(parts[1]) ?? DateTime.now().year;
          parsed = DateTime(y > 100 ? y : 2000 + y, m + 1, 0); // Last day of month
        } else if (parts.length == 3) {
          final d = int.tryParse(parts[0]) ?? 1;
          final m = int.tryParse(parts[1]) ?? 1;
          final y = int.tryParse(parts[2]) ?? DateTime.now().year;
          parsed = DateTime(y > 100 ? y : 2000 + y, m, d);
        }
      } else {
        parsed = DateTime.tryParse(expiryDate);
      }

      if (parsed == null) return ExpiryStatus.unknown;

      final now = DateTime.now();
      if (parsed.isBefore(now)) {
        return ExpiryStatus.expired;
      } else if (parsed.isBefore(now.add(const Duration(days: 60)))) {
        return ExpiryStatus.expiringSoon;
      } else {
        return ExpiryStatus.fresh;
      }
    } catch (_) {
      return ExpiryStatus.unknown;
    }
  }
}

final batchReportProvider = FutureProvider.autoDispose<List<BatchItemRecord>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  final isar = dbService.isar;

  final purchaseItems = await isar.purchaseItems.filter().idGreaterThan(-1).findAll();
  final invoiceItems = await isar.invoiceItems.filter().idGreaterThan(-1).findAll();
  final orderItems = await isar.orderItems.filter().idGreaterThan(-1).findAll();
  final creditItems = await isar.creditNoteItems.filter().idGreaterThan(-1).findAll();
  final debitItems = await isar.debitNoteItems.filter().idGreaterThan(-1).findAll();

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

  for (var oi in orderItems) {
    if (oi.batchNumber != null && oi.batchNumber!.trim().isNotEmpty) {
      list.add(BatchItemRecord(
        itemName: oi.itemName ?? 'Unnamed Product',
        batchNumber: oi.batchNumber!.trim(),
        expiryDate: oi.expiryDate ?? 'N/A',
        mfgDate: oi.mfgDate ?? 'N/A',
        qty: oi.quantity ?? 0.0,
        unit: oi.unit ?? 'PCS',
        source: 'Order Allocation',
        recordDate: oi.createdAt,
      ));
    }
  }

  for (var ci in creditItems) {
    if (ci.batchNumber != null && ci.batchNumber!.trim().isNotEmpty) {
      list.add(BatchItemRecord(
        itemName: ci.itemName ?? 'Unnamed Product',
        batchNumber: ci.batchNumber!.trim(),
        expiryDate: ci.expiryDate ?? 'N/A',
        mfgDate: ci.mfgDate ?? 'N/A',
        qty: ci.quantity ?? 0.0,
        unit: ci.unit ?? 'PCS',
        source: 'Sales Return',
        recordDate: ci.createdAt,
      ));
    }
  }

  for (var di in debitItems) {
    if (di.batchNumber != null && di.batchNumber!.trim().isNotEmpty) {
      list.add(BatchItemRecord(
        itemName: di.itemName ?? 'Unnamed Product',
        batchNumber: di.batchNumber!.trim(),
        expiryDate: di.expiryDate ?? 'N/A',
        mfgDate: di.mfgDate ?? 'N/A',
        qty: di.quantity ?? 0.0,
        unit: di.unit ?? 'PCS',
        source: 'Purchase Return',
        recordDate: di.createdAt,
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
  String _expiryFilter = 'All';

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
            tooltip: 'Refresh Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reportAsync.when(
        data: (items) {
          int expiredCount = 0;
          int expiringCount = 0;
          for (var item in items) {
            if (item.expiryStatus == ExpiryStatus.expired) expiredCount++;
            if (item.expiryStatus == ExpiryStatus.expiringSoon) expiringCount++;
          }

          final filtered = items.where((b) {
            final matchesQuery = _searchQuery.isEmpty ||
                b.batchNumber.toLowerCase().contains(_searchQuery) ||
                b.itemName.toLowerCase().contains(_searchQuery) ||
                b.expiryDate.toLowerCase().contains(_searchQuery);

            bool matchesFilter = true;
            if (_expiryFilter == 'Expired') {
              matchesFilter = b.expiryStatus == ExpiryStatus.expired;
            } else if (_expiryFilter == 'Expiring Soon') {
              matchesFilter = b.expiryStatus == ExpiryStatus.expiringSoon;
            } else if (_expiryFilter == 'Fresh Stock') {
              matchesFilter = b.expiryStatus == ExpiryStatus.fresh;
            }

            return matchesQuery && matchesFilter;
          }).toList();

          return Column(
            children: [
              // KPI Cards Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.purple,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Batches', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('${items.length}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.orange,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expiring Soon (60d)', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('$expiringCount', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.red,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expired Stock', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('$expiredCount', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),

              const SizedBox(height: 10),

              // Expiry Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Expiring Soon', 'Expired', 'Fresh Stock'].map((filter) {
                    final isSelected = _expiryFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _expiryFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // List of Batches
              Expanded(
                child: filtered.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final dateStr = DateFormat('dd MMM yyyy').format(item.recordDate);

                          Color badgeColor;
                          String badgeText;
                          if (item.expiryStatus == ExpiryStatus.expired) {
                            badgeColor = Colors.red;
                            badgeText = 'EXPIRED';
                          } else if (item.expiryStatus == ExpiryStatus.expiringSoon) {
                            badgeColor = Colors.orange.shade800;
                            badgeText = 'EXPIRING SOON';
                          } else {
                            badgeColor = Colors.green;
                            badgeText = 'FRESH';
                          }

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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 10),
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
                                    Text('Batch: ${item.batchNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                                    Text('Qty: ${item.qty} ${item.unit}', style: const TextStyle(fontSize: 12)),
                                    Text('MFG: ${item.mfgDate}', style: const TextStyle(fontSize: 12)),
                                    Text('EXP: ${item.expiryDate}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                                    Text('Source: ${item.source} ($dateStr)', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading batch report: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
