import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/excel_csv_helper.dart';
import 'package:business_sahaj_erp/core/utils/distance_calculator.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:business_sahaj_erp/core/services/party_excel_import_service.dart';
import 'package:business_sahaj_erp/core/widgets/liquid_glass_card.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';
import 'package:business_sahaj_erp/core/utils/excel_download_helper.dart';
import 'party_detail_screen.dart';
import 'add_edit_party_screen.dart';

class PartiesScreen extends ConsumerStatefulWidget {
  const PartiesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends ConsumerState<PartiesScreen> {
  final _searchController = TextEditingController();
  bool _isNearbyMode = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partySearchProvider.notifier).setQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    Future.microtask(() {
      try {
        ref.read(partySearchProvider.notifier).setQuery('');
      } catch (_) {}
    });
    super.dispose();
  }

  Future<void> _downloadPartySampleExcel() async {
    try {
      final sampleBytes = PartyExcelImportService.generateSampleTemplate();
      if (sampleBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sample template.')),
        );
        return;
      }

      await ExcelDownloadHelper.downloadExcel(
        sampleBytes,
        'Party_Import_Sample_Template.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Sample Party & Customer Excel Template downloaded! Fill details and click Import Excel.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating sample Excel: $e')),
      );
    }
  }

  Future<void> _importPartyExcel() async {
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
              title: 'Importing Parties & Customers',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final dbService = ref.read(databaseServiceProvider);
      final importResult = await PartyExcelImportService.importPartiesFromBytes(
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

      ref.read(partySearchProvider.notifier).setQuery('');
      ref.invalidate(filteredPartiesProvider);

      // Instantly trigger cloud sync to push newly imported parties to Firestore
      ref.read(syncServiceProvider).syncAll();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  (importResult.totalPartiesImported + importResult.totalPartiesUpdated) > 0
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: (importResult.totalPartiesImported + importResult.totalPartiesUpdated) > 0
                      ? Colors.green
                      : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Party Excel Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ New Parties Registered: ${importResult.totalPartiesImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('🔄 Existing Parties Updated: ${importResult.totalPartiesUpdated}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _importCsvDemo() {
    // Simulated CSV file content
    const csvData = '''name,gst,mobile,address,city,state,type
John Distributors,27AAAJD8239A1Z2,9876500112,45 Market Street,Mumbai,Maharashtra,Distributor
Shree Traders,27AAAST8903B2Z5,9922334455,Near Central Depot,Pune,Maharashtra,Wholesaler
Vijay Retails,,9123456789,Shop 5 Main Bazar,Nashik,Maharashtra,Retailer
Custom Contractor,,8888877777,Sector 9,Surat,Gujarat,Customer
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Parties from CSV'),
        content: const Text(
          'This will parse and import 4 demo parties: Wholesalers, Distributors, and Retailers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = ref.read(partyRepositoryProvider);
                final parsed = ExcelCsvHelper.parseCsv(csvData);
                int count = 0;

                for (var row in parsed) {
                  final party = Party()
                    ..partyName = row['name']
                    ..gstNumber = row['gst']
                    ..mobileNumber = row['mobile']
                    ..addressLine1 = row['address']
                    ..city = row['city']
                    ..state = row['state']
                    ..partyType = row['type']
                    ..openingBalance = 25000.0 // Demo balance
                    ..balanceType = 'Dr';
                  
                  await repo.create(party);
                  count++;
                }

                // Refresh search
                ref.read(partySearchProvider.notifier).setQuery('');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported $count parties offline.')),
                  );
                }
              } catch (e) {
                ErrorDialog.show(context, title: 'Import Failed', message: e.toString());
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(partySearchProvider);
    final partiesFuture = ref.watch(filteredPartiesProvider);
    final nearbyPartiesAsync = ref.watch(nearbyPartyProvider);
    final balanceCache = ref.watch(partyBalanceCacheProvider).valueOrNull ?? {};
    
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: ResponsiveLayout.isMobile(context) ? 44 : 52,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search name, code, phone, city...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  ref.read(partySearchProvider.notifier).setQuery(value);
                },
              )
            : Text(
                'Parties Directory',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isMobile(context) ? 15 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          // 🔍 Search Toggle Button
          IconButton(
            tooltip: 'Search Parties',
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(partySearchProvider.notifier).setQuery('');
                }
              });
            },
          ),

          // ⚡ Filter & Sort Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Filter & Sort Parties',
            onSelected: (val) {
              if (val.startsWith('type:')) {
                ref.read(partySearchProvider.notifier).setFilterType(val.replaceFirst('type:', ''));
              } else {
                ref.read(partySearchProvider.notifier).setSortBy(val);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'type:All', child: Text('Show All Types')),
              const PopupMenuItem(value: 'type:Customer', child: Text('Customers Only')),
              const PopupMenuItem(value: 'type:Supplier', child: Text('Suppliers Only')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'Recent', child: Text('Sort by Recent')),
              const PopupMenuItem(value: 'Outstanding', child: Text('Sort by Outstanding')),
              const PopupMenuItem(value: 'City', child: Text('Sort by City')),
            ],
          ),

          // ⋮ 3-Dot Options & Tools Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'Tools & Export',
            onSelected: (value) {
              switch (value) {
                case 'sample':
                  _downloadPartySampleExcel();
                  break;
                case 'import_excel':
                  _importPartyExcel();
                  break;
                case 'gps':
                  setState(() {
                    _isNearbyMode = !_isNearbyMode;
                  });
                  if (_isNearbyMode) {
                    ref.read(nearbyPartyProvider.notifier).findNearbyParties();
                  }
                  break;
                case 'pdf':
                  partiesFuture.whenData((list) {
                    if (list.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No parties available to export.')),
                      );
                      return;
                    }
                    ExcelCsvHelper.exportPartiesToPdf(list);
                  });
                  break;
                case 'csv_demo':
                  _importCsvDemo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Sample Excel Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_excel',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_rounded, size: 18, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Import Parties Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'gps',
                child: Row(
                  children: [
                    Icon(_isNearbyMode ? Icons.map_rounded : Icons.my_location_rounded, size: 18, color: Colors.purple),
                    const SizedBox(width: 10),
                    Text(_isNearbyMode ? 'Show All Parties' : 'Find Nearby GPS Parties'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Export PDF Directory'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv_demo',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 18, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Import Demo CSV'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditPartyScreen(),
            ),
          ).then((_) {
            ref.read(partySearchProvider.notifier).setQuery(_searchController.text);
          });
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Party'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),

          // Filtering Chips bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip(label: 'All Types', value: 'All', activeValue: searchState.filterType ?? 'All', onSelected: (val) {
                  ref.read(partySearchProvider.notifier).setFilterType(val);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Customers', value: 'Customer', activeValue: searchState.filterType ?? 'All', onSelected: (val) {
                  ref.read(partySearchProvider.notifier).setFilterType(val);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Suppliers', value: 'Supplier', activeValue: searchState.filterType ?? 'All', onSelected: (val) {
                  ref.read(partySearchProvider.notifier).setFilterType(val);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Retailers', value: 'Retailer', activeValue: searchState.filterType ?? 'All', onSelected: (val) {
                  ref.read(partySearchProvider.notifier).setFilterType(val);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Wholesalers', value: 'Wholesaler', activeValue: searchState.filterType ?? 'All', onSelected: (val) {
                  ref.read(partySearchProvider.notifier).setFilterType(val);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List Body
          Expanded(
            child: _isNearbyMode
                ? _buildNearbyListView(nearbyPartiesAsync)
                : _buildStandardListView(partiesFuture),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String activeValue,
    required ValueChanged<String> onSelected,
  }) {
    final selected = value == activeValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) => onSelected(value),
    );
  }

  Widget _buildStandardListView(AsyncValue<List<Party>> partiesFuture) {
    return partiesFuture.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No parties found matching filters.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final party = list[index];
            return _buildPartyCard(party, balanceCache: balanceCache);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading parties: $err')),
    );
  }

  Widget _buildNearbyListView(AsyncValue<List<NearbyParty>> nearbyAsync) {
    return nearbyAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No parties have GPS coordinates captured.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return _buildPartyCard(
              item.party,
              distanceBadge: DistanceCalculator.formatDistance(item.distanceInMeters),
              balanceCache: balanceCache,
            );
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Acquiring GPS coordinates & calculating distances...'),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'GPS Error: ${err.toString()}\nEnsure GPS permissions are enabled.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // _getRealPartyBalance REMOVED — replaced by partyBalanceCacheProvider (single-pass cache)

  Widget _buildPartyCard(Party party, {String? distanceBadge, Map<String, double> balanceCache = const {}}) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final rawOut = party.outstandingBalance ?? 0.0;
    final rawOpen = party.openingBalance ?? 0.0;
    final fallbackBal = (rawOut != 0.0) ? rawOut : rawOpen;
    final isReceivable = party.partyType != 'Supplier' && (party.balanceType == 'Dr' || fallbackBal >= 0);
    final glowColor = isReceivable ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    
    // Use pre-computed balance cache (instant O(1) lookup instead of per-card DB scan)
    final cacheKey = party.partyType == 'Supplier'
        ? 'supp_${party.partyName?.trim().toLowerCase() ?? ""}'
        : party.partyName?.trim().toLowerCase() ?? '';
    final balance = balanceCache[cacheKey] ?? fallbackBal;
    
    final VoidCallback handleTap = () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PartyDetailScreen(partyUuid: party.uuid!),
        ),
      ).then((_) {
        ref.read(partySearchProvider.notifier).setQuery(_searchController.text);
      });
    };

    final cardContent = Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Row(
        children: [
          Container(
            width: isMobile ? 38 : 44,
            height: isMobile ? 38 : 44,
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                party.partyName != null && party.partyName!.isNotEmpty
                    ? party.partyName![0].toUpperCase()
                    : 'P',
                style: TextStyle(
                  color: glowColor,
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 15 : 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        party.partyName ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 13.5 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (distanceBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          distanceBadge,
                          style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        party.partyType ?? 'Customer',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Code: ${party.partyCode ?? "N/A"}' +
                        (party.mobileNumber != null && party.mobileNumber!.isNotEmpty ? ' • 📞 ${party.mobileNumber}' : ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 13.5 : 15,
                  color: isReceivable ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReceivable ? 'Receivable' : 'Payable',
                  style: TextStyle(fontSize: 9.5, color: glowColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: isMobile
          ? LiquidGlassCard(
              onTap: handleTap,
              accentGlowColor: glowColor,
              padding: EdgeInsets.zero,
              lightweight: true, // Skip BackdropFilter for smooth 60fps scroll
              child: cardContent,
            )
          : AnimatedHoverCard(
              glowColor: glowColor,
              onTap: handleTap,
              child: cardContent,
            ),
    );
  }
}
