import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/add_edit_order_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(orderSearchFilterProvider);
    final ordersAsync = ref.watch(filteredOrdersProvider);
    final partiesAsync = ref.watch(partiesListProvider);
    final userRoleAsync = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(filteredOrdersProvider);
            },
            tooltip: 'Refresh Registry',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Order #, Customer Name, Mobile...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(orderSearchFilterProvider.notifier).update((state) => state.copyWith(query: ''));
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
                      ref.read(orderSearchFilterProvider.notifier).update((state) => state.copyWith(query: val));
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

          // Filters Panel
          if (_showFilters) _buildFilterPanel(theme, filter, partiesAsync),

          // Order list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No orders found matching filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Sales Order'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditOrderScreen(),
                              ),
                            ).then((_) => ref.invalidate(filteredOrdersProvider));
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load orders: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Order'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditOrderScreen(),
            ),
          ).then((_) => ref.invalidate(filteredOrdersProvider));
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    OrderSearchFilter filter,
    AsyncValue<List<Party>> partiesAsync,
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
        children: [
          Row(
            children: [
              // Status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.status,
                  decoration: const InputDecoration(
                    labelText: 'Order Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending Approval')),
                    DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'Converted To Sale', child: Text('Converted to Sale')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(orderSearchFilterProvider.notifier).update((state) => state.copyWith(status: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Sorting
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
                    DropdownMenuItem(value: 'Recent', child: Text('Recent Date')),
                    DropdownMenuItem(value: 'Amount High-Low', child: Text('Amount (High-Low)')),
                    DropdownMenuItem(value: 'Amount Low-High', child: Text('Amount (Low-High)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(orderSearchFilterProvider.notifier).update((state) => state.copyWith(sortBy: v));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Customer Selection
              Expanded(
                child: partiesAsync.when(
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
                        ref.read(orderSearchFilterProvider.notifier).update((state) => state.copyWith(partyId: v));
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 8),

              // Reset filters button
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: () {
                  _searchController.clear();
                  ref.read(orderSearchFilterProvider.notifier).state = const OrderSearchFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    switch (order.status) {
      case 'Draft':
        statusColor = Colors.blue;
        statusIcon = Icons.edit_note;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'Converted To Sale':
        statusColor = Colors.purple;
        statusIcon = Icons.receipt_long;
        break;
    }

    final dateStr = order.orderDate?.toIso8601String().substring(0, 10) ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderUuid: order.uuid!),
            ),
          ).then((_) => ref.invalidate(filteredOrdersProvider));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading Status Circle
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),

              // Body Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.orderNumber ?? 'N/A',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${order.grandTotal?.toStringAsFixed(2) ?? "0.00"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.partyName ?? 'Unknown Party',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Date: $dateStr | Items: ${order.orderItems.length}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
