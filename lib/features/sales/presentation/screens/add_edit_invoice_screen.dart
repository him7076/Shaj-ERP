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

class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  const AddEditInvoiceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController(text: '0.0');

  String _invoiceType = 'Tax Invoice';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceCartProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveInvoice() async {
    final cart = ref.read(invoiceCartProvider);
    if (cart.selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      _tabController.animateTo(0);
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add at least one item.')),
      );
      _tabController.animateTo(1);
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

      // Generate invoice number
      final nextInvNum = await repo.generateNextInvoiceNumber();

      final invoice = Invoice()
        ..invoiceNumber = nextInvNum
        ..invoiceDate = DateTime.now()
        ..invoiceType = _invoiceType
        ..partyId = cart.selectedParty!.id
        ..partyName = cart.selectedParty!.partyName
        ..gstNumber = cart.selectedParty!.gstNumber
        ..address = cart.selectedParty!.city
        ..subtotal = totals['subtotal']
        ..discountAmount = totals['discountAmount']
        ..taxableAmount = totals['subtotal'] // base taxable
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

      // GST splits
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

      // Map cart items to InvoiceItems
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

      // Refresh lists
      ref.invalidate(filteredInvoicesProvider);

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
    final cart = ref.watch(invoiceCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Tax Invoice'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '1. Customer', icon: Icon(Icons.person_outline)),
            Tab(text: '2. Select Items', icon: Icon(Icons.shopping_bag_outlined)),
            Tab(text: '3. Billing Review', icon: Icon(Icons.shopping_cart_outlined)),
          ],
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPartySelectionTab(),
                _buildProductCatalogTab(),
                _buildCartTab(),
              ],
            ),
    );
  }

  Widget _buildPartySelectionTab() {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);

    return partiesAsync.when(
      data: (parties) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Billing Customer Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: parties.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final party = parties[index];
                  final isSelected = ref.watch(invoiceCartProvider).selectedParty?.uuid == party.uuid;

                  return ListTile(
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    title: Text(party.partyName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('GST: ${party.gstNumber ?? "Unregistered"} | City: ${party.city ?? "N/A"}'),
                    leading: CircleAvatar(
                      child: Text(party.partyName?.substring(0, 1).toUpperCase() ?? ''),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      ref.read(invoiceCartProvider.notifier).setParty(party);
                      _tabController.animateTo(1);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add New Customer Account'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditPartyScreen(),
                    ),
                  ).then((_) => ref.invalidate(partiesListProvider));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load customers: $e')),
    );
  }

  Widget _buildProductCatalogTab() {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(filteredItemsProvider);
    final cart = ref.watch(invoiceCartProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cart Basket contains: ${cart.items.length} product lines.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('Review Cart'),
              ),
            ],
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final cartItem = cart.items.firstWhere(
                    (element) => element.item.uuid == item.uuid,
                    orElse: () => CartItemState(item: item, rate: 0, gstPercent: 0, quantity: 0),
                  );

                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: theme.colorScheme.surfaceVariant,
                          child: item.imagePaths != null && item.imagePaths!.isNotEmpty
                              ? Image.file(File(item.imagePaths!.first), fit: BoxFit.cover)
                              : const Icon(Icons.inventory),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rate: ₹${item.sellRate?.toStringAsFixed(2)} | Stock: ${item.currentStock?.toInt()}'),
                            Text('GST: ${item.gstRate?.toInt()}%', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      _buildQuantityAdjuster(item, cartItem),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load items: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Product Master'),
            onPressed: () async {
              final newlyCreated = await AddItemSheet.show(context);
              if (newlyCreated != null) {
                ref.read(invoiceCartProvider.notifier).addItem(newlyCreated);
                ref.invalidate(filteredItemsProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAdjuster(Item item, CartItemState cartItem) {
    final theme = Theme.of(context);
    if (cartItem.quantity == 0) {
      return ElevatedButton(
        onPressed: () {
          ref.read(invoiceCartProvider.notifier).addItem(item);
        },
        child: const Text('ADD'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              ref.read(invoiceCartProvider.notifier).updateItem(
                    item.uuid!,
                    quantity: cartItem.quantity - 1,
                  );
              if (cartItem.quantity <= 1) {
                ref.read(invoiceCartProvider.notifier).removeItem(item.uuid!);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${cartItem.quantity.toInt()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              ref.read(invoiceCartProvider.notifier).updateItem(
                    item.uuid!,
                    quantity: cartItem.quantity + 1,
                  );
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    final theme = Theme.of(context);
    final cart = ref.watch(invoiceCartProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Items Review List', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final cartItem = cart.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cartItem.item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(invoiceCartProvider.notifier).removeItem(cartItem.item.uuid!);
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: cartItem.quantity.toInt().toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? qty = double.tryParse(val);
                                  if (qty != null && qty > 0) {
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
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Invoice Level Configurations
                Text('Invoice Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _invoiceType,
                        decoration: const InputDecoration(labelText: 'Invoice Billing Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Tax Invoice', child: Text('Tax Invoice')),
                          DropdownMenuItem(value: 'Retail Invoice', child: Text('Retail Invoice')),
                          DropdownMenuItem(value: 'Cash Invoice', child: Text('Cash Invoice')),
                          DropdownMenuItem(value: 'Credit Invoice', child: Text('Credit Invoice')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _invoiceType = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Inclusive GST', style: TextStyle(fontSize: 12)),
                        value: cart.isGstInclusive,
                        onChanged: (val) {
                          ref.read(invoiceCartProvider.notifier).toggleGstInclusive(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        title: const Text('Due Date', style: TextStyle(fontSize: 11)),
                        subtitle: Text(_dueDate.toIso8601String().substring(0, 10)),
                        trailing: const Icon(Icons.calendar_today, size: 16),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountPercentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Invoice Discount %', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Invoice Discount Amt (₹)', border: OutlineInputBorder()),
                        onChanged: (val) {
                          final double? amt = double.tryParse(val);
                          ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks & Terms', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // Grand Totals Summary Card
                _buildTotalsSummaryPanel(theme),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Record Sales Invoice'),
            onPressed: _saveInvoice,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.where().findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(companyGst);

        return Card(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal (Taxable Value)', totals['subtotal']!, theme),
                _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
                _buildSummaryRow('GST Tax Total', totals['totalGST']!, theme),
                _buildSummaryRow('Round Off', totals['roundOff']!, theme),
                const Divider(),
                _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
                _buildSummaryRow('Pending Outstanding', totals['pendingAmount']!, theme, isPending: true),
              ],
            ),
          ),
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
              fontSize: (isBold || isPending) ? 16 : 14,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: (isBold || isPending) ? FontWeight.bold : FontWeight.normal,
              fontSize: (isBold || isPending) ? 16 : 14,
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
