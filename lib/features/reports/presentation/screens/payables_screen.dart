import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';

enum DuesSortOption { highestDues, lowestDues, partyName }

class PayablesScreen extends ConsumerStatefulWidget {
  const PayablesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PayablesScreen> createState() => _PayablesScreenState();
}

class _PayablesScreenState extends ConsumerState<PayablesScreen> {
  String _searchQuery = '';
  DuesSortOption _sortOption = DuesSortOption.highestDues;
  String _selectedCity = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);
    final purchasesAsync = ref.watch(purchaseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Payable (Supplier Dues)'),
        elevation: 0,
      ),
      body: partiesAsync.when(
        data: (allParties) {
          final purchases = purchasesAsync.asData?.value ?? [];
          final Map<String, double> partyUuidDues = {};
          final Map<int, double> partyIdDues = {};

          for (var pur in purchases) {
            final pending = pur.pendingAmount ?? 
                ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0));
            if (pending > 0 && (pur.paymentStatus == 'Unpaid' || pur.paymentStatus == 'Partially Paid' || pur.paymentStatus == null)) {
              if (pur.partyUuid != null && pur.partyUuid!.isNotEmpty) {
                partyUuidDues[pur.partyUuid!] = (partyUuidDues[pur.partyUuid!] ?? 0.0) + pending;
              }
              if (pur.partyId != null && pur.partyId! > 0) {
                partyIdDues[pur.partyId!] = (partyIdDues[pur.partyId!] ?? 0.0) + pending;
              }
            }
          }

          double getPartyDue(Party p) {
            final uuidDue = p.uuid != null ? (partyUuidDues[p.uuid] ?? 0.0) : 0.0;
            final idDue = p.id > 0 ? (partyIdDues[p.id] ?? 0.0) : 0.0;
            final purchaseDue = uuidDue > 0 ? uuidDue : idDue;
            if (purchaseDue > 0) return purchaseDue;
            if (p.outstandingBalance != null && p.outstandingBalance! != 0) return p.outstandingBalance!;
            return p.openingBalance ?? 0.0;
          }

          final supplierParties = allParties
              .where((p) => p.partyType == 'Supplier' && getPartyDue(p) > 0)
              .toList();

          final cities = {'All', ...supplierParties.map((p) => p.city ?? 'Unassigned').where((l) => l.isNotEmpty)};

          // Filter by search query & city
          var filtered = supplierParties.where((p) {
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

          final totalPayables = supplierParties.fold(0.0, (sum, p) => sum + getPartyDue(p));

          return Column(
            children: [
              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade900],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PENDING PAYABLES',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalPayables.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${supplierParties.length} Suppliers to be paid',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Search & Filter Toolbar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search supplier name, phone, city...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: cities.contains(_selectedCity) ? _selectedCity : 'All',
                            decoration: const InputDecoration(
                              labelText: 'Filter City / Region',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: cities.map((l) => DropdownMenuItem<String>(value: l, child: Text(l))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCity = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<DuesSortOption>(
                            value: _sortOption,
                            decoration: const InputDecoration(
                              labelText: 'Sort By',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: DuesSortOption.highestDues, child: Text('Highest Due Amount')),
                              DropdownMenuItem(value: DuesSortOption.lowestDues, child: Text('Lowest Due Amount')),
                              DropdownMenuItem(value: DuesSortOption.partyName, child: Text('Party Name (A-Z)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sortOption = val);
                            },
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
                            const Text('No pending supplier payables!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          final initial = (party.partyName?.isNotEmpty == true) ? party.partyName![0].toUpperCase() : 'S';

                          return Card(
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
                                backgroundColor: Colors.red.shade100,
                                child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              ),
                              title: Text(party.partyName ?? 'Unnamed Supplier', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('DUE PAYABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
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
        error: (e, _) => Center(child: Text('Error loading payables: $e')),
      ),
    );
  }
}
