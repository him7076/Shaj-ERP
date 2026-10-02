import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

enum DuesSortOption { highestDues, lowestDues, partyName }

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  String _searchQuery = '';
  DuesSortOption _sortOption = DuesSortOption.highestDues;
  String _selectedCity = 'All';
  bool _isSearchVisible = false;
  bool _isFilterVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        toolbarHeight: 44,
        title: const Text('Accounts Receivable (Customer Dues)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isSearchVisible ? 'Close Search' : 'Search Customers',
            icon: Icon(_isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded),
            onPressed: () => setState(() => _isSearchVisible = !_isSearchVisible),
          ),
          IconButton(
            tooltip: _isFilterVisible ? 'Hide Filters' : 'Show Filters',
            icon: Icon(
              _isFilterVisible ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
              color: (_selectedCity != 'All' || _sortOption != DuesSortOption.highestDues) ? theme.colorScheme.primary : null,
            ),
            onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
          ),
        ],
      ),
      body: partiesAsync.when(
        data: (allParties) {
          final balanceCache = ref.watch(partyBalanceCacheProvider).valueOrNull ?? {};
          double getPartyDue(Party p) {
            final keyName = p.partyName?.trim().toLowerCase() ?? '';
            final bal = balanceCache[p.uuid] ?? balanceCache[p.id.toString()] ?? balanceCache[keyName] ?? p.outstandingBalance ?? p.openingBalance ?? 0.0;
            if (bal > 0) return bal; // Receivable amount is positive here
            return 0.0;
          }

          final customerParties = allParties.where((p) => getPartyDue(p) > 0).toList();
          
          final cities = {'All', ...customerParties.map((p) => p.city ?? 'Unassigned').where((l) => l.isNotEmpty)};

          // Filter by search query & city
          var filtered = customerParties.where((p) {
            final query = _searchQuery.toLowerCase();
            final matchesQuery = (p.partyName?.toLowerCase().contains(query) ?? false) ||
                (p.mobileNumber?.contains(query) ?? false) ||
                (p.city?.toLowerCase().contains(query) ?? false);

            final matchesCity = _selectedCity == 'All' || (p.city ?? 'Unassigned') == _selectedCity;

            return matchesQuery && matchesCity;
          }).toList();

          // Sort
          if (_sortOption == DuesSortOption.highestDues) {
            filtered.sort((a, b) => getPartyDue(b).compareTo(getPartyDue(a)));
          } else if (_sortOption == DuesSortOption.lowestDues) {
            filtered.sort((a, b) => getPartyDue(a).compareTo(getPartyDue(b)));
          } else if (_sortOption == DuesSortOption.partyName) {
            filtered.sort((a, b) => (a.partyName ?? '').compareTo(b.partyName ?? ''));
          }

          final totalReceivables = customerParties.fold(0.0, (sum, p) => sum + getPartyDue(p));

          return Column(
            children: [
              // Compact Sleek Summary Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PENDING RECEIVABLES',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customerParties.length} Customers with pending dues',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '₹${totalReceivables.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Search & Filter Toolbar (Toggleable from AppBar)
              if (_isSearchVisible || _searchQuery.isNotEmpty || _isFilterVisible || _selectedCity != 'All' || _sortOption != DuesSortOption.highestDues)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    children: [
                      if (_isSearchVisible || _searchQuery.isNotEmpty) ...[
                        SizedBox(
                          height: 40,
                          child: TextField(
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search customer name, phone, city...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        if (_isFilterVisible || _selectedCity != 'All' || _sortOption != DuesSortOption.highestDues)
                          const SizedBox(height: 8),
                      ],
                      if (_isFilterVisible || _selectedCity != 'All' || _sortOption != DuesSortOption.highestDues)
                        ResponsiveFormRow(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: DropdownButtonFormField<String>(
                                  value: cities.contains(_selectedCity) ? _selectedCity : 'All',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    labelText: 'Filter City',
                                    
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  items: cities.map((l) => DropdownMenuItem<String>(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCity = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: DropdownButtonFormField<DuesSortOption>(
                                  value: _sortOption,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    labelText: 'Sort By',
                                    
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: DuesSortOption.highestDues, child: Text('Highest Due Amount', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: DuesSortOption.lowestDues, child: Text('Lowest Due Amount', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: DuesSortOption.partyName, child: Text('Party Name (A-Z)', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _sortOption = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              // Party Dues List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            const Text('No pending customer receivables!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final party = filtered[index];
                          final due = getPartyDue(party);
                          final initial = (party.partyName?.isNotEmpty == true) ? party.partyName![0].toUpperCase() : 'C';

                          return NeuCard(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ListTile(
                              onTap: () {
                                context.push('/parties/detail/${party.id}');
                              },
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                              ),
                              title: Text(party.partyName ?? 'Unnamed Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${party.mobileNumber ?? "No Phone"} | City: ${party.city ?? "N/A"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${due.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('DUE RECEIVABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
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
        error: (e, _) => Center(child: Text('Error loading receivables: $e')),
      ),
    );
  }
}
