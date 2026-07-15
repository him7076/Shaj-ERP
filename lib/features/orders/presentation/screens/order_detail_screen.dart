import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/add_edit_order_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/pdf_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderUuid;

  const OrderDetailScreen({Key? key, required this.orderUuid}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final fetched = await repo.getByUuid(widget.orderUuid);
      if (fetched != null) {
        try { await fetched.party.load(); } catch (_) {}
        try { await fetched.orderItems.load(); } catch (_) {}
      }
      setState(() {
        _order = fetched;
      });
    } catch (e) {
      logger.error('Failed to load order detail', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Sales Order'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
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
              child: const Text('Cancel Order'),
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
              content: Text('Order has been cancelled successfully.'),
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
    final paidController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 15));
    var invoiceType = 'Tax Invoice';
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Convert Order to Invoice'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: invoiceType,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Billing Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tax Invoice', child: Text('Tax Invoice')),
                          DropdownMenuItem(value: 'Retail Invoice', child: Text('Retail Invoice')),
                          DropdownMenuItem(value: 'Cash Invoice', child: Text('Cash Invoice')),
                          DropdownMenuItem(value: 'Credit Invoice', child: Text('Credit Invoice')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => invoiceType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: paidController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount Paid (₹)',
                          border: const OutlineInputBorder(),
                          helperText: 'Grand Total: ₹${_order?.grandTotal?.toStringAsFixed(2)}',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required (enter 0 if credit)';
                          final amt = double.tryParse(v);
                          if (amt == null || amt < 0) return 'Enter valid amount >= 0';
                          if (amt > (_order?.grandTotal ?? 0.0)) return 'Paid amount cannot exceed total';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Due Date Picker
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        title: const Text('Credit Due Date'),
                        subtitle: Text(dueDate.toIso8601String().substring(0, 10)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selected != null) {
                            setDialogState(() => dueDate = selected);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Generate Invoice'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true && _order != null) {
      setState(() => _isLoading = true);
      try {
        final authState = ref.read(authProvider);
        final userEmail = authState.email ?? 'salesman@sahaj.com';
        final paidAmt = double.parse(paidController.text);

        final invoiceRepo = ref.read(invoiceRepositoryProvider);
        final invoice = await invoiceRepo.convertOrderToInvoice(
          orderUuid: _order!.uuid!,
          invoiceType: invoiceType,
          paidAmount: paidAmt,
          dueDate: dueDate,
          user: userEmail,
        );

        // Reload current order
        await _loadOrder();
        ref.invalidate(filteredOrdersProvider);
        ref.invalidate(filteredInvoicesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order converted! Generated Invoice #${invoice.invoiceNumber}.'),
              backgroundColor: Colors.purple,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to convert order to invoice', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conversion failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_order == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfService = PdfService();
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.where().findFirst();
      final companyName = companySettings?.companyName ?? 'Business Sahaj ERP';
      
      final pdfData = await pdfService.generateOrderPdf(_order!, companyName: companyName);
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
        appBar: AppBar(),
        body: const Center(child: Text('Sales order not found.')),
      );
    }

    final order = _order!;
    final isLocked = order.status == 'Cancelled' || order.status == 'Converted To Sale';
    final isCancelled = order.status == 'Cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order: ${order.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _generatePdf,
            tooltip: 'Share/Print PDF',
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
              // Status Badge
              _buildStatusHeader(order, theme),
              const SizedBox(height: 20),

              // Party Details Card
              _buildPartyDetailsCard(order, theme),
              const SizedBox(height: 20),

              // Items Table Card
              _buildItemsTable(order, theme),
              const SizedBox(height: 20),

              // Financial Totals Table
              _buildTotalsCard(order, theme),
              const SizedBox(height: 20),

              // Remarks & Audit Timeline
              _buildTimelineCard(order, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isLocked
          ? null
          : BottomAppBar(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel Order'),
                      onPressed: _cancelOrder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: userRoleAsync.when(
                      data: (role) {
                        // Salesman cannot convert to sale (only Owner and Staff)
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
              ),
            ),
    );
  }

  Widget _buildStatusHeader(Order order, ThemeData theme) {
    Color color = Colors.grey;
    if (order.status == 'Draft') color = Colors.blue;
    if (order.status == 'Pending') color = Colors.orange;
    if (order.status == 'Confirmed') color = Colors.green;
    if (order.status == 'Cancelled') color = Colors.red;
    if (order.status == 'Converted To Sale') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Status: ${order.status ?? "N/A"}',
                  style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Number: ${order.orderNumber} | Date: ${order.orderDate?.toIso8601String().substring(0, 10)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyDetailsCard(Order order, ThemeData theme) {
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
            Text('CUSTOMER ACCOUNT Details', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Text(order.partyName ?? 'N/A', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(order.mobileNumber ?? 'N/A', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 16),
                const Icon(Icons.receipt, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('GST: ${order.gstNumber ?? "Unregistered"}', style: theme.textTheme.bodyMedium),
              ],
            ),
            if (order.locationAddress != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
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

  Widget _buildItemsTable(Order order, ThemeData theme) {
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
            Text('PRODUCTS ORDERED', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.orderItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = order.orderItems.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName ?? 'N/A', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              'Rate: ₹${item.rate?.toStringAsFixed(2)} | HSN: ${item.hsnCode ?? "N/A"}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantity?.toInt()} ${item.unit ?? "PCS"}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${item.totalAmount?.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', '₹${order.subtotal?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Discount Total', '-₹${order.discountAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Total GST Tax', '₹${order.totalGST?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Round Off', '₹${order.roundOff?.toStringAsFixed(2) ?? "0.00"}', theme),
            const Divider(),
            _buildTotalRow('Grand Total', '₹${order.grandTotal?.toStringAsFixed(2) ?? "0.00"}', theme, isGrandTotal: true),
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
    final hasLogs = order.internalNotes != null && order.internalNotes!.isNotEmpty;

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
            Text('ORDER TIMELINE LOGS', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (order.remarks != null && order.remarks!.isNotEmpty) ...[
              Text('Salesman Remarks:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
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
