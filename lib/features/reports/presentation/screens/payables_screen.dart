import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

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

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Accounts Payable (Supplier Dues)'),
        elevation: 0,
      ),
      body: partiesAsync.when(
        data: (allParties) {
          final isar = ref.read(databaseServiceProvider).isar;
          return FutureBuilder<List<Purchase>>(
            future: isar.purchases.filter()
                .isDeletedEqualTo(false)
                .and()
                .not().paymentStatusEqualTo('Cancelled')
                .and()
                .group((q) => q.paymentStatusEqualTo('Unpaid').or().paymentStatusEqualTo('Partially Paid'))
                .findAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final purchases = snapshot.data ?? [];
              final Map<String, double> partyUuidDues = {};
              final Map<String, double> partyNameDues = {};

              final Map<int, String> partyIdToUuid = {
                for (var p in allParties)
                  if (p.id != null && p.uuid != null) p.id!: p.uuid!
              };

              for (var pur in purchases) {
                if (pur.paymentStatus == 'Cancelled') continue;
                final pending = pur.pendingAmount ?? 
                    ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0));
                if (pending > 0) {
                  final pUuid = pur.partyId != null ? partyIdToUuid[pur.partyId!] : null;
                  if (pUuid != null && pUuid.isNotEmpty) {
                    partyUuidDues[pUuid] = (partyUuidDues[pUuid] ?? 0.0) + pending;
                  }
                  if (pur.partyName != null && pur.partyName!.trim().isNotEmpty) {
                    final nameKey = pur.partyName!.trim().toLowerCase();
                    partyNameDues[nameKey] = (partyNameDues[nameKey] ?? 0.0) + pending;
                  }
                }
              }

              double getPartyDue(Party p) {
                final hasUuid = p.uuid != null && p.uuid!.isNotEmpty;
                final uDue = hasUuid ? (partyUuidDues[p.uuid] ?? 0.0) : 0.0;
                final nameKey = p.partyName?.trim().toLowerCase() ?? '';
                final nDue = nameKey.isNotEmpty ? (partyNameDues[nameKey] ?? 0.0) : 0.0;
                final purchaseDue = uDue > 0 ? uDue : nDue;

                if (purchaseDue > 0) return purchaseDue;
                final rawOut = p.outstandingBalance ?? 0.0;
                if (rawOut > 0) return rawOut;
                return p.openingBalance ?? 0.0;
              }

          final supplierParties = allParties.where((p) {
            final due = getPartyDue(p);
            if (due <= 0) return false;
            final type = (p.partyType ?? '').trim().toLowerCase();
            return type == 'supplier' || type == 'vendor' || type == 'both' || p.balanceType == 'credit' || (due > 0 && type != 'customer');
          }).toList();

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
              // Compact Sleek Summary Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade900],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PENDING PAYABLES',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${supplierParties.length} Suppliers to be paid',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '₹${totalPayables.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Search & Filter Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: TextField(
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search supplier name, phone, city...',
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: DropdownButtonFormField<String>(
                              value: cities.contains(_selectedCity) ? _selectedCity : 'All',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              decoration: const InputDecoration(
                                labelText: 'Filter City',
                                border: OutlineInputBorder(),
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
                                border: OutlineInputBorder(),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading payables: $e')),
      ),
    );
  }
}
