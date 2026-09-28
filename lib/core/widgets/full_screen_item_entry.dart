import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_item_dropdown.dart';

class FullScreenItemEntryData {
  final Item item;
  final double quantity;
  final double rate; 
  final double discountAmount;
  final double discountPercent;
  final double gstRate;
  
  final String unit;
  final String? batchNumber;
  final DateTime? mfgDate;
  final DateTime? expDate;
  
  final double saleRate;
  final double purchaseRate;
  final bool isSaleRateWithTax;
  final bool isPurchaseRateWithTax;
  final double taxableAmount;
  final double gstAmount;
  final double totalAmount;

  FullScreenItemEntryData({
    required this.item,
    required this.quantity,
    required this.rate,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    required this.gstRate,
    required this.unit,
    this.batchNumber,
    this.mfgDate,
    this.expDate,
    required this.saleRate,
    required this.purchaseRate,
    this.isSaleRateWithTax = false,
    this.isPurchaseRateWithTax = false,
    this.taxableAmount = 0.0,
    this.gstAmount = 0.0,
    this.totalAmount = 0.0,
  });
}

class FullScreenItemEntry extends ConsumerStatefulWidget {
  final bool isPurchase;
  final bool isFixedAsset;
  final bool onlyBundles;
  final bool excludeBundles;
  final Function(FullScreenItemEntryData) onAdd;

