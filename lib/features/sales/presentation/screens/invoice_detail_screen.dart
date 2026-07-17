import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/pdf_service.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final fetched = await repo.getByUuid(widget.invoiceUuid);
      if (fetched != null) {
        try { await fetched.party.load(); } catch (_) {}
        try { await fetched.invoiceItems.load(); } catch (_) {}
      }
      setState(() {
        _invoice = fetched;
      });
    } catch (e) {
      logger.error('Failed to load invoice details', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelInvoice() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Sales Invoice'),
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
              child: const Text('Cancel Invoice'),
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
              content: Text('Invoice cancelled successfully! Stock levels and outstanding values restored.'),
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
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.where().findFirst();
      final companyName = companySettings?.companyName ?? 'Business Sahaj ERP';
      final companyGst = companySettings?.companyGST ?? '27AAAAA1111A1Z1';
      final companyAddr = companySettings?.companyAddress ?? '123 Business Hub, Mumbai, MH';
      final companyPhone = companySettings?.companyPhone ?? '+91 98765 43210';
      
      final pdfData = await pdfService.generateInvoicePdf(
        _invoice!,
        companyName: companyName,
        companyGst: companyGst,
        companyAddress: companyAddr,
        companyPhone: companyPhone,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Sales invoice not found.')),
      );
    }

    final invoice = _invoice!;
    final isCancelled = invoice.invoiceStatus == 'Cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice: ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _generatePdf,
            tooltip: 'Share/Print Invoice PDF',
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
              // Status Badge
              _buildStatusHeader(invoice, theme),
              const SizedBox(height: 20),

              // Party Billing Card
              _buildPartyBillingCard(invoice, theme),
              const SizedBox(height: 20),

              // Products Table Card
              _buildItemsTable(invoice, theme),
              const SizedBox(height: 20),

              // Financial breakdown & Tax Summary Card
              _buildTotalsCard(invoice, theme),
              const SizedBox(height: 20),

              // Payment Status details Card
              _buildPaymentCard(invoice, theme),
              const SizedBox(height: 20),

              // Audit history log timeline
              _buildTimelineCard(invoice, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Invoice invoice, ThemeData theme) {
    Color color = Colors.grey;
    if (invoice.paymentStatus == 'Unpaid') color = Colors.red;
    if (invoice.paymentStatus == 'Partially Paid') color = Colors.orange;
    if (invoice.paymentStatus == 'Paid') color = Colors.green;
    if (invoice.paymentStatus == 'Cancelled') color = Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Type: ${invoice.invoiceType ?? "Tax Invoice"}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Status: ${invoice.paymentStatus} | Date: ${invoice.invoiceDate?.toIso8601String().substring(0, 10)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyBillingCard(Invoice invoice, ThemeData theme) {
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
            Text('BILL TO CUSTOMER', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Text(invoice.partyName ?? 'N/A', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.receipt, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('GSTIN: ${invoice.gstNumber ?? "Unregistered"}', style: theme.textTheme.bodyMedium),
              ],
            ),
            if (invoice.address != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
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

  Widget _buildItemsTable(Invoice invoice, ThemeData theme) {
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
            Text('PRODUCTS BILLED', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoice.invoiceItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = invoice.invoiceItems.elementAt(index);
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
                            '${item.quantity?.toInt()} ${item.freeQuantity != null && item.freeQuantity! > 0 ? "+${item.freeQuantity!.toInt()} Free" : ""}',
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

  Widget _buildTotalsCard(Invoice invoice, ThemeData theme) {
    final words = AmountToWordsService().convertToWords(invoice.grandTotal ?? 0.0);

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
            _buildTotalRow('Subtotal (Taxable Value)', '₹${invoice.subtotal?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Discount Total', '-₹${invoice.discountAmount?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('GST Tax Total', '₹${invoice.totalGST?.toStringAsFixed(2) ?? "0.00"}', theme),
            _buildTotalRow('Round Off', '₹${invoice.roundOff?.toStringAsFixed(2) ?? "0.00"}', theme),
            const Divider(),
            _buildTotalRow('GRAND TOTAL', '₹${invoice.grandTotal?.toStringAsFixed(2) ?? "0.00"}', theme, isGrandTotal: true),
            const SizedBox(height: 12),
            Text(
              'Amount in Words:',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              words,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('GST Tax Division Splits:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (invoice.cgstAmount != null && invoice.cgstAmount! > 0)
              _buildTaxRow('Central GST (CGST):', '₹${invoice.cgstAmount?.toStringAsFixed(2)}', theme),
            if (invoice.sgstAmount != null && invoice.sgstAmount! > 0)
              _buildTaxRow('State GST (SGST):', '₹${invoice.sgstAmount?.toStringAsFixed(2)}', theme),
            if (invoice.igstAmount != null && invoice.igstAmount! > 0)
              _buildTaxRow('Integrated GST (IGST):', '₹${invoice.igstAmount?.toStringAsFixed(2)}', theme),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
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
    final dueStr = invoice.dueDate?.toIso8601String().substring(0, 10) ?? 'N/A';
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
            Text('PAYMENT & OUTSTANDING status', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            _buildTaxRow('Payment Status:', invoice.paymentStatus ?? 'Unpaid', theme),
            _buildTaxRow('Paid Amount:', '₹${invoice.paidAmount?.toStringAsFixed(2)}', theme),
            _buildTaxRow('Pending credit Amount:', '₹${invoice.pendingAmount?.toStringAsFixed(2)}', theme),
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
            Text('SALES AUDIT history', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (invoice.remarks != null && invoice.remarks!.isNotEmpty) ...[
              Text('Remarks / Terms:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(invoice.remarks!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (invoice.invoiceStatus == 'Cancelled') ...[
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
