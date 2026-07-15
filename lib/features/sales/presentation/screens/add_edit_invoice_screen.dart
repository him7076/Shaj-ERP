import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  const AddEditInvoiceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController(text: '0.0');
  final TextEditingController _productSearchController = TextEditingController();

  String _invoiceType = 'Tax Invoice';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceCartProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    _paidAmountController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveInvoice() async {
    final cart = ref.read(invoiceCartProvider);
    if (cart.selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add at least one item.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.email ?? 'salesman@sahaj.com';

      final repo = ref.read(invoiceRepositoryProvider);
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.where().findFirst();
      final companyGst = companySettings?.companyGST;

      final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(companyGst);
      final nextInvNum = await repo.generateNextInvoiceNumber();

      final invoice = Invoice()
        ..invoiceNumber = nextInvNum
        ..invoiceDate = _invoiceDate
        ..invoiceType = _invoiceType
        ..partyId = cart.selectedParty!.id
        ..partyName = cart.selectedParty!.partyName
        ..gstNumber = cart.selectedParty!.gstNumber
        ..address = cart.selectedParty!.city
        ..subtotal = totals['subtotal']
        ..discountAmount = totals['discountAmount']
        ..taxableAmount = totals['subtotal']
        ..totalGST = totals['totalGST']
        ..roundOff = totals['roundOff']
        ..grandTotal = totals['grandTotal']
        ..paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? 0.0
        ..pendingAmount = totals['pendingAmount']
        ..dueDate = _dueDate
        ..remarks = _remarksController.text.trim()
        ..createdBy = userEmail
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false
        ..version = 1;

      final cleanCompany = companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
      final cleanParty = cart.selectedParty!.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
      final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

      if (isLocal) {
        invoice.cgstAmount = (totals['totalGST'] ?? 0.0) / 2.0;
        invoice.sgstAmount = (totals['totalGST'] ?? 0.0) / 2.0;
        invoice.igstAmount = 0.0;
      } else {
        invoice.cgstAmount = 0.0;
        invoice.sgstAmount = 0.0;
        invoice.igstAmount = totals['totalGST'];
      }

      invoice.party.value = cart.selectedParty;

      final List<InvoiceItem> invoiceItems = cart.items.map((cartItem) {
        final invItem = InvoiceItem()
          ..itemId = cartItem.item.id
          ..itemName = cartItem.item.itemName
          ..hsnCode = cartItem.item.hsnCode
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..rate = cartItem.rate
          ..discount = cartItem.discountAmount
          ..taxableAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..gstRate = cartItem.gstPercent
          ..gstAmount = cartItem.gstPercent * cartItem.rate * 0.01
          ..totalAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount;

        invItem.item.value = cartItem.item;
        return invItem;
      }).toList();

      await repo.saveInvoice(invoice, invoiceItems);

      ref.invalidate(filteredInvoicesProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Direct Invoice #${invoice.invoiceNumber} recorded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to record Sales Invoice', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(invoiceCartProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_isSaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPartyAndHeaderCard(theme),
        const SizedBox(height: 16),
        _buildProductSearchAndCatalog(theme),
        const SizedBox(height: 16),
        _buildCartItemsTable(theme, cart),
      ],
    );

    final summaryContent = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invoice Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _invoiceType,
              decoration: const InputDecoration(labelText: 'Billing Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Tax Invoice', child: Text('Tax Invoice')),
                DropdownMenuItem(value: 'Retail Invoice', child: Text('Retail Invoice')),
                DropdownMenuItem(value: 'Cash Invoice', child: Text('Cash Invoice')),
                DropdownMenuItem(value: 'Credit Invoice', child: Text('Credit Invoice')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _invoiceType = val);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('GST Inclusive Pricing'),
              value: cart.isGstInclusive,
              onChanged: (val) {
                ref.read(invoiceCartProvider.notifier).toggleGstInclusive(val);
              },
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Paid Amount (₹)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      if (amt != null) {
                        ref.read(invoiceCartProvider.notifier).setPaidAmount(amt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setState(() => _dueDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd-MM-yyyy').format(_dueDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Disc %', border: OutlineInputBorder()),
                    onChanged: (val) {
                      final double? pct = double.tryParse(val);
                      ref.read(invoiceCartProvider.notifier).setDiscounts(pct, null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Disc Amt (₹)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks / Terms', border: OutlineInputBorder()),
            ),
            const Divider(height: 32),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save & Print Invoice'),
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Tax Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: mainContent),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: summaryContent),
                ],
              )
            : Column(
                children: [
                  mainContent,
                  const SizedBox(height: 16),
                  summaryContent,
                ],
              ),
      ),
    );
  }

  Widget _buildPartyAndHeaderCard(ThemeData theme) {
    final partiesAsync = ref.watch(partiesListProvider);
    final cart = ref.watch(invoiceCartProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: partiesAsync.when(
                    data: (parties) {
                      final customerParties = parties.where((p) => p.partyType != 'Supplier').toList();
                      return DropdownButtonFormField<Party>(
                        value: cart.selectedParty != null && customerParties.any((p) => p.uuid == cart.selectedParty!.uuid)
                            ? customerParties.firstWhere((p) => p.uuid == cart.selectedParty!.uuid)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Customer Account',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: customerParties.map((p) {
                          return DropdownMenuItem<Party>(value: p, child: Text(p.partyName ?? ''));
                        }).toList(),
                        onChanged: (party) {
                          ref.read(invoiceCartProvider.notifier).setParty(party);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading customers: $e'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditPartyScreen()),
                    ).then((_) => ref.invalidate(partiesListProvider));
                  },
                ),
              ],
            ),
            if (cart.selectedParty != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GST: ${cart.selectedParty!.gstNumber ?? "Unregistered"} | Address: ${cart.selectedParty!.city ?? "N/A"} | Current Outstanding: ₹${cart.selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _invoiceDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Invoice Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd-MM-yyyy').format(_invoiceDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearchAndCatalog(ThemeData theme) {
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search & Add Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: itemsAsync.when(
                    data: (items) {
                      return Autocomplete<Item>(
                        displayStringForOption: (item) => '${item.itemName} (Stock: ${item.currentStock?.toInt() ?? 0})',
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Item>.empty();
                          }
                          return items.where((item) =>
                              item.itemName!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (item) {
                          ref.read(invoiceCartProvider.notifier).addItem(item);
                          _productSearchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Type product name to add...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading products: $e'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final newlyCreated = await AddItemSheet.show(context);
                    if (newlyCreated != null) {
                      ref.read(invoiceCartProvider.notifier).addItem(newlyCreated);
                      ref.invalidate(filteredItemsProvider);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsTable(ThemeData theme, InvoiceCart cart) {
    if (cart.items.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No product lines added yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing Cart lines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final cartItem = cart.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cartItem.item.itemName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            ref.read(invoiceCartProvider.notifier).removeItem(cartItem.item.uuid!);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: cartItem.quantity.toInt().toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final double? qty = double.tryParse(val);
                              if (qty != null && qty >= 0) {
                                ref.read(invoiceCartProvider.notifier).updateItem(cartItem.item.uuid!, quantity: qty);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: cartItem.freeQuantity.toInt().toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Free Qty', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final double? qty = double.tryParse(val);
                              if (qty != null) {
                                ref.read(invoiceCartProvider.notifier).updateItem(cartItem.item.uuid!, freeQuantity: qty);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: cartItem.rate.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Rate (₹)', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final double? rateVal = double.tryParse(val);
                              if (rateVal != null) {
                                ref.read(invoiceCartProvider.notifier).updateItem(cartItem.item.uuid!, rate: rateVal);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: cartItem.discountPercent.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Disc %', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final double? pct = double.tryParse(val);
                              if (pct != null) {
                                ref.read(invoiceCartProvider.notifier).updateItem(cartItem.item.uuid!, discountPercent: pct);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: cartItem.discountAmount.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Disc Amt (₹)', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final double? amt = double.tryParse(val);
                              if (amt != null) {
                                ref.read(invoiceCartProvider.notifier).updateItem(cartItem.item.uuid!, discountAmount: amt);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'GST Tax %', isDense: true, border: OutlineInputBorder()),
                            child: Text('${cartItem.gstPercent.toInt()}%'),
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

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.where().findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(companyGst);

        return Column(
          children: [
            _buildSummaryRow('Subtotal (Taxable Value)', totals['subtotal']!, theme),
            _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
            _buildSummaryRow('GST Tax Total', totals['totalGST']!, theme),
            _buildSummaryRow('Round Off', totals['roundOff']!, theme),
            const Divider(),
            _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
            _buildSummaryRow('Pending Outstanding', totals['pendingAmount']!, theme, isPending: true),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double val, ThemeData theme, {bool isBold = false, bool isPending = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: (isBold || isPending) ? FontWeight.bold : FontWeight.normal,
              fontSize: (isBold || isPending) ? 15 : 13,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: (isBold || isPending) ? FontWeight.bold : FontWeight.normal,
              fontSize: (isBold || isPending) ? 15 : 13,
              color: isPending
                  ? Colors.red
                  : isBold
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
