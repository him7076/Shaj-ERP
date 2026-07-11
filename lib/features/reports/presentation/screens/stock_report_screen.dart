import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class StockReportScreen extends ConsumerStatefulWidget {
  const StockReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends ConsumerState<StockReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stock list filters
  String _selectedStatus = 'All'; // All, Available, Low Stock, Out Of Stock

  // Stock movement variables
  String? _selectedItemUuid;
  List<Item> _itemsList = [];
  bool _loadingItems = false;

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final items = await db.isar.items.filter().isDeletedEqualTo(false).findAll();
      setState(() {
        _itemsList = items;
        if (items.isNotEmpty) {
          _selectedItemUuid = items.first.uuid;
        }
      });
    } catch (_) {}
    setState(() => _loadingItems = false);
  }

  void _exportPDF(StockReportSummary summary) async {
    final exportService = ref.read(exportServiceProvider);

    final headers = ['Item Name', 'SKU', 'Stock Qty', 'Reorder Level', 'Buy Cost', 'Total Value'];
    final rows = summary.lines.map((line) {
      return [
        line.itemName,
        line.sku,
        line.currentStock.toStringAsFixed(1),
        line.reorderLevel.toStringAsFixed(1),
        currencyFormat.format(line.buyRate),
        currencyFormat.format(line.stockValue),
      ];
    }).toList();

    final totals = [
      'Total Inventory Value: ${currencyFormat.format(summary.totalValue)}',
    ];

    await exportService.exportToPDF(
      title: 'Current Inventory Valuation Report',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Watch providers
    final reportAsync = ref.watch(stockReportProvider(_selectedStatus));
    
    final movementAsync = _selectedItemUuid != null
        ? ref.watch(stockMovementProvider(_selectedItemUuid!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Valuation & Stock Ledger'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Stock Value'),
            Tab(text: 'Stock Movement Logs'),
          ],
        ),
        actions: [
          _tabController.index == 0
              ? reportAsync.when(
                  data: (summary) => IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    tooltip: 'Export Valuation PDF',
                    onPressed: () => _exportPDF(summary),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                )
              : const SizedBox(),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Current Stock Value
          Column(
            children: [
              // Filter status
              Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter Stock Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Stock Levels')),
                      DropdownMenuItem(value: 'Available', child: Text('Available (Safe levels)')),
                      DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock Alerts')),
                      DropdownMenuItem(value: 'Out Of Stock', child: Text('Out Of Stock')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatus = val);
                      }
                    },
                  ),
                ),
              ),

              // Summary valuation banner
              reportAsync.when(
                data: (summary) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available: ${summary.availableCount} items', style: const TextStyle(fontSize: 12)),
                          Text('Low Stock: ${summary.lowStockCount} items', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                          Text('Out of Stock: ${summary.outOfStockCount} items', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Stock Value', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                          Text(
                            currencyFormat.format(summary.totalValue),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              // Items Valuation Table
              Expanded(
                child: reportAsync.when(
                  data: (summary) {
                    if (summary.lines.isEmpty) {
                      return const Center(child: Text('No stock items match selected filters.'));
                    }
                    return ListView.builder(
                      itemCount: summary.lines.length,
                      itemBuilder: (context, index) {
                        final line = summary.lines[index];
                        final isLow = line.status == 'Low Stock';
                        final isOut = line.status == 'Out Of Stock';

                        Color badgeColor = Colors.green[700]!;
                        if (isOut) {
                          badgeColor = Colors.red[700]!;
                        } else if (isLow) {
                          badgeColor = Colors.orange[700]!;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                          ),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    line.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(line.stockValue),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Stock: ${line.currentStock.toStringAsFixed(1)} units • Buy: ${currencyFormat.format(line.buyRate)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      line.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),

          // Tab 2: Stock Movement Logs
          Column(
            children: [
              // Product selector
              Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _loadingItems
                      ? const Center(child: LinearProgressIndicator())
                      : DropdownButtonFormField<String?>(
                          value: _selectedItemUuid,
                          decoration: const InputDecoration(
                            labelText: 'Select Product Item',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: _itemsList.map((item) {
                            return DropdownMenuItem<String?>(
                              value: item.uuid,
                              child: Text(item.itemName ?? 'Unnamed Item'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedItemUuid = val);
                            }
                          },
                        ),
                ),
              ),

              // Ledger Lists
              Expanded(
                child: _selectedItemUuid == null
                    ? const Center(child: Text('Please select an item to view movement logs.'))
                    : movementAsync == null
                        ? const Center(child: CircularProgressIndicator())
                        : movementAsync.when(
                            data: (logs) {
                              if (logs.isEmpty) {
                                return const Center(child: Text('No movement ledger entries logged for this item.'));
                              }
                              return ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.date);
                                  
                                  final isStockIn = log.qtyIn > 0;
                                  final changeText = isStockIn ? '+${log.qtyIn}' : '-${log.qtyOut}';
                                  final changeColor = isStockIn ? Colors.green[700] : Colors.red[700];

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                                    ),
                                    child: ListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.reason,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            changeText,
                                            style: TextStyle(fontWeight: FontWeight.bold, color: changeColor),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dateStr, style: const TextStyle(fontSize: 11)),
                                            Text(
                                              'Balance: ${log.balance.toStringAsFixed(1)} units',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
