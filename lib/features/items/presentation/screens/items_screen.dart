import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/item_detail_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/services/item_excel_import_service.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showSearch = false;
  int _displayLimit = 50;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadItemSampleExcel() async {
    try {
      final sampleBytes = ItemExcelImportService.generateSampleTemplate();
      if (sampleBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sample template.')),
        );
        return;
      }

      await Printing.sharePdf(
        bytes: Uint8List.fromList(sampleBytes),
        filename: 'Items_Import_Sample_Template.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Sample Product Catalog Excel Template downloaded! Fill details and click Import Excel.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating sample Excel: $e')),
      );
    }
  }

  Future<void> _importItemExcel() async {
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

      final progressController = StreamController<ImportProgressState>.broadcast();
      BuildContext? progressDialogContext;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            progressDialogContext = ctx;
            return ImportProgressModal(
              title: 'Importing Products & Stock',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final dbService = ref.read(databaseServiceProvider);
      final importResult = await ItemExcelImportService.importItemsFromBytes(
        fileBytes,
        dbService,
        onProgress: (current, total, statusMessage) {
          progressController.add(ImportProgressState(
            current: current,
            total: total,
            statusMessage: statusMessage,
          ));
        },
      );

      await progressController.close();
      if (progressDialogContext != null && progressDialogContext!.mounted) {
        Navigator.of(progressDialogContext!).pop(); // Close progress dialog safely
      }

      // Instantly trigger cloud sync to push newly imported items to Firestore
      ref.read(syncServiceProvider).syncAll();

      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(query: ''));
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(lowStockAlertProvider);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(brandsListProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  (importResult.totalItemsImported + importResult.totalItemsUpdated) > 0
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: (importResult.totalItemsImported + importResult.totalItemsUpdated) > 0
                      ? Colors.green
                      : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Items Excel Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ New Products Added: ${importResult.totalItemsImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('🔄 Existing Stock Updated: ${importResult.totalItemsUpdated}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Future<void> _scanBarcode() async {
    final barcodeService = ref.read(barcodeServiceProvider);
    final code = await barcodeService.scanBarcode(context);
    if (code != null) {
      _searchController.text = code;
      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(query: code));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Barcode: $code. Showing matches.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(itemSearchProvider);
    final itemsAsync = ref.watch(filteredItemsProvider);
    final lowStockAsync = ref.watch(lowStockAlertProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final brandsAsync = ref.watch(brandsListProvider);

    // Responsive grid columns
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    double childAspectRatio = 2.8;

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
      childAspectRatio = 1.55;
    } else if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    } else {
      if (screenWidth > 480) {
        crossAxisCount = 2;
        childAspectRatio = 1.6;
      } else {
        crossAxisCount = 1;
        childAspectRatio = 3.0;
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: ResponsiveLayout.isMobile(context) ? 44 : 52,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search name, code, HSN, barcode...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) {
                  ref.read(itemSearchProvider.notifier).update(
                        (state) => state.copyWith(query: val),
                      );
                },
              )
            : Text(
                'Product Inventory',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isMobile(context) ? 15 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          // 🔍 Search Toggle Button
          IconButton(
            tooltip: 'Search Products',
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(itemSearchProvider.notifier).update(
                        (state) => state.copyWith(query: ''),
                      );
                }
              });
            },
          ),

          // ⚡ Filter Toggle Button
          IconButton(
            tooltip: 'Filter Products',
            icon: Icon(
              _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
              size: 20,
              color: _showFilters ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),

          // 📷 Barcode Scan Icon
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
          ),

          // ⋮ 3-Dot Tools Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'Product Tools',
            onSelected: (value) {
              if (value == 'sample') {
                _downloadItemSampleExcel();
              } else if (value == 'import') {
                _importItemExcel();
              } else if (value == 'quick_add') {
                AddItemSheet.show(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'quick_add',
                child: Row(
                  children: [
                    Icon(Icons.add_shopping_cart_outlined, size: 18, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Quick Add Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Sample Excel Sheet'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_rounded, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Import Excel Catalog'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Low stock warning banner
          lowStockAsync.when(
            data: (lowStockItems) {
              if (lowStockItems.isEmpty) return const SizedBox.shrink();
              return Material(
                color: Colors.orange.shade50,
                child: InkWell(
                  onTap: () {
                    ref.read(itemSearchProvider.notifier).update(
                          (state) => state.copyWith(stockStatus: 'Low Stock'),
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '⚠ ${lowStockItems.length} products running below reorder level!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Filter Panel (collapsible)
          if (_showFilters) _buildFilterPanel(theme, filter, categoriesAsync, brandsAsync),

          // Horizontal Category Chip Quick Filters
          _buildCategoryChipBar(theme, filter, categoriesAsync),

          // Item Grid
          Expanded(
            child: itemsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products found matching filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditItemScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                final visibleList = list.take(_displayLimit).toList();
                final hasMore = list.length > _displayLimit;

                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: visibleList.length,
                        itemBuilder: (context, index) {
                          final item = visibleList[index];
                          return _buildProductCard(item, theme);
                        },
                      ),
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _displayLimit += 50;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.arrow_downward_rounded),
                          label: Text(
                            'Load More Products (Showing ${_displayLimit} of ${list.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load catalog: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
          ref.invalidate(filteredItemsProvider);
        },
      ),
    );
  }

  Widget _buildCategoryChipBar(
    ThemeData theme,
    ItemSearchFilter filter,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : categories[index - 1];
              final isSelected = isAll ? filter.categoryId == null : filter.categoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isAll ? 'All' : (cat?.categoryName ?? '')),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(itemSearchProvider.notifier).update(
                          (state) => state.copyWith(
                            categoryId: selected ? cat?.id : null,
                          ),
                        );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    ItemSearchFilter filter,
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Brand>> brandsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.stockStatus,
                  decoration: const InputDecoration(
                    labelText: 'Stock Level',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                    DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(stockStatus: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Name A-Z', child: Text('Name (A-Z)')),
                    DropdownMenuItem(value: 'Name Z-A', child: Text('Name (Z-A)')),
                    DropdownMenuItem(value: 'Price L-H', child: Text('Price (Low-High)')),
                    DropdownMenuItem(value: 'Price H-L', child: Text('Price (High-Low)')),
                    DropdownMenuItem(value: 'Stock L-H', child: Text('Stock (Low-High)')),
                    DropdownMenuItem(value: 'Stock H-L', child: Text('Stock (High-Low)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(sortBy: v));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: brandsAsync.when(
                  data: (brands) {
                    return DropdownButtonFormField<int?>(
                      value: filter.brandId,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Brands')),
                        ...brands.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.brandName ?? ''))),
                      ],
                      onChanged: (v) {
                        ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(brandId: v));
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: () {
                  _searchController.clear();
                  ref.read(itemSearchProvider.notifier).state = const ItemSearchFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Item item, ThemeData theme) {
    final stockVal = item.currentStock ?? 0.0;
    final reorderVal = item.reorderLevel ?? 0.0;
    final isOut = stockVal <= 0;
    final isLow = stockVal <= reorderVal && !isOut;

    final String primaryUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? 'PCS';
    final String? secUnit = item.secondaryUnit;
    final double? conv = item.conversionFactor;

    final String formattedStock = stockVal == stockVal.roundToDouble() ? stockVal.toInt().toString() : stockVal.toStringAsFixed(2);
    String stockLabel = '$formattedStock $primaryUnit';
    if (secUnit != null && secUnit.isNotEmpty && conv != null && conv > 1.0) {
      final double secVal = stockVal * conv;
      final String formattedSec = secVal == secVal.roundToDouble() ? secVal.toInt().toString() : secVal.toStringAsFixed(1);
      stockLabel = '$formattedStock $primaryUnit ($formattedSec $secUnit)';
    }

    Color stockColor = Colors.green;
    IconData stockIcon = Icons.check_circle;
    if (isOut) {
      stockColor = Colors.red;
      stockLabel = 'Out of Stock ($stockLabel)';
      stockIcon = Icons.cancel;
    } else if (isLow) {
      stockColor = Colors.orange;
      stockLabel = '$stockLabel (Low)';
      stockIcon = Icons.warning;
    }

    return Card(
      key: ValueKey(item.uuid),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOut
              ? Colors.red.withOpacity(0.4)
              : isLow
                  ? Colors.orange.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(itemUuid: item.uuid!),
            ),
          ).then((_) => ref.invalidate(filteredItemsProvider));
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Name + Stock indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName ?? 'Unnamed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.itemCode ?? 'No code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Bottom row: Price + Stock badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(item.sellRate ?? 0.0),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stockIcon, size: 12, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          stockLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
