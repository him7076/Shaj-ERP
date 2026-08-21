import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/services/pdf_service.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/models/firm_info.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceUuid;

  const InvoiceDetailScreen({Key? key, required this.invoiceUuid}) : super(key: key);

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isLoading = false;
  Invoice? _invoice;
  List<InvoiceItem> _invoiceItems = [];

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final idVal = int.tryParse(widget.invoiceUuid);
      
      Invoice? fetched;
      if (idVal != null) {
        if (idVal > 100000000) {
          fetched = await isar.invoices.get(idVal - 100000000);
        } else {
          fetched = await isar.invoices.get(idVal);
        }
      }
      fetched ??= await isar.invoices.filter().uuidEqualTo(widget.invoiceUuid).findFirst();

      if (fetched != null) {
        try { await fetched.party.load(); } catch (_) {}

        final targetId = fetched.id;
        final targetUuid = fetched.uuid;

        // 1. Query items by parent invoice ID or parent invoice UUID first
        List<InvoiceItem> items = await isar.invoiceItems
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .group((q) {
              var builder = q.parentInvoiceIdEqualTo(targetId);
              if (targetUuid != null && targetUuid.isNotEmpty) {
                builder = builder.or().parentInvoiceUuidEqualTo(targetUuid);
              }
              return builder;
            })
            .findAll();

        if (items.isEmpty) {
          try {
            await fetched.invoiceItems.load();
            items = fetched.invoiceItems.where((i) => !i.isDeleted).toList();
          } catch (_) {}
        }

        // Self-heal parent invoice IDs and UUIDs if missing
        if (items.isNotEmpty) {
          final needsRepair = items.any((i) => i.parentInvoiceId != targetId || i.parentInvoiceUuid != targetUuid);
          if (needsRepair) {
            await isar.writeTxn(() async {
              for (var itm in items) {
                itm.parentInvoiceId = targetId;
                itm.parentInvoiceUuid = targetUuid;
                try { itm.invoice.value = fetched; } catch (_) {}
                await isar.invoiceItems.put(itm);
                try { await itm.invoice.save(); } catch (_) {}
              }
            });
          }
        }

        for (var itm in items) {
          try { await itm.item.load(); } catch (_) {}
          if (itm.item.value == null && itm.itemId != null) {
            try { itm.item.value = await isar.items.get(itm.itemId!); } catch (_) {}
          }
        }

        setState(() {
          _invoice = fetched;
          _invoiceItems = items;
        });
      }
    } catch (e) {
      logger.error('Failed to load invoice details', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelInvoice() async {
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
              Text('Cancel Sales Invoice'),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Enter reason for cancellation',
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

    if (confirm == true && _invoice != null) {
      setState(() => _isLoading = true);
      try {
        final authState = ref.read(authProvider);
        final userEmail = authState.email ?? 'salesman@sahaj.com';

        final repo = ref.read(invoiceRepositoryProvider);
        await repo.cancelInvoice(
          _invoice!.uuid!,
          reasonController.text.trim(),
          userEmail,
        );

        await _loadInvoice();
        ref.invalidate(filteredInvoicesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice cancelled successfully! Stock and balances updated.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to cancel invoice', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel invoice: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_invoice == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfService = PdfService();
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final firmInfo = await FirmInfo.getActiveFirmInfo(prefs, isar);
      
      final pdfData = await pdfService.generateInvoicePdf(
        _invoice!,
        items: _invoiceItems,
        firmInfo: firmInfo,
      );
      await pdfService.printOrSharePdf(pdfData, 'Invoice_${_invoice!.invoiceNumber}.pdf');
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
    if (_invoice == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfService = PdfService();
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final firmInfo = await FirmInfo.getActiveFirmInfo(prefs, isar);
      
      final pdfData = await pdfService.generateInvoicePdf(
        _invoice!,
        items: _invoiceItems,
        firmInfo: firmInfo,
      );
      await pdfService.sharePdf(pdfData, 'Invoice_${_invoice!.invoiceNumber}.pdf');
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
    final isMobile = ResponsiveLayout.isMobile(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Invoice')),
        body: const Center(child: Text('Sales invoice not found.')),
      );
    }

    final invoice = _invoice!;
    final isCancelled = invoice.paymentStatus == 'Cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
            onPressed: _sharePdf,
            tooltip: 'Share PDF via WhatsApp / Apps',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _generatePdf,
            tooltip: 'Print / Download PDF',
          ),
          if (!isCancelled) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditInvoiceScreen(invoiceUuid: invoice.uuid),
                  ),
                ).then((_) => _loadInvoice());
              },
              tooltip: 'Edit Invoice',
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: _cancelInvoice,
              tooltip: 'Cancel Invoice',
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
              _buildModernHeaderCard(invoice, theme),
              const SizedBox(height: 16),

              // SECTION 1: Customer / Billing Party Details
              _buildPartyBillingCard(invoice, theme),
              const SizedBox(height: 16),

              // SECTION 2: PRODUCTS BILLED (Item Details - Right after Party Details!)
              _buildModernItemsTable(invoice, theme),
              const SizedBox(height: 16),

              // SECTION 3: Financial Totals Breakdown & Tax Split
              _buildTotalsCard(invoice, theme),
              const SizedBox(height: 16),

              // SECTION 4: Payment Status & Credit Details
              _buildPaymentCard(invoice, theme),
              const SizedBox(height: 16),

              // SECTION 5: Invoice Audit History
              _buildTimelineCard(invoice, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? null : BottomAppBar(
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
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print / Preview'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeaderCard(Invoice invoice, ThemeData theme) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.receipt_long;

    if (invoice.paymentStatus == 'Unpaid') { statusColor = Colors.red; statusIcon = Icons.error_outline; }
    if (invoice.paymentStatus == 'Partially Paid') { statusColor = Colors.orange; statusIcon = Icons.timelapse; }
    if (invoice.paymentStatus == 'Paid') { statusColor = Colors.green; statusIcon = Icons.check_circle; }
    if (invoice.paymentStatus == 'Cancelled') { statusColor = Colors.grey; statusIcon = Icons.block; }

    final formattedDate = invoice.invoiceDate != null ? DateFormat('dd MMM yyyy').format(invoice.invoiceDate!) : 'N/A';

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
                        invoice.invoiceType?.toUpperCase() ?? 'TAX INVOICE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '#${invoice.invoiceNumber}',
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
                  invoice.paymentStatus?.toUpperCase() ?? 'UNPAID',
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
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Items: ${_invoiceItems.length}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyBillingCard(Invoice invoice, ThemeData theme) {
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
                        'BILL TO CUSTOMER (PARTY)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        invoice.partyName ?? 'N/A',
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
                        'GSTIN: ${invoice.gstNumber ?? "Unregistered"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invoice.address != null && invoice.address!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      invoice.address!,
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

  Widget _buildModernItemsTable(Invoice invoice, ThemeData theme) {
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
                      'PRODUCTS BILLED',
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
                    '${_invoiceItems.length} Products',
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoiceItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No item lines found in this invoice.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoiceItems.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = _invoiceItems[index];
                  final masterItem = item.item.value;
                  String unitStr = (item.unit != null && item.unit!.isNotEmpty)
                      ? item.unit!
                      : (masterItem?.primaryUnitName ?? masterItem?.unit.value?.shortName ?? masterItem?.unit.value?.unitName ?? 'PCS');

                  final qty = item.quantity ?? 0.0;
                  final freeQty = item.freeQuantity ?? 0.0;
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
                            () {
                              final catalogName = item.item.value?.itemName;
                              final displayName = (catalogName != null && catalogName.trim().isNotEmpty)
                                  ? catalogName
                                  : (item.itemName ?? 'Unnamed Item');
                              return Text(
                                displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              );
                            }(),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (item.hsnCode != null && item.hsnCode!.isNotEmpty)
                                  Text('HSN: ${item.hsnCode}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                                if (item.gstRate != null)
                                  Text('GST ${item.gstRate!.toInt()}%', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
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
                            '${qty % 1 == 0 ? qty.toInt() : qty} $unitStr ${freeQty > 0 ? "(+${freeQty.toInt()} Free)" : ""}',
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

  Widget _buildTotalsCard(Invoice invoice, ThemeData theme) {
    final words = AmountToWordsService().convertToWords(invoice.grandTotal ?? 0.0);

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
                  'INVOICE FINANCIAL BREAKDOWN',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFB8C00),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTotalRow('Subtotal (Taxable Value)', '₹${invoice.subtotal?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Discount Total', '-₹${invoice.discountAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('GST Tax Total', '₹${invoice.totalGST?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Round Off', '₹${invoice.roundOff?.toStringAsFixed(2) ?? "0.00"}', theme),
            const Divider(height: 20),
            _buildTotalRow('GRAND TOTAL', '₹${invoice.grandTotal?.toStringAsFixed(2) ?? "0.00"}', theme, isGrandTotal: true),
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
            if ((invoice.cgstAmount ?? 0) > 0 || (invoice.sgstAmount ?? 0) > 0 || (invoice.igstAmount ?? 0) > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Text('GST Tax Division Splits:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (invoice.cgstAmount != null && invoice.cgstAmount! > 0)
                _buildTaxRow('Central GST (CGST):', '₹${invoice.cgstAmount?.toStringAsFixed(2)}', theme),
              if (invoice.sgstAmount != null && invoice.sgstAmount! > 0)
                _buildTaxRow('State GST (SGST):', '₹${invoice.sgstAmount?.toStringAsFixed(2)}', theme),
              if (invoice.igstAmount != null && invoice.igstAmount! > 0)
                _buildTaxRow('Integrated GST (IGST):', '₹${invoice.igstAmount?.toStringAsFixed(2)}', theme),
            ],
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

  Widget _buildTaxRow(String label, String val, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(val, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Invoice invoice, ThemeData theme) {
    final dueStr = invoice.dueDate != null ? DateFormat('dd MMM yyyy').format(invoice.dueDate!) : 'N/A';
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
            Text('PAYMENT & OUTSTANDING STATUS', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            _buildTaxRow('Payment Status:', invoice.paymentStatus ?? 'Unpaid', theme),
            _buildTaxRow('Paid Amount:', '₹${invoice.paidAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTaxRow('Pending Credit Amount:', '₹${invoice.pendingAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTaxRow('Credit Due Date:', dueStr, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Invoice invoice, ThemeData theme) {
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
            Text('SALES AUDIT & TIMELINE', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (invoice.remarks != null && invoice.remarks!.isNotEmpty) ...[
              Text('Remarks / Terms:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(invoice.remarks!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (invoice.paymentStatus == 'Cancelled') ...[
              Text('Cancellation Audit Info:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
              Text('Cancelled By: ${invoice.cancelledBy ?? "N/A"}', style: theme.textTheme.bodySmall),
              Text('Cancelled Date: ${invoice.cancelledDate?.toIso8601String().substring(0, 16)}', style: theme.textTheme.bodySmall),
              Text('Reason: ${invoice.cancellationReason ?? "N/A"}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade900)),
              const SizedBox(height: 16),
            ],
            Text('Invoice Created Date:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('${invoice.createdAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')} by ${invoice.createdBy ?? "system"}', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
