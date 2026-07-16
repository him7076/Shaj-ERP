import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';

class SalesScreen extends ConsumerStatefulWidget {
  final bool createImmediately;
  const SalesScreen({Key? key, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    if (widget.createImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditInvoiceScreen(),
          ),
        ).then((_) => ref.invalidate(filteredInvoicesProvider));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(invoiceSearchFilterProvider);
    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final partiesAsync = ref.watch(partiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoice Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(filteredInvoicesProvider);
            },
            tooltip: 'Refresh Invoices',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Invoice #, Customer Name, GST...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(query: ''));
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    onChanged: (val) {
                      ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(query: val));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters panel
          if (_showFilters) _buildFilterPanel(theme, filter, partiesAsync),

          // Invoice List
          Expanded(
            child: invoicesAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No invoices found matching filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Record Direct Sales Invoice'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditInvoiceScreen(),
                              ),
                            ).then((_) => ref.invalidate(filteredInvoicesProvider));
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final invoice = list[index];
                    return _buildInvoiceCard(invoice, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load invoices: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Direct Invoice'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditInvoiceScreen(),
            ),
          ).then((_) => ref.invalidate(filteredInvoicesProvider));
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    InvoiceSearchFilter filter,
    AsyncValue<List<Party>> partiesAsync,
  ) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final paymentStatusDropdown = DropdownButtonFormField<String>(
      value: filter.paymentStatus,
      decoration: const InputDecoration(
        labelText: 'Payment Status',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Payments')),
        DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid (Credit)')),
        DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
        DropdownMenuItem(value: 'Paid', child: Text('Paid (Cash)')),
        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(paymentStatus: v));
        }
      },
    );

    final sortByDropdown = DropdownButtonFormField<String>(
      value: filter.sortBy,
      decoration: const InputDecoration(
        labelText: 'Sort By',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Date', child: Text('Invoice Date')),
        DropdownMenuItem(value: 'Amount High-Low', child: Text('Amount (High-Low)')),
        DropdownMenuItem(value: 'Amount Low-High', child: Text('Amount (Low-High)')),
        DropdownMenuItem(value: 'Due Date', child: Text('Credit Due Date')),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(sortBy: v));
        }
      },
    );

    final partyDropdown = partiesAsync.when(
      data: (parties) {
        return DropdownButtonFormField<int?>(
          value: filter.partyId,
          decoration: const InputDecoration(
            labelText: 'Customer Account',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All Customers')),
            ...parties.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.partyName ?? ''))),
          ],
          onChanged: (v) {
            ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(partyId: v));
          },
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const Icon(Icons.error),
    );

    final resetFiltersButton = TextButton.icon(
      icon: const Icon(Icons.refresh),
      label: const Text('Reset'),
      onPressed: () {
        _searchController.clear();
        ref.read(invoiceSearchFilterProvider.notifier).state = const InvoiceSearchFilter();
      },
    );

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                paymentStatusDropdown,
                const SizedBox(height: 10),
                sortByDropdown,
                const SizedBox(height: 10),
                partyDropdown,
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: resetFiltersButton,
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: paymentStatusDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: sortByDropdown),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: partyDropdown),
                    const SizedBox(width: 8),
                    resetFiltersButton,
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, ThemeData theme) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    switch (invoice.paymentStatus) {
      case 'Unpaid':
        statusColor = Colors.red;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Partially Paid':
        statusColor = Colors.orange;
        statusIcon = Icons.payments_outlined;
        break;
      case 'Paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    final dateStr = invoice.invoiceDate?.toIso8601String().substring(0, 10) ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
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
                color: statusColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailScreen(invoiceUuid: invoice.uuid!),
                      ),
                    ).then((_) => ref.invalidate(filteredInvoicesProvider));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.08),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    invoice.invoiceNumber ?? 'N/A',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${invoice.grandTotal?.toStringAsFixed(2) ?? "0.00"}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                invoice.partyName ?? 'Unknown Party',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Date: $dateStr | Type: ${invoice.invoiceType ?? "Tax Invoice"}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      invoice.paymentStatus ?? 'Pending',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
