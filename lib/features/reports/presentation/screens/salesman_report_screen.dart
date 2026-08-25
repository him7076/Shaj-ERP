import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class SalesmanReportScreen extends ConsumerStatefulWidget {
  const SalesmanReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesmanReportScreen> createState() => _SalesmanReportScreenState();
}

class _SalesmanReportScreenState extends ConsumerState<SalesmanReportScreen> {
  bool _isLoading = false;
  String _selectedSalesman = 'All';
  List<String> _salesmenList = ['All'];

  List<Order> _allOrders = [];
  List<Invoice> _allInvoices = [];

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final prefs = ref.read(sharedPreferencesProvider);

      final customS = prefs.getStringList('custom_salesmen_list') ?? [];
      final salesmen = ['All', 'Default Salesman', 'Salesperson 1', 'Salesperson 2', ...customS].toSet().toList();

      final orders = await isar.orders.filter().isDeletedEqualTo(false).findAll();
      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();

      // Collect any additional createdBy names found in database
      for (var o in orders) {
        if (o.createdBy != null && o.createdBy!.isNotEmpty && !salesmen.contains(o.createdBy)) {
          salesmen.add(o.createdBy!);
        }
      }
      for (var i in invoices) {
        if (i.createdBy != null && i.createdBy!.isNotEmpty && !salesmen.contains(i.createdBy)) {
          salesmen.add(i.createdBy!);
        }
      }

      setState(() {
        _salesmenList = salesmen;
        _allOrders = orders;
        _allInvoices = invoices;
      });
    } catch (e) {
      // Quietly handle
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filter orders and invoices based on selected salesman
    final filteredOrders = _allOrders.where((o) {
      if (_selectedSalesman == 'All') return true;
      return o.createdBy == _selectedSalesman;
    }).toList();

    final filteredInvoices = _allInvoices.where((i) {
      if (_selectedSalesman == 'All') return true;
      return i.createdBy == _selectedSalesman;
    }).toList();

    final double totalOrdersVal = filteredOrders.fold(0.0, (sum, o) => sum + (o.grandTotal ?? 0.0));
    final double totalInvoicesVal = filteredInvoices.fold(0.0, (sum, i) => sum + (i.grandTotal ?? 0.0));
    final double combinedRevenue = totalOrdersVal + totalInvoicesVal;

    // Build Salesman Performance Map for breakdown table
    final Map<String, Map<String, dynamic>> salesmanStats = {};
    for (var s in _salesmenList.where((s) => s != 'All')) {
      final sOrders = _allOrders.where((o) => o.createdBy == s || (s == 'Default Salesman' && (o.createdBy == null || o.createdBy!.isEmpty))).toList();
      final sInvoices = _allInvoices.where((i) => i.createdBy == s || (s == 'Default Salesman' && (i.createdBy == null || i.createdBy!.isEmpty))).toList();

      final oVal = sOrders.fold(0.0, (sum, o) => sum + (o.grandTotal ?? 0.0));
      final iVal = sInvoices.fold(0.0, (sum, i) => sum + (i.grandTotal ?? 0.0));

      salesmanStats[s] = {
        'ordersCount': sOrders.length,
        'ordersVal': oVal,
        'invoicesCount': sInvoices.length,
        'invoicesVal': iVal,
        'totalRevenue': oVal + iVal,
      };
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Salesman Wise Performance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: Colors.teal),
                    const SizedBox(width: 12),
                    const Text('Filter by Salesman: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSalesman,
                        isDense: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSalesman = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KPI Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard('Total Revenue', currencyFormat.format(combinedRevenue), Icons.payments, Colors.green),
                _buildStatCard('Total Orders', '${filteredOrders.length}', Icons.shopping_cart, Colors.teal),
                _buildStatCard('Orders Value', currencyFormat.format(totalOrdersVal), Icons.monetization_on, Colors.blue),
                _buildStatCard('Invoices Value', currencyFormat.format(totalInvoicesVal), Icons.receipt_long, Colors.purple),
              ],
            ),
            const SizedBox(height: 28),

            // Salesman Performance Summary Table
            Text(
              'Salesperson Performance Leaderboard',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Salesman Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Orders', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Order Value (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Invoice Value (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total Revenue (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: salesmanStats.entries.map((entry) {
                    final name = entry.key;
                    final stats = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text('${stats['ordersCount']}')),
                        DataCell(Text(currencyFormat.format(stats['ordersVal']))),
                        DataCell(Text('${stats['invoicesCount']}')),
                        DataCell(Text(currencyFormat.format(stats['invoicesVal']))),
                        DataCell(
                          Text(
                            currencyFormat.format(stats['totalRevenue']),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Detailed Recent Activity Log by Salesman
            Text(
              'Recent Orders & Invoices Log (${_selectedSalesman})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (filteredOrders.isEmpty && filteredInvoices.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No orders or invoices recorded for this salesman.')),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length + filteredInvoices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index < filteredOrders.length) {
                    final order = filteredOrders[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2F1),
                          child: Icon(Icons.shopping_cart, color: Colors.teal, size: 20),
                        ),
                        title: Text('Order #${order.orderNumber} - ${order.partyName ?? "N/A"}'),
                        subtitle: Text('Date: ${order.orderDate != null ? DateFormat('dd-MM-yyyy').format(order.orderDate!) : "N/A"} | Salesman: ${order.createdBy ?? "Default"}'),
                        trailing: Text(
                          currencyFormat.format(order.grandTotal ?? 0.0),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    );
                  } else {
                    final inv = filteredInvoices[index - filteredOrders.length];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF3E5F5),
                          child: Icon(Icons.receipt_long, color: Colors.purple, size: 20),
                        ),
                        title: Text('Invoice #${inv.invoiceNumber} - ${inv.partyName ?? "N/A"}'),
                        subtitle: Text('Date: ${inv.invoiceDate != null ? DateFormat('dd-MM-yyyy').format(inv.invoiceDate!) : "N/A"} | Salesman: ${inv.createdBy ?? "Default"}'),
                        trailing: Text(
                          currencyFormat.format(inv.grandTotal ?? 0.0),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
