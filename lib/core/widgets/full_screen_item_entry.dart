import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_fixed_asset_sheet.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/core/utils/unit_conversion_helper.dart';
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
  final String? description;
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
    this.description,
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
  final FullScreenItemEntryData? initialData;
  final Function(FullScreenItemEntryData) onAdd;

  const FullScreenItemEntry({
    Key? key,
    this.isPurchase = false,
    this.isFixedAsset = false,
    this.onlyBundles = false,
    this.excludeBundles = false,
    this.initialData,
    required this.onAdd,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {bool isPurchase = false, bool isFixedAsset = false, bool onlyBundles = false, bool excludeBundles = false, FullScreenItemEntryData? initialData, required Function(FullScreenItemEntryData) onAdd}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenItemEntry(isPurchase: isPurchase, isFixedAsset: isFixedAsset, onlyBundles: onlyBundles, excludeBundles: excludeBundles, initialData: initialData, onAdd: onAdd),
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
  final TextEditingController _descriptionController = TextEditingController();
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
    
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _selectedItem = d.item;
      _qtyController.text = d.quantity.toString();
      _saleRateController.text = d.saleRate.toString();
      _purchaseRateController.text = d.purchaseRate.toString();
      _batchController.text = d.batchNumber ?? '';
      _descriptionController.text = d.description ?? '';
      _discountController.text = d.discountPercent > 0 ? d.discountPercent.toString() : d.discountAmount.toString();
      _isDiscountPercent = d.discountPercent > 0 || (d.discountPercent == 0 && d.discountAmount == 0);
      _gstController.text = d.gstRate.toString();
      _mfgDate = d.mfgDate;
      _expDate = d.expDate;
      _isSaleWithTax = d.isSaleRateWithTax;
      _isPurchaseWithTax = d.isPurchaseRateWithTax;
      _selectedUnit = d.unit;
      
      _availableUnits = [
        if (d.item.primaryUnitName != null && d.item.primaryUnitName!.isNotEmpty) d.item.primaryUnitName!,
        if (d.item.secondaryUnit != null && d.item.secondaryUnit!.isNotEmpty) d.item.secondaryUnit!,
        if (d.item.tertiaryUnit != null && d.item.tertiaryUnit!.isNotEmpty) d.item.tertiaryUnit!,
      ];
      if (_availableUnits.isEmpty) _availableUnits.add(d.item.unit.value?.shortName ?? d.item.unit.value?.unitName ?? 'PCS');
      
      _calculateTotals();
    }
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
    double multNew = 1.0;
    if (UnitConversionHelper.areUnitsMatching(newUnit, item.secondaryUnit)) {
      multNew = item.conversionFactor ?? 1.0;
    } else if (UnitConversionHelper.areUnitsMatching(newUnit, item.tertiaryUnit)) {
      multNew = (item.conversionFactor ?? 1.0) * (item.secondaryToTertiaryConversion ?? 1.0);
    }
    
    double multOld = 1.0;
    if (UnitConversionHelper.areUnitsMatching(_selectedUnit, item.secondaryUnit)) {
      multOld = item.conversionFactor ?? 1.0;
    } else if (UnitConversionHelper.areUnitsMatching(_selectedUnit, item.tertiaryUnit)) {
      multOld = (item.conversionFactor ?? 1.0) * (item.secondaryToTertiaryConversion ?? 1.0);
    }
    
    // Switching from Old Unit to New Unit: rate multiplier is multOld / multNew
    // E.g. Box (mult 1) to Pcs (mult 10) -> multOld/multNew = 1/10 = 0.1 (Rate per Pcs = Rate per Box / 10)
    final double relativeFactor = multNew > 0 ? (multOld / multNew) : 1.0;
    
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
    final prefs = ref.read(sharedPreferencesProvider);
    final showPurchaseRate = prefs.getBool('enable_sales_buy_price') ?? false;

    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final saleRateInput = double.tryParse(_saleRateController.text) ?? 0.0;
    final purchaseRateInput = double.tryParse(_purchaseRateController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final discountVal = double.tryParse(_discountController.text) ?? 0.0;
    
    final activeRateInput = (widget.isPurchase && showPurchaseRate && purchaseRateInput > 0)
        ? purchaseRateInput
        : (saleRateInput > 0 ? saleRateInput : purchaseRateInput);
    final isTaxInclusive = (widget.isPurchase && showPurchaseRate) ? _isPurchaseWithTax : _isSaleWithTax;
    
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
    
    final prefs = ref.read(sharedPreferencesProvider);
    final showPurchaseRate = prefs.getBool('enable_sales_buy_price') ?? false;

    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final saleRateInput = double.tryParse(_saleRateController.text) ?? 0.0;
    final purchaseRateInput = double.tryParse(_purchaseRateController.text) ?? 0.0;
    final gst = double.tryParse(_gstController.text) ?? 0.0;
    final discountVal = double.tryParse(_discountController.text) ?? 0.0;
    
    final activeRateInput = (widget.isPurchase && showPurchaseRate && purchaseRateInput > 0)
        ? purchaseRateInput
        : (saleRateInput > 0 ? saleRateInput : purchaseRateInput);
    final isTaxInclusive = (widget.isPurchase && showPurchaseRate) ? _isPurchaseWithTax : _isSaleWithTax;
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
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.initialData != null ? '${_selectedItem!.itemName} updated!' : '${_selectedItem!.itemName} added!')));
    Navigator.pop(context);
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    final prefs = ref.watch(sharedPreferencesProvider);
    final showPurchaseRate = prefs.getBool('enable_sales_buy_price') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData != null 
            ? (widget.isFixedAsset ? 'Edit Fixed Asset' : 'Edit Item') 
            : (widget.isFixedAsset ? 'Add Fixed Asset' : 'Add Item')),
        centerTitle: true,
        elevation: 0,
        actions: const [],
      ),
      body: widget.isFixedAsset
          ? ref.watch(fixedAssetListProvider).when(
              data: (assets) {
                final faItems = assets.map((fa) {
                  return Item()
                    ..id = fa.id
                    ..uuid = fa.uuid
                    ..itemName = fa.assetName
                    ..itemCode = fa.assetCode
                    ..hsnCode = fa.hsnCode
                    ..gstRate = fa.gstRate ?? 18.0
                    ..sellRate = fa.purchasePrice ?? 0.0
                    ..buyRate = fa.purchasePrice ?? 0.0
                    ..currentStock = fa.quantity ?? 1.0
                    ..primaryUnitName = fa.unit ?? 'PCS';
                }).toList();

                final stdItems = itemsAsync.valueOrNull?.where((i) => i.category.value?.categoryName == 'Fixed Assets').toList() ?? [];
                final combined = [...faItems, ...stdItems];
                return _buildMainContent(context, theme, combined, showPurchaseRate);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading fixed assets: $err')),
            )
          : itemsAsync.when(
              data: (allItems) {
                final items = allItems.where((i) {
                  if (widget.onlyBundles && !i.isBundle) return false;
                  if (widget.excludeBundles && i.isBundle) return false;
                  return i.category.value?.categoryName != 'Fixed Assets';
                }).toList();

                return _buildMainContent(context, theme, items, showPurchaseRate);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
      bottomNavigationBar: _buildBottomBar(context, theme),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme, List<Item> items, bool showPurchaseRate) {
    return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
                            elevation: 0,
                            shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _selectedItem!.itemName ?? 'Unknown Item', 
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  
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
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          items: _availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                          onChanged: _onUnitChange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

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
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  const SizedBox(height: 12),

                                  if (showPurchaseRate) ...[
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
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                  const SizedBox(height: 12),
                                  ],

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
                                  const SizedBox(height: 12),

                                  // BATCH, MFG, EXP
                                  _buildModernTextField('Batch Number', _batchController),
                                  const SizedBox(height: 12),
                                  Consumer(
                                    builder: (context, r, child) {
                                      final prefs = r.watch(sharedPreferencesProvider);
                                      final isBundle = _selectedItem?.isBundle == true;
                                      final showDesc = isBundle
                                          ? (prefs.getBool('enable_bundle_description') ?? false)
                                          : (prefs.getBool('enable_item_description') ?? false);
                                      if (!showDesc) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: TextFormField(
                                          controller: _descriptionController,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText: 'Description',
                                            alignLabelWithHint: true,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }
                                  ),
                                  const SizedBox(height: 12),
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
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          
                          const SizedBox(height: 12),
                          
                          // SUMMARY CARD
                          Card(
                            elevation: 0,
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
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
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 2,
                      ),
                      child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}