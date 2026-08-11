import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);
    final invoicesAsync = ref.watch(filteredInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Receivable (Customer Dues)'),
        elevation: 0,
      ),
      body: partiesAsync.when(
        data: (allParties) {
          final invoices = invoicesAsync.asData?.value ?? [];
          final Map<String, double> partyUuidDues = {};
          final Map<int, double> partyIdDues = {};

          for (var inv in invoices) {
            final pending = inv.pendingAmount ?? 
                ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0));
            if (pending > 0 && (inv.paymentStatus == 'Unpaid' || inv.paymentStatus == 'Partially Paid' || inv.paymentStatus == null)) {
              if (inv.partyUuid != null && inv.partyUuid!.isNotEmpty) {
                partyUuidDues[inv.partyUuid!] = (partyUuidDues[inv.partyUuid!] ?? 0.0) + pending;
              }
              if (inv.partyId != null && inv.partyId! > 0) {
                partyIdDues[inv.partyId!] = (partyIdDues[inv.partyId!] ?? 0.0) + pending;
              }
            }
          }

          double getPartyDue(Party p) {
            final uuidDue = p.uuid != null ? (partyUuidDues[p.uuid] ?? 0.0) : 0.0;
            final idDue = p.id > 0 ? (partyIdDues[p.id] ?? 0.0) : 0.0;
            final invoiceDue = uuidDue > 0 ? uuidDue : idDue;
            if (invoiceDue > 0) return invoiceDue;
            if (p.outstandingBalance != null && p.outstandingBalance! != 0) return p.outstandingBalance!;
            return p.openingBalance ?? 0.0;
          }

          final customerParties = allParties
              .where((p) => p.partyType != 'Supplier' && getPartyDue(p) > 0)
              .toList();

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
              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PENDING RECEIVABLES',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalReceivables.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customerParties.length} Customers with pending dues',
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
                        hintText: 'Search customer name, phone, city...',
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
