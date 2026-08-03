import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/services/purchase_excel_import_service.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  final bool createImmediately;
  const PurchasesScreen({Key? key, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    if (widget.createImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditPurchaseScreen(),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadSampleExcel() async {
    try {
      final sampleBytes = PurchaseExcelImportService.generateSampleTemplate();
      if (sampleBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sample template.')),
        );
        return;
      }

      await Printing.sharePdf(
        bytes: Uint8List.fromList(sampleBytes),
        filename: 'Purchase_Import_Sample_Template.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Sample Purchase Excel Template downloaded! Fill details in Sheet 1 & Sheet 2.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating sample Excel: $e')),
      );
    }
  }

  Future<void> _importPurchaseExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected Excel file.')),
        );
        return;
      }

      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importing Purchases & Items...'),
            ],
          ),
        ),
      );

      final dbService = ref.read(databaseServiceProvider);
      final importResult = await PurchaseExcelImportService.importPurchasesFromBytes(fileBytes, dbService);

      // Instantly trigger cloud sync to push newly imported purchases & items to Firestore
      ref.read(syncServiceProvider).syncAll();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog safely
      }

      ref.invalidate(purchaseListProvider);
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  importResult.totalBillsImported > 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: importResult.totalBillsImported > 0 ? Colors.green : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Purchase Excel Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Purchase Bills Imported: ${importResult.totalBillsImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('📦 Purchase Items Recorded: ${importResult.totalItemsImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (importResult.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Warnings / Errors:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...importResult.errors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import Excel file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchasesAsync = ref.watch(purchaseListProvider);
    final notifierState = ref.watch(purchaseNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Purchases & Inward Goods'),
        actions: [
          TextButton.icon(
            onPressed: _downloadSampleExcel,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Sample Sheet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _importPurchaseExcel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(purchaseListProvider),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPurchaseScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Record Purchase Bill'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by purchase number or supplier...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(purchaseSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(purchaseSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Main Content Area
          Expanded(
            child: purchasesAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No purchases recorded yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditPurchaseScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Purchase Bill'),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate Totals
                final double totalAmt = list.fold(0.0, (sum, p) => sum + (p.grandTotal ?? 0.0));
                final double totalTax = list.fold(0.0, (sum, p) => sum + (p.totalGST ?? 0.0));

                return Column(
                  children: [
                    // Summary Banner Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Total Inward Value',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(totalAmt),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
                            Column(
                              children: [
                                Text(
                                  'Total Input Tax Credit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(totalTax),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // List of purchases
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final purchase = list[index];
                          final dateStr = purchase.purchaseDate != null
                              ? DateFormat('dd MMM yyyy').format(purchase.purchaseDate!)
                              : 'N/A';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 6,
                                      color: theme.colorScheme.primary,
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddEditPurchaseScreen(purchaseUuid: purchase.uuid),
                                            ),
                                          ).then((_) => ref.invalidate(purchaseListProvider));
                                        },
                                        leading: CircleAvatar(
                                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                          child: Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 20),
                                        ),
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              purchase.partyName ?? 'Unknown Supplier',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              currencyFormat.format(purchase.grandTotal ?? 0.0),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.spaceBetween,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'Bill No: ${purchase.purchaseNumber ?? "N/A"}  •  $dateStr',
                                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                              ),
                                              if (purchase.remarks != null && purchase.remarks!.isNotEmpty)
                                                Icon(
                                                  Icons.comment_outlined,
                                                  size: 14,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                            ],
                                          ),
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                                          onSelected: (val) async {
                                            final dbService = ref.read(databaseServiceProvider);
                                            final isar = dbService.isar;

                                            if (val == 'edit') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AddEditPurchaseScreen(purchaseUuid: purchase.uuid),
                                                ),
                                              ).then((_) => ref.invalidate(purchaseListProvider));
                                            } else if (val == 'cancel') {
                                              final newStatus = purchase.paymentStatus == 'Cancelled' ? 'Unpaid' : 'Cancelled';
                                              await isar.writeTxn(() async {
                                                purchase.paymentStatus = newStatus;
                                                purchase.updatedAt = DateTime.now();
                                                await isar.purchases.put(purchase);
                                              });
                                              ref.invalidate(purchaseListProvider);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Purchase Bill ${purchase.purchaseNumber} status set to $newStatus.'),
                                                    backgroundColor: newStatus == 'Cancelled' ? Colors.orange : Colors.green,
                                                  ),
                                                );
                                              }
                                            } else if (val == 'delete') {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete Purchase Bill?'),
                                                  content: Text('Are you sure you want to delete Purchase Bill ${purchase.purchaseNumber}?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                final success = await ref
                                                    .read(purchaseNotifierProvider.notifier)
                                                    .deletePurchase(purchase.id);
                                                if (success && mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Purchase record deleted.')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Purchase')]),
                                            ),
                                            PopupMenuItem(
                                              value: 'cancel',
                                              child: Row(children: [
                                                Icon(purchase.paymentStatus == 'Cancelled' ? Icons.check_circle_outline : Icons.block_outlined, size: 18, color: Colors.orange),
                                                const SizedBox(width: 8),
                                                Text(purchase.purchaseNumber == 'Cancelled' ? 'Reactivate Bill' : 'Cancel Bill', style: const TextStyle(color: Colors.orange)),
                                              ]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Bill', style: TextStyle(color: Colors.red))]),
                                            ),
                                          ],
                                        ),
                                      ),
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
                child: Text('Failed to load purchases: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
