import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:isar/isar.dart';

final deletedVouchersProvider = FutureProvider.autoDispose<List<DeletedVoucher>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  final isar = dbService.isar;
  final list = await isar.collection<DeletedVoucher>().filter().idGreaterThan(-1).findAll();
  list.sort((a, b) => b.deletedAt?.compareTo(a.deletedAt ?? DateTime.now()) ?? 0);
  return list;
});


class DeletedVouchersScreen extends ConsumerStatefulWidget {
  const DeletedVouchersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeletedVouchersScreen> createState() => _DeletedVouchersScreenState();
}

class _DeletedVouchersScreenState extends ConsumerState<DeletedVouchersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterType = 'All';

  final List<String> _voucherTypes = [
    'All',
    'Invoice',
    'Purchase',
    'Order',
    'Transaction',
    'Payment',
    'Receipt',
    'Credit Note',
    'Debit Note',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vouchersAsync = ref.watch(deletedVouchersProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Vouchers Audit Log', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(deletedVouchersProvider),
            tooltip: 'Refresh Audit Log',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vouchersAsync.when(
        data: (vouchers) {
          final filtered = vouchers.where((v) {
            final matchesQuery = _searchQuery.isEmpty ||
                (v.voucherNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                (v.partyName?.toLowerCase().contains(_searchQuery) ?? false) ||
                (v.voucherType?.toLowerCase().contains(_searchQuery) ?? false);
            final matchesType = _selectedFilterType == 'All' ||
                (v.voucherType?.toLowerCase().contains(_selectedFilterType.toLowerCase()) ?? false);
            return matchesQuery && matchesType;
          }).toList();

          double totalDeletedAmount = 0.0;
          for (var v in filtered) {
            totalDeletedAmount += (v.amount ?? 0.0);
          }

          return Column(
            children: [
              // KPI Cards Row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.redAccent,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deleted Vouchers Count', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '${filtered.length}',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedHoverCard(
                        glowColor: Colors.orangeAccent,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Deleted Value', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(totalDeletedAmount),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Type Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Voucher No, Party Name, Type...',
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

              const SizedBox(height: 12),

              // Voucher Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _voucherTypes.map((type) {
                    final isSelected = _selectedFilterType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilterType = type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // List of Deleted Vouchers
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text(
                              vouchers.isEmpty
                                  ? 'No deleted vouchers recorded yet.'
                                  : 'No deleted vouchers match your search filter.',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          final dateStr = v.deletedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(v.deletedAt!)
                              : 'Unknown Date';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${v.voucherType ?? "Voucher"}: ${v.voucherNumber ?? "N/A"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(v.amount ?? 0.0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Party: ${v.partyName ?? "General / Cash"}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Deleted: $dateStr',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
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
        error: (err, _) => Center(
          child: Text('Error loading deleted vouchers: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
