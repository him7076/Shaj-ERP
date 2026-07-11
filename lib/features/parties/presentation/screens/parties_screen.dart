import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/core/utils/excel_csv_helper.dart';
import 'package:business_sahaj_erp/core/utils/distance_calculator.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties Directory'),
        actions: [
          // GPS Location nearby filter button
          IconButton(
            tooltip: _isNearbyMode ? 'Show All Parties' : 'Find Nearby Parties',
            icon: Icon(
              _isNearbyMode ? Icons.map_rounded : Icons.my_location_rounded,
              color: _isNearbyMode ? theme.colorScheme.primaryContainer : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isNearbyMode = !_isNearbyMode;
              });
              if (_isNearbyMode) {
                ref.read(nearbyPartyProvider.notifier).findNearbyParties();
              }
            },
          ),
          
          // PDF Export
          IconButton(
            tooltip: 'Export PDF List',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              partiesFuture.whenData((list) {
                if (list.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No parties available to export.')),
                  );
                  return;
                }
                ExcelCsvHelper.exportPartiesToPdf(list);
              });
            },
          ),

          // Import CSV
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importCsvDemo,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditPartyScreen(),
            ),
          ).then((_) {
            // Trigger refresh
            ref.read(partySearchProvider.notifier).setQuery(_searchController.text);
          });
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Party'),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search by name, code, phone, or city...',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(partySearchProvider.notifier).setQuery('');
                          },
                        ),
                    ],
                    onChanged: (val) {
                      ref.read(partySearchProvider.notifier).setQuery(val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Sort Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Parties',
                  onSelected: (val) {
                    ref.read(partySearchProvider.notifier).setSortBy(val);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
                    const PopupMenuItem(value: 'Recent', child: Text('Sort by Recent')),
                    const PopupMenuItem(value: 'Outstanding', child: Text('Sort by Outstanding')),
                    const PopupMenuItem(value: 'City', child: Text('Sort by City')),
                  ],
                ),
              ],
            ),
          ),

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
            return _buildPartyCard(party);
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

  Widget _buildPartyCard(Party party, {String? distanceBadge}) {
    final theme = Theme.of(context);
    final balance = party.openingBalance ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PartyDetailScreen(partyUuid: party.uuid!),
            ),
          ).then((_) {
            // Trigger refresh
            ref.read(partySearchProvider.notifier).setQuery(_searchController.text);
          });
        },
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            party.partyName != null && party.partyName!.isNotEmpty
                ? party.partyName![0].toUpperCase()
                : 'P',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                party.partyName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (distanceBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distanceBadge,
                  style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code: ${party.partyCode ?? "N/A"} • Type: ${party.partyType}'),
              const SizedBox(height: 2),
              Text(
                'Phone: ${party.mobileNumber ?? "N/A"}' +
                (party.city != null && party.city!.isNotEmpty ? ' • City: ${party.city}' : ''),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: party.balanceType == 'Dr' ? Colors.red[700] : Colors.green[700],
              ),
            ),
            Text(
              party.balanceType == 'Dr' ? 'Receivable' : 'Payable',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
