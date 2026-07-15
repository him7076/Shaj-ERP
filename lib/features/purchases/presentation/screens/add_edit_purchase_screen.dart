import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class AddEditPurchaseScreen extends ConsumerStatefulWidget {
  const AddEditPurchaseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditPurchaseScreen> createState() => _AddEditPurchaseScreenState();
}

class _AddEditPurchaseScreenState extends ConsumerState<AddEditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0.0');
  final _productSearchController = TextEditingController();

  Party? _selectedParty;
  List<PurchaseItem> _draftItems = [];
  DateTime _purchaseDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));

  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _taxableAmount = 0.0;
  double _totalGST = 0.0;
  double _grandTotal = 0.0;
  bool _isSaving = false;
  String? _companyGst;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() async {
    final repo = ref.read(purchaseRepositoryProvider);
    final numStr = await repo.generateNextPurchaseNumber();
    final isar = ref.read(databaseServiceProvider).isar;
    final settings = await isar.settings.where().findFirst();
    setState(() {
      _billNumberController.text = numStr;
      _companyGst = settings?.companyGST;
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _billNumberController.dispose();
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

    setState(() {
      _subtotal = sub;
      _taxableAmount = sub - _discountAmount;
      _totalGST = tax;
      _grandTotal = _taxableAmount + _totalGST;
    });
  }

  void _addItemLine(Item item) {
    // Check if item is already added
    final exists = _draftItems.any((element) => element.itemId == item.id);
    if (exists) {
      final existingIndex = _draftItems.indexWhere((element) => element.itemId == item.id);
      setState(() {
        _draftItems[existingIndex].quantity = (_draftItems[existingIndex].quantity ?? 0.0) + 1.0;
      });
      _recalculateTotals();
      return;
    }

    final newItem = PurchaseItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = 1.0
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

      final purchase = Purchase()
        ..purchaseNumber = _billNumberController.text.trim()
        ..purchaseDate = _purchaseDate
        ..partyId = _selectedParty!.id
        ..partyName = _selectedParty!.partyName
        ..gstNumber = _selectedParty!.gstNumber
        ..address = _selectedParty!.addressLine1
        ..subtotal = _subtotal
        ..discountAmount = _discountAmount
        ..taxableAmount = _taxableAmount
        ..totalGST = _totalGST
        ..grandTotal = _grandTotal
        ..paidAmount = paidAmt
        ..pendingAmount = pendingAmt
        ..paymentStatus = paymentStat
        ..remarks = _remarksController.text.trim();

      purchase.party.value = _selectedParty;

      final success = await ref
          .read(purchaseNotifierProvider.notifier)
          .savePurchase(purchase, _draftItems);

      ref.invalidate(dashboardAnalyticsProvider);

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bill settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _billNumberController,
              decoration: const InputDecoration(labelText: 'Purchase Bill Number', border: OutlineInputBorder()),
            ),
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Bill'),
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
            Text('Supplier Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: partiesAsync.when(
                    data: (parties) {
                      final supplierParties = parties.where((p) => p.partyType == 'Supplier').toList();
                      return DropdownButtonFormField<Party>(
                        value: _selectedParty != null && supplierParties.any((p) => p.uuid == _selectedParty!.uuid)
                            ? supplierParties.firstWhere((p) => p.uuid == _selectedParty!.uuid)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Supplier Profile',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: supplierParties.map((p) {
                          return DropdownMenuItem<Party>(value: p, child: Text(p.partyName ?? ''));
                        }).toList(),
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
                      decoration: const InputDecoration(labelText: 'Purchase Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd-MM-yyyy').format(_purchaseDate)),
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
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final newlyCreated = await AddItemSheet.show(context);
                    if (newlyCreated != null) {
                      _addItemLine(newlyCreated);
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
              itemCount: _draftItems.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = _draftItems[index];
                return PurchaseCartItemRow(
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
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSummaryPanel(ThemeData theme) {
    final double paidAmt = double.tryParse(_paidAmountController.text) ?? 0.0;
    final double pendingAmt = _grandTotal - paidAmt;

    final cleanCompany = _companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    final cleanParty = _selectedParty?.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

    final totalGst = _totalGST;
    final cgst = isLocal ? totalGst / 2.0 : 0.0;
    final sgst = isLocal ? totalGst / 2.0 : 0.0;
    final igst = isLocal ? 0.0 : totalGst;

    return Column(
      children: [
        _buildSummaryRow('Subtotal (Before Discount)', _subtotal, theme),
        _buildSummaryRow('Discounts Total', -_discountAmount, theme),
        _buildSummaryRow('Taxable Value', _taxableAmount, theme),
        if (isLocal) ...[
          _buildSummaryRow('CGST (9%)', cgst, theme),
          _buildSummaryRow('SGST (9%)', sgst, theme),
        ] else ...[
          _buildSummaryRow('IGST (18%)', igst, theme),
        ],
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

class PurchaseCartItemRow extends StatefulWidget {
  final PurchaseItem item;
  final VoidCallback onDelete;
  final Function(double qty, double rate, double discount, double gstRate) onChanged;

  const PurchaseCartItemRow({
    Key? key,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PurchaseCartItemRow> createState() => _PurchaseCartItemRowState();
}

class _PurchaseCartItemRowState extends State<PurchaseCartItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _rateExclController;
  late TextEditingController _rateInclController;
  late TextEditingController _discController;
  late TextEditingController _gstController;

  bool _isUpdatingLocally = false;

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
  }

  @override
  void didUpdateWidget(PurchaseCartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
      ],
    );
  }
}

