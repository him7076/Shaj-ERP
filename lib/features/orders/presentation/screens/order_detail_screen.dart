import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/add_edit_order_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/services/pdf_service.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/models/firm_info.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderUuid;

  const OrderDetailScreen({Key? key, required this.orderUuid}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = false;
  Order? _order;
  List<OrderItem> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final fetched = await isar.orders.filter().uuidEqualTo(widget.orderUuid).findFirst();
      if (fetched != null) {
        List<OrderItem> items = [];
        try {
          await fetched.party.load();
        } catch (_) {}

        if (!kIsWeb) {
          try {
            await fetched.orderItems.load();
            items = fetched.orderItems.where((i) => !i.isDeleted).toList();
          } catch (_) {}
        }

        if (items.isEmpty) {
          final targetUuid = fetched.uuid;
          final targetId = fetched.id;
          final allItems = await isar.orderItems.filter().isDeletedEqualTo(false).findAll();
          items = allItems.where((i) {
            if (targetUuid != null && targetUuid.isNotEmpty && i.orderUuid == targetUuid) return true;
            if (targetId > 0 && (i.orderId == targetId || i.order.value?.id == targetId)) return true;
            return false;
          }).toList();
        }

        setState(() {
          _order = fetched;
          _orderItems = items;
        });
      }
    } catch (e) {
      logger.error('Failed to load order detail', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel Sales Order'),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Enter why this order is cancelled',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );

    if (confirm == true && _order != null) {
      setState(() => _isLoading = true);
      try {
        final authState = ref.read(authProvider);
        final userEmail = authState.email ?? 'salesman@sahaj.com';

        final repo = ref.read(orderRepositoryProvider);
        await repo.cancelOrder(
          _order!.uuid!,
          reasonController.text.trim(),
          userEmail,
        );

        await _loadOrder();
        ref.invalidate(filteredOrdersProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to cancel order', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _convertToSale() async {
    if (_order == null) return;

    final converted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditInvoiceScreen(sourceOrderUuid: _order!.uuid),
      ),
    );

    if (converted == true && mounted) {
      await _loadOrder();
      ref.invalidate(filteredOrdersProvider);
      ref.invalidate(filteredInvoicesProvider);
    }
  }

  Future<void> _generatePdf() async {
    if (_order == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfService = PdfService();
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final firmInfo = await FirmInfo.getActiveFirmInfo(prefs, isar);
      
      final pdfData = await pdfService.generateOrderPdf(_order!, firmInfo: firmInfo);
      await pdfService.printOrSharePdf(pdfData, 'Order_${_order!.orderNumber}.pdf');
    } catch (e) {
      logger.error('Failed to print PDF', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_order == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfService = PdfService();
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final firmInfo = await FirmInfo.getActiveFirmInfo(prefs, isar);
      
      final pdfData = await pdfService.generateOrderPdf(_order!, firmInfo: firmInfo);
      await pdfService.sharePdf(pdfData, 'Order_${_order!.orderNumber}.pdf');
    } catch (e) {
      logger.error('Failed to share PDF', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRoleAsync = ref.watch(currentUserRoleProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Order')),
        body: const Center(child: Text('Sales order not found.')),
      );
    }

    final order = _order!;
    final isLocked = order.status == 'Cancelled' || order.status == 'Converted To Sale';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
            onPressed: _sharePdf,
            tooltip: 'Share Order PDF via WhatsApp / Apps',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _generatePdf,
            tooltip: 'Print / Download PDF',
          ),
          if (!isLocked) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditOrderScreen(orderUuid: order.uuid),
                  ),
                );
                _loadOrder();
              },
              tooltip: 'Edit Order',
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: _cancelOrder,
              tooltip: 'Cancel Order',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Card
              _buildModernHeaderCard(order, theme),
              const SizedBox(height: 16),

              // SECTION 1: Party / Customer Details
              _buildPartyDetailsCard(order, theme),
              const SizedBox(height: 16),

              // Google Maps Outlet Location Card (if location available)
              if (order.locationUrl != null || (order.latitude != null && order.longitude != null)) ...[
                _buildLocationCard(order, theme),
                const SizedBox(height: 16),
              ],

              // SECTION 2: PRODUCTS ORDERED (Item Details - Right after Party Details!)
              _buildModernItemsTable(order, theme),
              const SizedBox(height: 16),

              // SECTION 3: Financial Totals Breakdown
              _buildTotalsCard(order, theme),
              const SizedBox(height: 16),

              // SECTION 4: Order Audit Timeline
              _buildTimelineCard(order, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sharePdf,
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: const Text('Share PDF (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (!isLocked) ...[
              const SizedBox(width: 12),
              Expanded(
                child: userRoleAsync.when(
                  data: (role) {
                    final canConvert = role == 'Owner' || role == 'Staff';
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Convert to Sale'),
                      onPressed: canConvert ? _convertToSale : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeaderCard(Order order, ThemeData theme) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    if (order.status == 'Draft') { statusColor = Colors.blue; statusIcon = Icons.edit_note; }
    if (order.status == 'Pending') { statusColor = Colors.orange; statusIcon = Icons.pending_actions; }
    if (order.status == 'Confirmed') { statusColor = Colors.green; statusIcon = Icons.check_circle_outline; }
    if (order.status == 'Cancelled') { statusColor = Colors.red; statusIcon = Icons.cancel_outlined; }
    if (order.status == 'Converted To Sale') { statusColor = Colors.purple; statusIcon = Icons.task_alt; }

    final formattedDate = order.orderDate != null ? DateFormat('dd MMM yyyy').format(order.orderDate!) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Order',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '#${order.orderNumber}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  order.status?.toUpperCase() ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Date: $formattedDate', style: theme.textTheme.bodyMedium),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Items: ${_orderItems.length}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyDetailsCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF1E88E5), width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Color(0xFF1E88E5), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMER ACCOUNT (PARTY)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        order.partyName ?? 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(order.mobileNumber ?? 'N/A', style: theme.textTheme.bodyMedium),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'GSTIN: ${order.gstNumber ?? "Unregistered"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.createdBy != null && order.createdBy!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 15, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 6),
                  Text('Salesman / Rep: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(order.createdBy!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            if (order.locationAddress != null && order.locationAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.locationAddress!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Order order, ThemeData theme) {
    final hasUrl = order.locationUrl != null && order.locationUrl!.trim().isNotEmpty;
    final hasCoordinates = order.latitude != null && order.longitude != null;

    if (!hasUrl && !hasCoordinates) {
      return const SizedBox.shrink();
    }

    final targetUrl = hasUrl
        ? order.locationUrl!
        : 'https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.redAccent, width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.map_rounded, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOOGLE MAPS OUTLET LOCATION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        hasCoordinates
                            ? 'GPS Coordinates: ${order.latitude?.toStringAsFixed(5)}, ${order.longitude?.toStringAsFixed(5)}'
                            : 'WhatsApp Location Link Attached',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(targetUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(uri);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch Google Maps: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                label: const Text(
                  'Open Directions in Google Maps',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernItemsTable(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF43A047), width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Color(0xFF43A047), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PRODUCTS ORDERED',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF43A047),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_orderItems.length} Products',
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_orderItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No item lines found in this order.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orderItems.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = _orderItems[index];
                  final unitStr = item.unit ?? 'PCS';
                  final qty = item.quantity ?? 0.0;
                  final rate = item.rate ?? 0.0;
                  final total = item.totalAmount ?? (qty * rate);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? 'Unnamed Item',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (item.hsnCode != null && item.hsnCode!.isNotEmpty)
                                  Text('HSN: ${item.hsnCode}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Unit: $unitStr', style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rate: ₹${rate.toStringAsFixed(2)} / $unitStr',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${qty % 1 == 0 ? qty.toInt() : qty} $unitStr',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(Order order, ThemeData theme) {
    final words = AmountToWordsService().convertToWords(order.grandTotal ?? 0.0);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFFB8C00), width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined, color: Color(0xFFFB8C00), size: 20),
                const SizedBox(width: 8),
                Text(
                  'ORDER FINANCIAL BREAKDOWN',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFB8C00),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTotalRow('Subtotal (Taxable Value)', '₹${order.subtotal?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Discount Total', '-₹${order.discountAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Total GST Tax', '₹${order.totalGST?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Round Off', '₹${order.roundOff?.toStringAsFixed(2) ?? "0.00"}', theme),
            const Divider(height: 20),
            _buildTotalRow('GRAND TOTAL', '₹${order.grandTotal?.toStringAsFixed(2) ?? "0.00"}', theme, isGrandTotal: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount in Words:',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    words,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String val, ThemeData theme, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isGrandTotal ? 16 : 14,
            ),
          ),
          Text(
            val,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isGrandTotal ? 16 : 14,
              color: isGrandTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ORDER AUDIT & TIMELINE', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (order.remarks != null && order.remarks!.isNotEmpty) ...[
              Text('Salesman Remarks / Terms:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(order.remarks!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (order.status == 'Cancelled') ...[
              Text('Cancellation Audit Info:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
              Text('Cancelled By: ${order.cancelledBy ?? "N/A"}', style: theme.textTheme.bodySmall),
              Text('Cancelled Date: ${order.cancelledDate?.toIso8601String().substring(0, 16)}', style: theme.textTheme.bodySmall),
              Text('Reason: ${order.cancellationReason ?? "N/A"}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade900)),
              const SizedBox(height: 16),
            ],
            Text('Created Date:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('${order.createdAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')} by ${order.createdBy ?? "system"}', style: theme.textTheme.bodyMedium),
            if (order.updatedAt != order.createdAt) ...[
              const SizedBox(height: 12),
              Text('Last Updated Date:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${order.updatedAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')} (v${order.version})', style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