  const FullScreenItemEntry({
    Key? key,
    this.isPurchase = false,
    this.isFixedAsset = false,
    this.onlyBundles = false,
    this.excludeBundles = false,
    required this.onAdd,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {bool isPurchase = false, bool isFixedAsset = false, bool onlyBundles = false, bool excludeBundles = false, required Function(FullScreenItemEntryData) onAdd}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenItemEntry(isPurchase: isPurchase, isFixedAsset: isFixedAsset, onlyBundles: onlyBundles, excludeBundles: excludeBundles, onAdd: onAdd),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<FullScreenItemEntry> createState() => _FullScreenItemEntryState();
}

class _FullScreenItemEntryState extends ConsumerState<FullScreenItemEntry> {
  Item? _selectedItem;
  int _resetKey = 0;

  final TextEditingController _qtyController = TextEditingController(text: '1.0');
  final TextEditingController _saleRateController = TextEditingController();
  final TextEditingController _purchaseRateController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _gstController = TextEditingController(text: '18.0');

  String _selectedUnit = 'PCS';
  List<String> _availableUnits = ['PCS'];
  
  bool _isSaleWithTax = false;
  bool _isPurchaseWithTax = false;
  bool _isDiscountPercent = true;

  DateTime? _mfgDate;
  DateTime? _expDate;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_calculateTotals);
    _saleRateController.addListener(_calculateTotals);
    _purchaseRateController.addListener(_calculateTotals);
    _discountController.addListener(_calculateTotals);
    _gstController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _saleRateController.dispose();
    _purchaseRateController.dispose();
    _batchController.dispose();
    _discountController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _onItemSelect(Item item) {
    setState(() {
      _selectedItem = item;
      
      _availableUnits = [
        if (item.primaryUnitName != null && item.primaryUnitName!.isNotEmpty) item.primaryUnitName!,
        if (item.secondaryUnit != null && item.secondaryUnit!.isNotEmpty) item.secondaryUnit!,
        if (item.tertiaryUnit != null && item.tertiaryUnit!.isNotEmpty) item.tertiaryUnit!,
      ];
      if (_availableUnits.isEmpty) _availableUnits.add(item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS');
      
      _selectedUnit = _availableUnits.first;
      
      _saleRateController.text = (item.sellRate ?? 0.0).toStringAsFixed(2);
      _purchaseRateController.text = (item.buyRate ?? 0.0).toStringAsFixed(2);
      _gstController.text = (item.gstRate ?? 18.0).toStringAsFixed(2);
      
      _isSaleWithTax = false;
      _isPurchaseWithTax = false;
      _isDiscountPercent = true;
      _discountController.text = '0.0';
      _batchController.clear();
      _mfgDate = null;
      _expDate = null;
    });
    _calculateTotals();
  }

  void _onUnitChange(String? newUnit) {
    if (newUnit == null || _selectedItem == null || newUnit == _selectedUnit) return;

    final item = _selectedItem!;
    double primaryToNew = 1.0;
    if (newUnit == item.secondaryUnit) {
      primaryToNew = item.conversionFactor ?? 1.0;
    } else if (newUnit == item.tertiaryUnit) {
      primaryToNew = (item.conversionFactor ?? 1.0) * (item.secondaryToTertiaryConversion ?? 1.0);
    }
    
    double primaryToOld = 1.0;
    if (_selectedUnit == item.secondaryUnit) {
      primaryToOld = item.conversionFactor ?? 1.0;
    } else if (_selectedUnit == item.tertiaryUnit) {
      primaryToOld = (item.conversionFactor ?? 1.0) * (item.secondaryToTertiaryConversion ?? 1.0);
    }
    
    final double relativeFactor = primaryToNew / primaryToOld;
    
    final currentSale = double.tryParse(_saleRateController.text) ?? 0.0;
    final currentPurchase = double.tryParse(_purchaseRateController.text) ?? 0.0;
    
    setState(() {
      _selectedUnit = newUnit;
      if (relativeFactor > 0.0) {
        _saleRateController.text = (currentSale * relativeFactor).toStringAsFixed(2);
        _purchaseRateController.text = (currentPurchase * relativeFactor).toStringAsFixed(2);
      }
    });
    _calculateTotals();
  }

  double _subTotal = 0.0;
  double _discountAmt = 0.0;
  double _taxableAmount = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;

  void _calculateTotals() {
    if (_selectedItem == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final saleRateInput = double.tryParse(_saleRateController.text) ?? 0.0;
    final purchaseRateInput = double.tryParse(_purchaseRateController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final discountVal = double.tryParse(_discountController.text) ?? 0.0;
    
    final activeRateInput = widget.isPurchase ? purchaseRateInput : saleRateInput;
    final isTaxInclusive = widget.isPurchase ? _isPurchaseWithTax : _isSaleWithTax;
    
    final activeBaseRate = isTaxInclusive ? activeRateInput / (1 + (gst / 100)) : activeRateInput;
    
    final sub = qty * activeBaseRate;
    
    double discAmt = 0.0;
    if (_isDiscountPercent) {
      discAmt = sub * (discountVal / 100);
    } else {
      discAmt = discountVal;
    }
    
    final taxable = sub - discAmt;
    final tax = taxable * (gst / 100);
    final total = taxable + tax;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _subTotal = sub;
          _discountAmt = discAmt;
          _taxableAmount = taxable;
          _taxAmount = tax;
          _totalAmount = total;
        });
      }
    });
  }

  void _save() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an item first.')));
      return;
    }
    
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final saleRateInput = double.tryParse(_saleRateController.text) ?? 0.0;
    final purchaseRateInput = double.tryParse(_purchaseRateController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final discountVal = double.tryParse(_discountController.text) ?? 0.0;
    
    final activeRateInput = widget.isPurchase ? purchaseRateInput : saleRateInput;
    final isTaxInclusive = widget.isPurchase ? _isPurchaseWithTax : _isSaleWithTax;
    final activeBaseRate = isTaxInclusive ? activeRateInput / (1 + (gst / 100)) : activeRateInput;

    widget.onAdd(
      FullScreenItemEntryData(
        item: _selectedItem!,
        quantity: qty,
        unit: _selectedUnit,
        rate: activeBaseRate,
        discountAmount: _discountAmt,
        discountPercent: _isDiscountPercent ? discountVal : 0.0,
        gstRate: gst,
        batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
        mfgDate: _mfgDate,
        expDate: _expDate,
        saleRate: saleRateInput,
        purchaseRate: purchaseRateInput,
        isSaleRateWithTax: _isSaleWithTax,
        isPurchaseRateWithTax: _isPurchaseWithTax,
        taxableAmount: _taxableAmount,
        gstAmount: _taxAmount,
        totalAmount: _totalAmount,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedItem!.itemName} added!')));
    
    setState(() {
      _selectedItem = null;
      _qtyController.text = '1.0';
      _saleRateController.clear();
      _purchaseRateController.clear();
      _discountController.text = '0.0';
      _gstController.text = '18.0';
      _batchController.clear();
      _mfgDate = null;
      _expDate = null;
      _subTotal = 0.0;
      _discountAmt = 0.0;
      _taxableAmount = 0.0;
      _taxAmount = 0.0;
      _totalAmount = 0.0;
      _resetKey++;
    });
  }

  Future<void> _pickDate(bool isMfg) async {
    final init = isMfg ? (_mfgDate ?? DateTime.now()) : (_expDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context, 
      initialDate: init, 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100)
    );
    if (picked != null) {
      setState(() {
        if (isMfg) _mfgDate = picked; else _expDate = picked;
      });
    }
  }

  Widget _buildModernTextField(String label, TextEditingController controller, {bool isNumber = false, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? theme.colorScheme.onSurface.withOpacity(0.7),
          )),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFixedAsset ? 'Add Fixed Asset' : 'Add Item'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: itemsAsync.when(
        data: (allItems) {
          final items = allItems.where((i) {
            if (widget.isFixedAsset) {
              return i.category.value?.categoryName == 'Fixed Assets';
            }
            if (widget.onlyBundles && !i.isBundle) return false;
            if (widget.excludeBundles && i.isBundle) return false;
            return i.category.value?.categoryName != 'Fixed Assets';
          }).toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SearchableItemDropdown(
                      isFixedAsset: widget.isFixedAsset,
                      autofocus: true,
                      key: ValueKey(_resetKey),
                      items: items,
                      labelText: widget.isFixedAsset ? 'Search or add Fixed Asset...' : 'Search or add Product...',
                      onSelected: _onItemSelect,
                    ),
                  ),
                  if (_selectedItem != null)
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Card(
                            elevation: 2,
                            shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _selectedItem!.itemName ?? 'Unknown Item', 
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // QTY & UNIT
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: _buildModernTextField('Quantity', _qtyController, isNumber: true)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 4,
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedUnit,
                                          decoration: InputDecoration(
                                            labelText: 'Unit',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          items: _availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                          onChanged: _onUnitChange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // SALE RATE
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildModernTextField('Sale Rate', _saleRateController, isNumber: true)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<bool>(
                                          value: _isSaleWithTax,
                                          decoration: InputDecoration(
                                            labelText: 'Sale Tax Type',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: false, child: Text('Without Tax')),
                                            DropdownMenuItem(value: true, child: Text('With Tax')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _isSaleWithTax = val);
                                              _calculateTotals();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // PURCHASE RATE
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildModernTextField('Purchase Rate', _purchaseRateController, isNumber: true)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<bool>(
                                          value: _isPurchaseWithTax,
                                          decoration: InputDecoration(
                                            labelText: 'Purchase Tax Type',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: false, child: Text('Without Tax')),
                                            DropdownMenuItem(value: true, child: Text('With Tax')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _isPurchaseWithTax = val);
                                              _calculateTotals();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // DISCOUNT & TAX
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Row(
                                          children: [
                                            Expanded(child: _buildModernTextField('Discount', _discountController, isNumber: true)),
                                            const SizedBox(width: 8),
                                            Container(
                                              height: 52,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: theme.colorScheme.outlineVariant),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: ToggleButtons(
                                                isSelected: [_isDiscountPercent, !_isDiscountPercent],
                                                onPressed: (idx) {
                                                  setState(() => _isDiscountPercent = idx == 0);
                                                  _calculateTotals();
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                constraints: const BoxConstraints(minHeight: 52, minWidth: 36),
                                                children: const [Text('%'), Text('₹')],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 4,
                                        child: _buildModernTextField(
                                          'GST %', 
                                          _gstController, 
                                          isNumber: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // BATCH, MFG, EXP
                                  _buildModernTextField('Batch Number', _batchController),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _pickDate(true),
                                          borderRadius: BorderRadius.circular(12),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Mfg Date',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                            child: Text(_mfgDate != null ? _dateFormat.format(_mfgDate!) : 'Select Date'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _pickDate(false),
                                          borderRadius: BorderRadius.circular(12),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Exp Date',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                            child: Text(_expDate != null ? _dateFormat.format(_expDate!) : 'Select Date'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // SUMMARY CARD
                          Card(
                            elevation: 0,
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSummaryRow('Sub Total', '₹${_subTotal.toStringAsFixed(2)}'),
                                  _buildSummaryRow('Discount', '- ₹${_discountAmt.toStringAsFixed(2)}', color: Colors.red.shade400),
                                  const Divider(height: 16),
                                  _buildSummaryRow('Taxable Amount', '₹${_taxableAmount.toStringAsFixed(2)}'),
                                  _buildSummaryRow('Total Tax (${_gstController.text}%)', '+ ₹${_taxAmount.toStringAsFixed(2)}', color: Colors.blueGrey),
                                  const Divider(height: 16),
                                  _buildSummaryRow('FINAL AMOUNT', '₹${_totalAmount.toStringAsFixed(2)}', isBold: true, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
