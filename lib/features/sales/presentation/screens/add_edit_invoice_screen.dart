import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';


class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  final String? invoiceUuid;
  const AddEditInvoiceScreen({Key? key, this.invoiceUuid}) : super(key: key);

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

  Invoice? _existingInvoice;
  String _paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(invoiceCartProvider.notifier).clear();
      if (widget.invoiceUuid != null) {
        await _loadInvoiceData();
      }
    });
  }

  Future<void> _loadInvoiceData() async {
    try {
      final db = ref.read(databaseServiceProvider).isar;
      final invoice = await db.invoices.filter().uuidEqualTo(widget.invoiceUuid).findFirst();
      if (invoice != null) {
        _existingInvoice = invoice;
        _invoiceType = invoice.invoiceType ?? 'Tax Invoice';
        _invoiceDate = invoice.invoiceDate ?? DateTime.now();
        _dueDate = invoice.dueDate ?? DateTime.now();
        final remarksText = invoice.remarks ?? '';
        _remarksController.text = remarksText.replaceAll(RegExp(r'\s*\[Paid via [^\]]+\]'), '');
        final match = RegExp(r'\[Paid via ([^\]]+)\]').firstMatch(remarksText);
        if (match != null) {
          _paymentMode = match.group(1) ?? 'Cash';
        } else {
          _paymentMode = 'Cash';
        }
        _paidAmountController.text = invoice.paidAmount?.toString() ?? '0.0';
        final double subVal = invoice.subtotal ?? 0.0;
        final double discAmtVal = invoice.discountAmount ?? 0.0;
        _discountController.text = discAmtVal.toString();
        final double discPctVal = subVal > 0 ? (discAmtVal / subVal * 100) : 0.0;
        _discountPercentController.text = discPctVal.toStringAsFixed(1);

        if (!kIsWeb) {
          await invoice.party.load();
          await invoice.invoiceItems.load();
        }
        final party = kIsWeb
            ? (invoice.partyId != null ? await db.partys.get(invoice.partyId!) : null)
            : invoice.party.value;

        if (party != null) {
          final List<InvoiceItem> itemsList = kIsWeb
              ? await db.invoiceItems.filter().parentInvoiceIdEqualTo(invoice.id).findAll()
              : invoice.invoiceItems.toList();

          final List<CartItemState> cartItems = [];
          for (var item in itemsList) {
            if (!kIsWeb) {
              await item.item.load();
            }
            final dbItem = kIsWeb
                ? (item.itemId != null ? await db.items.get(item.itemId!) : null)
                : item.item.value;
            if (dbItem != null) {
              final totalBase = (item.rate ?? 0.0) * (item.quantity ?? 1.0);
              final discPct = totalBase > 0 ? ((item.discount ?? 0.0) / totalBase) * 100.0 : 0.0;

              cartItems.add(
                CartItemState(
                  item: dbItem,
                  quantity: item.quantity ?? 1.0,
                  freeQuantity: item.freeQuantity ?? 0.0,
                  rate: item.rate ?? 0.0,
                  discountPercent: discPct,
                  discountAmount: item.discount ?? 0.0,
                  gstPercent: item.gstRate ?? 18.0,
                ),
              );
            }
          }

          ref.read(invoiceCartProvider.notifier).loadInvoice(
            party: party,
            invoice: invoice,
            items: cartItems,
          );
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading invoice: $e')),
      );
    }
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

      final invoice = _existingInvoice ?? Invoice();
      if (_existingInvoice == null) {
        invoice.invoiceNumber = nextInvNum;
        invoice.createdBy = userEmail;
        invoice.createdAt = DateTime.now();
        invoice.version = 1;
      } else {
        invoice.version = _existingInvoice!.version + 1;
      }
      
      final double paidAmt = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
      String currentRemarks = _remarksController.text.trim();
      currentRemarks = currentRemarks.replaceAll(RegExp(r'\s*\[Paid via [^\]]+\]'), '');
      if (paidAmt > 0) {
        currentRemarks += ' [Paid via $_paymentMode]';
      }

      invoice
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
        ..paidAmount = paidAmt
        ..pendingAmount = totals['pendingAmount']
        ..dueDate = _dueDate
        ..remarks = currentRemarks
        ..updatedAt = DateTime.now()
        ..isDeleted = false;

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

      if (!kIsWeb) {
        invoice.party.value = cart.selectedParty;
      }

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

        if (!kIsWeb) {
          invItem.item.value = cartItem.item;
        }
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF5E35B1), width: 5),
          ),
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
                      setState(() {});
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
            Builder(
              builder: (context) {
                final double paidAmt = double.tryParse(_paidAmountController.text) ?? 0.0;
                if (paidAmt <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final dropdownItems = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        const DropdownMenuItem(value: 'UPI', child: Text('UPI / PhonePe / GPay')),
                        const DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? ''),
                        )),
                      ];
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode)));
                      }
                      return DropdownButtonFormField<String>(
                        value: _paymentMode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode / Account',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => DropdownButtonFormField<String>(
                      value: _paymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode / Account',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _paymentMode = val);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
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
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoiceUuid != null ? 'Edit Sales Invoice' : 'Direct Tax Invoice'),
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF1E88E5), width: 5),
          ),
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
                      return SearchablePartyDropdown(
                        parties: customerParties,
                        selectedParty: cart.selectedParty != null && customerParties.any((p) => p.uuid == cart.selectedParty!.uuid)
                            ? customerParties.firstWhere((p) => p.uuid == cart.selectedParty!.uuid)
                            : null,
                        labelText: 'Select Customer Account',
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
      ),
    );
  }

  Widget _buildProductSearchAndCatalog(ThemeData theme) {
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFF43A047), width: 5),
          ),
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
                        displayStringForOption: (item) => '${item.itemName ?? "Unnamed"} (Stock: ${item.currentStock?.toInt() ?? 0})',
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return items.take(20);
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return items.where((item) {
                            final name = item.itemName?.toLowerCase() ?? '';
                            final code = item.itemCode?.toLowerCase() ?? '';
                            final hsn = item.hsnCode?.toLowerCase() ?? '';
                            return name.contains(query) || code.contains(query) || hsn.contains(query);
                          });
                        },
                        optionsMaxHeight: 300,
                        onSelected: (item) {
                          ref.read(invoiceCartProvider.notifier).addItem(item);
                          FocusScope.of(context).unfocus();
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final item = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                                      title: Text(item.itemName ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(
                                        'Code: ${item.itemCode ?? "N/A"} | Price: ₹${item.sellRate?.toStringAsFixed(2) ?? "0"} | Stock: ${item.currentStock?.toInt() ?? 0}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onTap: () => onSelected(item),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFFFB8C00), width: 5),
          ),
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
                return InvoiceCartItemRow(
                  cartItem: cartItem,
                  isGstInclusive: cart.isGstInclusive,
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    final cart = ref.watch(invoiceCartProvider);
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.where().findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(companyGst);

        final cleanCompany = companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final cleanParty = cart.selectedParty?.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

        final totalGst = totals['totalGST'] ?? 0.0;
        final cgst = isLocal ? totalGst / 2.0 : 0.0;
        final sgst = isLocal ? totalGst / 2.0 : 0.0;
        final igst = isLocal ? 0.0 : totalGst;

        return Column(
          children: [
            _buildSummaryRow('Subtotal (Taxable Value)', totals['subtotal']!, theme),
            _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
            if (isLocal) ...[
              _buildSummaryRow('CGST (9%)', cgst, theme),
              _buildSummaryRow('SGST (9%)', sgst, theme),
            ] else ...[
              _buildSummaryRow('IGST (18%)', igst, theme),
            ],
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

class InvoiceCartItemRow extends ConsumerStatefulWidget {
  final CartItemState cartItem;
  final bool isGstInclusive;
  const InvoiceCartItemRow({Key? key, required this.cartItem, required this.isGstInclusive}) : super(key: key);

  @override
  ConsumerState<InvoiceCartItemRow> createState() => _InvoiceCartItemRowState();
}

class _InvoiceCartItemRowState extends ConsumerState<InvoiceCartItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _freeQtyController;
  late TextEditingController _rateExclController;
  late TextEditingController _rateInclController;
  late TextEditingController _discPercentController;
  late TextEditingController _discAmountController;

  bool _isUpdatingLocally = false;

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    final gstPct = item.gstPercent;
    
    final double rateExcl = widget.isGstInclusive 
        ? item.rate / (1 + gstPct / 100.0) 
        : item.rate;
    final double rateIncl = widget.isGstInclusive 
        ? item.rate 
        : item.rate * (1 + gstPct / 100.0);

    _qtyController = TextEditingController(text: item.quantity.toInt().toString());
    _freeQtyController = TextEditingController(text: item.freeQuantity.toInt().toString());
    _rateExclController = TextEditingController(text: rateExcl.toStringAsFixed(2));
    _rateInclController = TextEditingController(text: rateIncl.toStringAsFixed(2));
    _discPercentController = TextEditingController(text: item.discountPercent.toString());
    _discAmountController = TextEditingController(text: item.discountAmount.toString());
  }
  
  @override
  void didUpdateWidget(InvoiceCartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isUpdatingLocally) return;
    
    final item = widget.cartItem;
    final gstPct = item.gstPercent;
    
    final double rateExcl = widget.isGstInclusive 
        ? item.rate / (1 + gstPct / 100.0) 
        : item.rate;
    final double rateIncl = widget.isGstInclusive 
        ? item.rate 
        : item.rate * (1 + gstPct / 100.0);

    _updateIfChanged(_qtyController, item.quantity.toInt().toString());
    _updateIfChanged(_freeQtyController, item.freeQuantity.toInt().toString());
    _updateIfChanged(_rateExclController, rateExcl.toStringAsFixed(2));
    _updateIfChanged(_rateInclController, rateIncl.toStringAsFixed(2));
    _updateIfChanged(_discPercentController, item.discountPercent.toString());
    _updateIfChanged(_discAmountController, item.discountAmount.toString());
  }

  void _updateIfChanged(TextEditingController controller, String value) {
    if (controller.text != value && double.tryParse(controller.text) != double.tryParse(value)) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _freeQtyController.dispose();
    _rateExclController.dispose();
    _rateInclController.dispose();
    _discPercentController.dispose();
    _discAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.cartItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.item.itemName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(invoiceCartProvider.notifier).removeItem(item.item.uuid!);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? qty = double.tryParse(val);
                  if (qty != null && qty >= 0) {
                    ref.read(invoiceCartProvider.notifier).updateItem(item.item.uuid!, quantity: qty);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _freeQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Free Qty', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? qty = double.tryParse(val);
                  if (qty != null) {
                    ref.read(invoiceCartProvider.notifier).updateItem(item.item.uuid!, freeQuantity: qty);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _rateExclController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate Excl (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? excl = double.tryParse(val);
                  if (excl == null) return;
                  
                  final gstPct = item.gstPercent;
                  final incl = excl * (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateInclController.text = incl.toStringAsFixed(2);
                  
                  final targetRate = widget.isGstInclusive ? incl : excl;
                  ref.read(invoiceCartProvider.notifier).updateItem(
                    item.item.uuid!,
                    rate: targetRate,
                  );
                  _isUpdatingLocally = false;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _rateInclController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate Incl (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? incl = double.tryParse(val);
                  if (incl == null) return;
                  
                  final gstPct = item.gstPercent;
                  final excl = incl / (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateExclController.text = excl.toStringAsFixed(2);
                  
                  final targetRate = widget.isGstInclusive ? incl : excl;
                  ref.read(invoiceCartProvider.notifier).updateItem(
                    item.item.uuid!,
                    rate: targetRate,
                  );
                  _isUpdatingLocally = false;
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
                controller: _discPercentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc %', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? pct = double.tryParse(val);
                  if (pct != null) {
                    ref.read(invoiceCartProvider.notifier).updateItem(item.item.uuid!, discountPercent: pct);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _discAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc Amt (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? amt = double.tryParse(val);
                  if (amt != null) {
                    ref.read(invoiceCartProvider.notifier).updateItem(item.item.uuid!, discountAmount: amt);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'GST Tax %', isDense: true, border: OutlineInputBorder()),
                child: Text('${item.gstPercent.toInt()}%'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
