import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/widgets/item_search_picker_modal.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:uuid/uuid.dart';
class AddEditPurchaseScreen extends ConsumerStatefulWidget {
  final String? purchaseUuid;
  const AddEditPurchaseScreen({Key? key, this.purchaseUuid}) : super(key: key);

  @override
  ConsumerState<AddEditPurchaseScreen> createState() => _AddEditPurchaseScreenState();
}

class _AddEditPurchaseScreenState extends ConsumerState<AddEditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _supplierInvoiceNumberController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0.0');
  final _productSearchController = TextEditingController();
  final ScrollController _itemsScrollController = ScrollController();

  Party? _selectedParty;
  List<PurchaseItem> _draftItems = [];
  DateTime _purchaseDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));

  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _taxableAmount = 0.0;
  double _totalGST = 0.0;
  double _grandTotal = 0.0;
  double? _customRoundOff;
  double _roundOff = 0.0;
  bool _isSaving = false;
  String? _companyGst;
  Purchase? _existingPurchase;
  String _paymentMode = 'Cash';

  List<String> _paymentModesList = ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'Credit'];

  void _loadPaymentModes() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final customP = prefs.getStringList('custom_payment_modes_list') ?? [];
      setState(() {
        _paymentModesList = ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'Credit', ...customP].toSet().toList();
      });
    } catch (_) {}
  }

  Future<void> _showAddPaymentModeDialog() async {
    final modeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newMode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Payment Type'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: modeController,
              decoration: const InputDecoration(
                labelText: 'Payment Mode Name (e.g. Finance, EMI)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Mode name is required' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, modeController.text.trim());
                }
              },
              child: const Text('Add Payment Type'),
            ),
          ],
        );
      },
    );

    if (newMode != null && newMode.isNotEmpty) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList('custom_payment_modes_list') ?? [];
      if (!list.contains(newMode)) {
        list.add(newMode);
        await prefs.setStringList('custom_payment_modes_list', list);
      }
      setState(() {
        _paymentModesList = ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'Credit', ...list].toSet().toList();
        _paymentMode = newMode;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentModes();
    _initValues();
  }

  void _initValues() async {
    final repo = ref.read(purchaseRepositoryProvider);
    final isar = ref.read(databaseServiceProvider).isar;
    final settings = await isar.settings.filter().idGreaterThan(-1).findFirst();
    _companyGst = settings?.companyGST;

    if (widget.purchaseUuid != null && widget.purchaseUuid!.isNotEmpty) {
      Purchase? purchase = await isar.purchases.filter().uuidEqualTo(widget.purchaseUuid).findFirst();
      if (purchase == null) {
        final idVal = int.tryParse(widget.purchaseUuid!);
        if (idVal != null) {
          purchase = await isar.purchases.get(idVal);
        }
      }

      if (purchase != null) {
        _existingPurchase = purchase;
        _billNumberController.text = purchase.purchaseNumber ?? '';
        _supplierInvoiceNumberController.text = purchase.supplierInvoiceNumber ?? '';
        _purchaseDate = purchase.purchaseDate ?? DateTime.now();
        final remarksText = purchase.remarks ?? '';
        _remarksController.text = remarksText.replaceAll(RegExp(r'\s*\[Paid via [^\]]+\]'), '');
        final match = RegExp(r'\[Paid via ([^\]]+)\]').firstMatch(remarksText);
        if (match != null) {
          _paymentMode = match.group(1) ?? 'Cash';
        } else {
          _paymentMode = 'Cash';
        }
        _paidAmountController.text = purchase.paidAmount?.toString() ?? '0.0';
        _discountController.text = purchase.discountAmount?.toString() ?? '0.0';

        try { await purchase.party.load(); } catch (_) {}
        _selectedParty = purchase.party.value ?? (purchase.partyId != null ? await isar.partys.get(purchase.partyId!) : null);
        if (_selectedParty == null && purchase.partyName != null && purchase.partyName!.isNotEmpty) {
          _selectedParty = await isar.partys.filter().partyNameEqualTo(purchase.partyName!).findFirst();
          if (_selectedParty == null) {
            _selectedParty = Party()
              ..partyName = purchase.partyName
              ..gstNumber = purchase.gstNumber
              ..addressLine1 = purchase.address;
          }
        }

        try { await purchase.purchaseItems.load(); } catch (_) {}
        var itemsList = purchase.purchaseItems.toList();

        final pId = purchase.id;
        final pUuid = purchase.uuid;

        List<PurchaseItem> queriedItems = [];
        if (pUuid != null && pUuid.isNotEmpty) {
          queriedItems = await isar.purchaseItems
              .filter()
              .purchaseUuidEqualTo(pUuid)
              .findAll();
        }
        if (queriedItems.isEmpty && pId != 0 && pId != Isar.autoIncrement) {
          queriedItems = await isar.purchaseItems
              .filter()
              .purchaseIdEqualTo(pId)
              .findAll();
        }

        if (queriedItems.isNotEmpty) {
          itemsList = queriedItems;
        }

        for (var pi in itemsList) {
          if (!kIsWeb) {
            try { await pi.item.load(); } catch (_) {}
          }
          if (pi.item.value == null && pi.itemId != null) {
            try {
              pi.item.value = await isar.items.get(pi.itemId!);
            } catch (_) {}
          }
          if (pi.item.value != null) {
            try { await pi.item.value!.unit.load(); } catch (_) {}
          }
        }

        _draftItems = List<PurchaseItem>.from(itemsList);
        _recalculateTotals();
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      final numStr = await repo.generateNextPurchaseNumber();
      _billNumberController.text = numStr;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _billNumberController.dispose();
    _supplierInvoiceNumberController.dispose();
    _paidAmountController.dispose();
    _discountController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    double sub = 0.0;
    double tax = 0.0;

    for (var item in _draftItems) {
      final double qty = item.quantity ?? 0.0;
      final double rate = item.rate ?? 0.0;
      final double itemDisc = item.discount ?? 0.0;
      
      final lineSub = qty * rate;
      final lineTaxable = lineSub - itemDisc;
      final lineTax = lineTaxable * ((item.gstRate ?? 0.0) / 100.0);
      
      item.taxableAmount = lineTaxable;
      item.gstAmount = lineTax;
      item.totalAmount = lineTaxable + lineTax;

      sub += lineSub;
      tax += lineTax;
    }

    _discountAmount = double.tryParse(_discountController.text) ?? 0.0;
    final double rawTotal = (sub - _discountAmount) + tax;
    _roundOff = _customRoundOff ?? (rawTotal.roundToDouble() - rawTotal);

    setState(() {
      _subtotal = sub;
      _taxableAmount = sub - _discountAmount;
      _totalGST = tax;
      _grandTotal = rawTotal + _roundOff;
    });
  }


  void _addItemLine(Item item) async {

    try {
      await item.unit.load();
    } catch (_) {}

    final primaryUnitName = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';

    final newItem = PurchaseItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = 1.0
      ..unit = primaryUnitName
      ..rate = item.buyRate ?? item.sellRate ?? 0.0
      ..discount = 0.0
      ..gstRate = item.gstRate ?? 18.0;
      
    newItem.item.value = item;

    setState(() {
      _draftItems.add(newItem);
    });
    _recalculateTotals();
  }

  void _saveBill() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier party.')),
      );
      return;
    }

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to purchase.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final double paidAmt = double.tryParse(_paidAmountController.text) ?? 0.0;
      final double pendingAmt = _grandTotal - paidAmt;
      final String paymentStat = pendingAmt <= 0 ? 'Paid' : (paidAmt > 0 ? 'Partially Paid' : 'Unpaid');

      String currentRemarks = _remarksController.text.trim();
      currentRemarks = currentRemarks.replaceAll(RegExp(r'\s*\[Paid via [^\]]+\]'), '');
      if (paidAmt > 0) {
        currentRemarks += ' [Paid via $_paymentMode]';
      }

      final purchase = _existingPurchase ?? Purchase();
      if (_existingPurchase == null) {
        purchase.uuid ??= Uuid().v4();
        purchase.purchaseNumber = _billNumberController.text.trim();
        purchase.createdAt = DateTime.now();
        purchase.version = 1;
      } else {
        purchase.uuid ??= Uuid().v4();
        purchase.version = _existingPurchase!.version + 1;
      }

      purchase
        ..purchaseDate = _purchaseDate
        ..purchaseNumber = _billNumberController.text.trim()
        ..supplierInvoiceNumber = _supplierInvoiceNumberController.text.trim()
        ..partyId = _selectedParty!.id
        ..partyName = _selectedParty!.partyName
        ..gstNumber = _selectedParty!.gstNumber
        ..address = _selectedParty!.addressLine1
        ..subtotal = _subtotal
        ..discountAmount = _discountAmount
        ..taxableAmount = _taxableAmount
        ..totalGST = _totalGST
        ..roundOff = _roundOff
        ..grandTotal = _grandTotal

        ..paidAmount = paidAmt
        ..pendingAmount = pendingAmt
        ..paymentStatus = paymentStat
        ..remarks = currentRemarks
        ..updatedAt = DateTime.now();

      if (!kIsWeb) {
        purchase.party.value = _selectedParty;
      }

      await Future.delayed(Duration.zero);
      final success = await ref
          .read(purchaseNotifierProvider.notifier)
          .savePurchase(purchase, _draftItems);

      ref.invalidate(dashboardAnalyticsProvider);

      // Lightweight non-blocking quiet background sync
      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase invoice saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save purchase: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        _buildCartItemsTable(theme),
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
            Text('Bill settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Paid Amount (₹)', border: OutlineInputBorder()),
                    onChanged: (val) => _recalculateTotals(),
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
                        const DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                        ..._paymentModesList.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? ''),
                        )),
                      ];
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode)));
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            tooltip: 'Add Payment Type',
                            onPressed: _showAddPaymentModeDialog,
                          ),
                        ],
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bill Level Discount (₹)', border: OutlineInputBorder()),
              onChanged: (val) => _recalculateTotals(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks / Notes', border: OutlineInputBorder()),
            ),
            const Divider(height: 32),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save Purchase Bill'),
              onPressed: _saveBill,
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
        title: Text(
          widget.purchaseUuid != null
              ? 'Edit Purchase Bill ${_billNumberController.text.isNotEmpty ? "(#${_billNumberController.text})" : ""}'
              : 'New Purchase Bill ${_billNumberController.text.isNotEmpty ? "(#${_billNumberController.text})" : ""}',
        ),
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
                  const SizedBox(height: 30),
                ],
              ),
      ),
      bottomNavigationBar: !isDesktop
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Grand Total (${_draftItems.length} items)',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '₹${_grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save Purchase Bill', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _saveBill,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyAndHeaderCard(ThemeData theme) {
    final partiesAsync = ref.watch(partiesListProvider);

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
              Text('Supplier Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            partiesAsync.when(
              data: (parties) {
                final supplierParties = parties.where((p) => p.partyType == 'Supplier').toList();
                return SearchablePartyDropdown(
                  parties: supplierParties,
                  selectedParty: _selectedParty != null && supplierParties.any((p) => (p.uuid != null && p.uuid == _selectedParty!.uuid) || p.id == _selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == _selectedParty!.partyName?.trim().toLowerCase()))
                      ? supplierParties.firstWhere((p) => (p.uuid != null && p.uuid == _selectedParty!.uuid) || p.id == _selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == _selectedParty!.partyName?.trim().toLowerCase()))
                      : _selectedParty,
                  labelText: 'Select Supplier Account',
                  onChanged: (party) {
                    setState(() {
                      _selectedParty = party;
                    });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading suppliers: $e'),
            ),
            if (_selectedParty != null) ...[
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
                        'GST: ${_selectedParty!.gstNumber ?? "Unregistered"} | Address: ${_selectedParty!.city ?? "N/A"} | Current Balance: ₹${_selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
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
                        initialDate: _purchaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _purchaseDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Purchase Date', border: OutlineInputBorder(), isDense: true),
                      child: Text(DateFormat('dd-MM-yyyy').format(_purchaseDate), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _billNumberController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Internal Bill # (Auto)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _supplierInvoiceNumberController,
                    decoration: const InputDecoration(labelText: 'Supplier Invoice #', border: OutlineInputBorder(), isDense: true),
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
                          _addItemLine(item);
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
                                        'Code: ${item.itemCode ?? "N/A"} | Buy: ₹${item.buyRate?.toStringAsFixed(2) ?? "0"} | Stock: ${item.currentStock?.toInt() ?? 0}',
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
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  tooltip: 'Search & Pick Item from Catalog',
                  onPressed: () async {
                    final selectedItem = await ItemSearchPickerModal.show(context, isPurchase: true);
                    if (selectedItem != null) {
                      _addItemLine(selectedItem);
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

  Widget _buildCartItemsTable(ThemeData theme) {
    if (_draftItems.isEmpty) {
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
             ConstrainedBox(
               constraints: const BoxConstraints(maxHeight: 450),
               child: Scrollbar(
                 thumbVisibility: true,
                 controller: _itemsScrollController,
                 child: ListView.separated(
                   controller: _itemsScrollController,
                   shrinkWrap: true,
                   itemCount: _draftItems.length,
                   separatorBuilder: (context, index) => const Divider(height: 24),
                   itemBuilder: (context, index) {
                     final item = _draftItems[index];
                     return PurchaseCartItemRow(
                       index: index,
                       item: item,
                       onDelete: () {
                         setState(() {
                           _draftItems.removeAt(index);
                         });
                         _recalculateTotals();
                       },
                       onChanged: (qty, rate, discount, gstRate) {
                         setState(() {
                           item.quantity = qty;
                           item.rate = rate;
                           item.discount = discount;
                           item.gstRate = gstRate;
                         });
                         _recalculateTotals();
                       },
                     );
                   },
                 ),
               ),
             ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final selectedItem = await ItemSearchPickerModal.show(context, isPurchase: true);
                if (selectedItem != null) {
                  _addItemLine(selectedItem);
                  ref.invalidate(filteredItemsProvider);
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text('+ Add Another Item from Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    final double paidAmt = double.tryParse(_paidAmountController.text) ?? 0.0;
    final double pendingAmt = _grandTotal - paidAmt;

    final isLocal = GstService().isIntrastate(_companyGst, _selectedParty?.gstNumber, partyState: _selectedParty?.state);

    final totalGst = _totalGST;
    final cgst = isLocal ? totalGst / 2.0 : 0.0;
    final sgst = isLocal ? totalGst / 2.0 : 0.0;
    final igst = isLocal ? 0.0 : totalGst;

    // Dynamic Tax Slab Calculation
    final gstRates = _draftItems.map((i) => i.gstRate ?? 18.0).toSet().toList();
    String cgstLabel = 'CGST';
    String sgstLabel = 'SGST';
    String igstLabel = 'IGST';

    if (gstRates.length == 1) {
      final singleRate = gstRates.first;
      final halfRate = singleRate / 2.0;
      final halfStr = halfRate % 1 == 0 ? halfRate.toInt().toString() : halfRate.toStringAsFixed(1);
      final rateStr = singleRate % 1 == 0 ? singleRate.toInt().toString() : singleRate.toStringAsFixed(1);
      cgstLabel = 'CGST ($halfStr%)';
      sgstLabel = 'SGST ($halfStr%)';
      igstLabel = 'IGST ($rateStr%)';
    } else if (gstRates.length > 1) {
      cgstLabel = 'CGST (Multiple Tax Rates)';
      sgstLabel = 'SGST (Multiple Tax Rates)';
      igstLabel = 'IGST (Multiple Tax Rates)';
    }

    return Column(
      children: [
        _buildSummaryRow('Subtotal (Before Discount)', _subtotal, theme),
        _buildSummaryRow('Discounts Total', -_discountAmount, theme),
        _buildSummaryRow('Taxable Value', _taxableAmount, theme),
        if (isLocal) ...[
          _buildSummaryRow(cgstLabel, cgst, theme),
          _buildSummaryRow(sgstLabel, sgst, theme),
        ] else ...[
          _buildSummaryRow(igstLabel, igst, theme),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Round Off', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  if (_customRoundOff != null)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.blue),
                      tooltip: 'Reset to Auto Round Off',
                      onPressed: () {
                        _customRoundOff = null;
                        _recalculateTotals();
                      },
                    ),
                ],
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: _roundOff.toStringAsFixed(2),
                  key: ValueKey('roundoff_${_customRoundOff}_$_roundOff'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      _customRoundOff = parsed;
                      _recalculateTotals();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        _buildSummaryRow('GRAND TOTAL', _grandTotal, theme, isBold: true),
        _buildSummaryRow('Pending Outstanding', pendingAmt < 0 ? 0.0 : pendingAmt, theme, isPending: true),
      ],
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

class PurchaseCartItemRow extends ConsumerStatefulWidget {
  final int index;
  final PurchaseItem item;
  final VoidCallback onDelete;
  final Function(double qty, double rate, double discount, double gstRate) onChanged;

  const PurchaseCartItemRow({
    Key? key,
    required this.index,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  }) : super(key: key);

  @override
  ConsumerState<PurchaseCartItemRow> createState() => _PurchaseCartItemRowState();
}

class _PurchaseCartItemRowState extends ConsumerState<PurchaseCartItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _rateExclController;
  late TextEditingController _rateInclController;
  late TextEditingController _discController;
  late TextEditingController _gstController;
  late TextEditingController _batchController;
  late TextEditingController _mfgDateController;
  late TextEditingController _expDateController;

  bool _isUpdatingLocally = false;
  bool _showMoreDetails = false;
  Item? _resolvedDbItem;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final double excl = item.rate ?? 0.0;
    final double gstPct = item.gstRate ?? 18.0;
    final double incl = excl * (1 + gstPct / 100.0);

    _qtyController = TextEditingController(text: item.quantity?.toInt().toString() ?? '1');
    _rateExclController = TextEditingController(text: excl.toStringAsFixed(2));
    _rateInclController = TextEditingController(text: incl.toStringAsFixed(2));
    _discController = TextEditingController(text: item.discount?.toString() ?? '0.0');
    _gstController = TextEditingController(text: gstPct.toString());
    _batchController = TextEditingController(text: item.batchNumber ?? '');
    _mfgDateController = TextEditingController(text: item.mfgDate ?? '');
    _expDateController = TextEditingController(text: item.expiryDate ?? '');

    _loadDbItem();
  }


  Future<void> _loadDbItem() async {
    final item = widget.item;
    if (item.item.value != null) {
      _resolvedDbItem = item.item.value;
      if (_resolvedDbItem?.unit.value == null) {
        try { await _resolvedDbItem?.unit.load(); } catch (_) {}
      }
      if (mounted) setState(() {});
    } else if (item.itemId != null) {
      try {
        final isar = ref.read(databaseServiceProvider).isar;
        final fetched = await isar.items.get(item.itemId!);
        if (fetched != null) {
          try { await fetched.unit.load(); } catch (_) {}
          item.item.value = fetched;
          if (mounted) {
            setState(() {
              _resolvedDbItem = fetched;
            });
          }
        }
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(PurchaseCartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.itemId != widget.item.itemId || widget.item.item.value != _resolvedDbItem) {
      _loadDbItem();
    }
    if (_isUpdatingLocally) return;

    final item = widget.item;
    final double excl = item.rate ?? 0.0;
    final double gstPct = item.gstRate ?? 18.0;
    final double incl = excl * (1 + gstPct / 100.0);

    _updateIfChanged(_qtyController, item.quantity?.toInt().toString() ?? '1');
    _updateIfChanged(_rateExclController, excl.toStringAsFixed(2));
    _updateIfChanged(_rateInclController, incl.toStringAsFixed(2));
    _updateIfChanged(_discController, item.discount?.toString() ?? '0.0');
    _updateIfChanged(_gstController, gstPct.toString());
  }

  void _updateIfChanged(TextEditingController controller, String value) {
    if (controller.text != value && double.tryParse(controller.text) != double.tryParse(value)) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateExclController.dispose();
    _rateInclController.dispose();
    _discController.dispose();
    _gstController.dispose();
    _batchController.dispose();
    _mfgDateController.dispose();
    _expDateController.dispose();
    super.dispose();
  }


  void _triggerChanged({double? qty, double? exclRate, double? disc, double? gst}) {
    final targetQty = qty ?? double.tryParse(_qtyController.text) ?? 1.0;
    final targetExcl = exclRate ?? double.tryParse(_rateExclController.text) ?? 0.0;
    final targetDisc = disc ?? double.tryParse(_discController.text) ?? 0.0;
    final targetGst = gst ?? double.tryParse(_gstController.text) ?? 18.0;
    
    widget.onChanged(targetQty, targetExcl, targetDisc, targetGst);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dbItem = _resolvedDbItem ?? item.item.value;
    final primaryUnit = dbItem?.primaryUnitName ?? dbItem?.unit.value?.shortName ?? dbItem?.unit.value?.unitName ?? item.unit ?? 'PCS';
    final secondaryUnit = dbItem?.secondaryUnit;
    final List<String> availableUnits = [
      primaryUnit,
      if (secondaryUnit != null && secondaryUnit.isNotEmpty && secondaryUnit != primaryUnit) secondaryUnit,
    ];
    if (item.unit != null && item.unit!.isNotEmpty && !availableUnits.contains(item.unit)) {
      availableUnits.add(item.unit!);
    }
    final selectedUnit = item.unit ?? primaryUnit;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);

    if (!isDesktop) {
      // Mobile-optimized purchase item card
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Index, Item Name, Delete Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${widget.index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.itemName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              const Divider(height: 16),

              // Qty Stepper & Unit Selector
              Row(
                children: [
                  // Qty Stepper
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                          onPressed: () {
                            final current = item.quantity ?? 1.0;
                            if (current > 1) {
                              final next = current - 1.0;
                              _qtyController.text = next.toInt().toString();
                              _triggerChanged(qty: next);
                            }
                          },
                        ),
                        SizedBox(
                          width: 44,
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            onChanged: (val) {
                              final double? qtyVal = double.tryParse(val);
                              if (qtyVal != null && qtyVal >= 0) {
                                _triggerChanged(qty: qtyVal);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                          onPressed: () {
                            final next = (item.quantity ?? 1.0) + 1.0;
                            _qtyController.text = next.toInt().toString();
                            _triggerChanged(qty: next);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unit Selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: availableUnits.contains(selectedUnit) ? selectedUnit : availableUnits.first,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      items: availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => item.unit = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Rate Excl & Disc
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _rateExclController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Purchase Rate (₹)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final double? excl = double.tryParse(val);
                        if (excl != null) {
                          _triggerChanged(exclRate: excl);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _discController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Disc (₹)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final double? discVal = double.tryParse(val);
                        if (discVal != null) {
                          _triggerChanged(disc: discVal);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Expandable Batch, Mfg/Exp Date & Free Qty
              InkWell(
                onTap: () {
                  setState(() {
                    _showMoreDetails = !_showMoreDetails;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showMoreDetails ? '▲ Hide Batch, Free Qty & GST Details' : '▼ More Inputs (Free Qty, Batch, Expiry, GST %)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showMoreDetails) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rateInclController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Rate Incl (₹)', isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                final double? incl = double.tryParse(val);
                                if (incl != null) {
                                  final gstPct = double.tryParse(_gstController.text) ?? 18.0;
                                  final excl = incl / (1 + gstPct / 100.0);
                                  _triggerChanged(exclRate: excl);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _gstController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'GST %', isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                final double? gstVal = double.tryParse(val);
                                if (gstVal != null) {
                                  _triggerChanged(gst: gstVal);
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
                              controller: _batchController,
                              decoration: const InputDecoration(labelText: 'Batch No.', isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                item.batchNumber = val.trim();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _mfgDateController,
                              decoration: const InputDecoration(labelText: 'Mfg Date', isDense: true, border: OutlineInputBorder()),
                              onChanged: (val) {
                                item.mfgDate = val.trim();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _expDateController,
                        decoration: const InputDecoration(labelText: 'Expiry Date (e.g. 12/28)', isDense: true, border: OutlineInputBorder()),
                        onChanged: (val) {
                          item.expiryDate = val.trim();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Line Total Summary Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GST: ${_gstController.text}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    Text(
                      'Total: ₹${(item.totalAmount ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${widget.index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.itemName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: widget.onDelete,
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
                  final double? qtyVal = double.tryParse(val);
                  if (qtyVal != null) {
                    _triggerChanged(qty: qtyVal);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: availableUnits.contains(selectedUnit) ? selectedUnit : availableUnits.first,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final oldUnit = selectedUnit;
                    final newUnit = val;
                    if (oldUnit != newUnit) {
                      final conv = dbItem?.conversionFactor ?? 1.0;
                      if (conv > 0 && conv != 1.0) {
                        double currentRate = item.rate ?? 0.0;
                        double newRate = currentRate;
                        if (oldUnit == primaryUnit && newUnit == secondaryUnit) {
                          newRate = currentRate / conv;
                        } else if (oldUnit == secondaryUnit && newUnit == primaryUnit) {
                          newRate = currentRate * conv;
                        }

                        final gstPct = double.tryParse(_gstController.text) ?? 18.0;
                        final double rateIncl = newRate * (1 + gstPct / 100.0);

                        _isUpdatingLocally = true;
                        _rateExclController.text = newRate.toStringAsFixed(2);
                        _rateInclController.text = rateIncl.toStringAsFixed(2);
                        _isUpdatingLocally = false;

                        setState(() {
                          item.unit = newUnit;
                          item.rate = newRate;
                        });
                        _triggerChanged(exclRate: newRate);
                      } else {
                        setState(() {
                          item.unit = newUnit;
                        });
                      }
                    }
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
                  
                  final gstPct = double.tryParse(_gstController.text) ?? 18.0;
                  final incl = excl * (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateInclController.text = incl.toStringAsFixed(2);
                  _isUpdatingLocally = false;
                  
                  _triggerChanged(exclRate: excl);
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
                  
                  final gstPct = double.tryParse(_gstController.text) ?? 18.0;
                  final excl = incl / (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateExclController.text = excl.toStringAsFixed(2);
                  _isUpdatingLocally = false;
                  
                  _triggerChanged(exclRate: excl);
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
                controller: _discController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? discVal = double.tryParse(val);
                  if (discVal != null) {
                    _triggerChanged(disc: discVal);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _gstController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'GST Tax %', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  final double? gstVal = double.tryParse(val);
                  if (gstVal != null) {
                    final excl = double.tryParse(_rateExclController.text) ?? 0.0;
                    final incl = excl * (1 + gstVal / 100.0);
                    
                    _isUpdatingLocally = true;
                    _rateInclController.text = incl.toStringAsFixed(2);
                    _isUpdatingLocally = false;
                    
                    _triggerChanged(gst: gstVal);
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
                controller: _batchController,
                decoration: const InputDecoration(labelText: 'Batch No.', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  widget.item.batchNumber = val.trim();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _mfgDateController,
                decoration: const InputDecoration(labelText: 'MFG Date', hintText: 'MM/YYYY', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  widget.item.mfgDate = val.trim();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _expDateController,
                decoration: const InputDecoration(labelText: 'EXP Date', hintText: 'MM/YYYY', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  widget.item.expiryDate = val.trim();
                },
              ),
            ),
          ],
        ),
      ],
    );

  }
}

