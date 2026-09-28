import 'dart:io';
import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/widgets/full_screen_item_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/item_search_picker_modal.dart';
import 'package:business_sahaj_erp/core/utils/distance_calculator.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';


class AddEditOrderScreen extends ConsumerStatefulWidget {
  final String? orderUuid;

  const AddEditOrderScreen({Key? key, this.orderUuid}) : super(key: key);

  @override
  ConsumerState<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends ConsumerState<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _itemsScrollController = ScrollController();

  bool _isSaving = false;

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  Order? _existingOrder;
  DateTime _orderDate = DateTime.now();

  List<String> _salesmenList = ['Default Salesman', 'Salesperson 1', 'Salesperson 2'];
  String _selectedSalesman = 'Default Salesman';

  void _loadSalesmen() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final custom = prefs.getStringList('custom_salesmen_list') ?? [];
      setState(() {
        _salesmenList = ['Default Salesman', 'Salesperson 1', 'Salesperson 2', ...custom].toSet().toList();
      });
    } catch (_) {}
  }

  Future<void> _showAddSalesmanDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newSalesman = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Salesman'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Salesman Name',
                
                prefixIcon: Icon(Icons.person_add),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, nameController.text.trim());
                }
              },
              child: const Text('Save Salesman'),
            ),
          ],
        );
      },
    );

    if (newSalesman != null && newSalesman.isNotEmpty) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList('custom_salesmen_list') ?? [];
      if (!list.contains(newSalesman)) {
        list.add(newSalesman);
        await prefs.setStringList('custom_salesmen_list', list);
      }
      setState(() {
        _salesmenList = ['Default Salesman', 'Salesperson 1', 'Salesperson 2', ...list].toSet().toList();
        _selectedSalesman = newSalesman;
      });
    }
  }

    bool _isDiscountPercent = true;
  String? _attachedImage;
  String _paymentMode = "Cash";
  bool _isPaidAmountAutoFill = false;
  DateTime _dueDate = DateTime.now();
  final _paidAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSalesmen();
      ref.read(cartProvider.notifier).clear();
      if (widget.orderUuid != null) {
        _loadExistingOrder();
      }
    });
  }

  Future<void> _loadExistingOrder() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.getByUuid(widget.orderUuid!);
      if (order != null) {
        try { await order.party.load(); } catch (_) {}
        try { await order.orderItems.load(); } catch (_) {}

        _existingOrder = order;
        _remarksController.text = order.remarks ?? '';
        _discountController.text = order.discountAmount?.toString() ?? '';
        _discountPercentController.text = order.discountPercent?.toString() ?? '';
        if (order.orderDate != null) {
          _orderDate = order.orderDate!;
        }

        final cart = ref.read(cartProvider.notifier);
        final db = ref.read(databaseServiceProvider).isar;
        Party? party;
        if (order.partyId != null && order.partyId! > 0) {
          party = await db.partys.get(order.partyId!);
        }
        if (party == null && order.partyName != null && order.partyName!.isNotEmpty) {
          party = await db.partys.filter().partyNameEqualTo(order.partyName!).findFirst();
        }
        if (party == null) {
          try { await order.party.load(); } catch (_) {}
          try { party = order.party.value; } catch (_) {}
        }
        if (party != null) {
          cart.setParty(party);
        }
        cart.toggleGstInclusive(true);
        cart.setOrderDiscounts(order.discountPercent, order.discountAmount);

        List<OrderItem> orderItemsList = [];
        try {
          await order.orderItems.load();
          orderItemsList = order.orderItems.where((i) => !i.isDeleted).toList();
        } catch (_) {}

        if (orderItemsList.isEmpty) {
          final targetUuid = order.uuid;
          final targetId = order.id;
          orderItemsList = await db.orderItems.filter().isDeletedEqualTo(false)
              .and()
              .group((q) => q.orderUuidEqualTo(targetUuid ?? '').or().orderIdEqualTo(targetId))
              .findAll();
        }

        for (var orderItem in orderItemsList) {
          Item? itemObj;
          if (orderItem.itemId != null && orderItem.itemId! > 0) {
            try { itemObj = await db.items.get(orderItem.itemId!); } catch (_) {}
          }
          if (itemObj == null && orderItem.itemName != null && orderItem.itemName!.isNotEmpty) {
            try { itemObj = await db.items.filter().itemNameEqualTo(orderItem.itemName!).findFirst(); } catch (_) {}
          }
          if (itemObj == null) {
            try { await orderItem.item.load(); } catch (_) {}
            try { itemObj = orderItem.item.value; } catch (_) {}
          }
          if (itemObj != null) {
            cart.addItem(itemObj, qty: orderItem.quantity ?? 0.0);
            cart.updateItem(
              itemObj.uuid!,
              freeQuantity: orderItem.freeQuantity,
              rate: orderItem.rate,
              discountAmount: orderItem.discountAmount,
              discountPercent: orderItem.discountPercent,
            );
          }
        }
      }
    } catch (e) {
      logger.error('Failed to load existing order into cart', e);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder({bool isSaveAndNew = false}) async {
    final cart = ref.read(cartProvider);
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

    final prefs = ref.read(sharedPreferencesProvider);
    final enableNegStockWarning = prefs.getBool('enable_negative_stock_warning') ?? true;

    if (enableNegStockWarning) {
      final insufficientItems = <String>[];
      for (var cartItem in cart.items) {
        final availStock = cartItem.item.currentStock ?? 0.0;
        if (cartItem.quantity > availStock) {
          insufficientItems.add('${cartItem.item.itemName ?? "Item"} (Available: ${availStock.toInt()}, Required: ${cartItem.quantity.toInt()})');
        }
      }

      if (insufficientItems.isNotEmpty) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Negative Stock Warning', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The following items exceed available stock inventory:'),
                const SizedBox(height: 10),
                ...insufficientItems.map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $msg', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                )),
                const SizedBox(height: 12),
                const Text('Do you want to proceed and save this sales order anyway?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel & Fix'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.email ?? 'salesman@sahaj.com';

      final repo = ref.read(orderRepositoryProvider);
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.filter().idGreaterThan(-1).findFirst();
      final companyGst = companySettings?.companyGST;

      final totals = ref.read(cartProvider.notifier).calculateTotals(companyGst);

      final order = _existingOrder ?? Order();
      if (_existingOrder == null) {
        order.orderNumber = await repo.generateNextOrderNumber();
        order.status = 'Pending';
        order.createdBy = _selectedSalesman;
      } else {
        order.editedBy = _selectedSalesman;
        order.editTime = DateTime.now();
      }

      order.orderDate = _orderDate;
      order.paymentMode = _paymentMode;
      order.discountType = _isDiscountPercent ? "percentage" : "flat";
      order.discountPercent = _isDiscountPercent ? (double.tryParse(_discountController.text) ?? 0.0) : 0.0;
      order.attachedImage = _attachedImage;
      order.isSynced = false;
      order.partyId = cart.selectedParty!.id;
      order.partyName = cart.selectedParty!.partyName;
      order.mobileNumber = cart.selectedParty!.mobileNumber;
      order.gstNumber = cart.selectedParty!.gstNumber;

      order.subtotal = totals['subtotal'];
      order.discountAmount = totals['discountAmount'];
      order.discountPercent = double.tryParse(_discountPercentController.text) ?? 0.0;
      order.totalGST = totals['totalGST'];
      order.roundOff = totals['roundOff'];
      order.grandTotal = totals['grandTotal'];
      order.remarks = _remarksController.text.trim();

      if (!kIsWeb) {
        order.party.value = cart.selectedParty;
      }

      final List<OrderItem> orderItems = cart.items.map((cartItem) {
        final orderItem = OrderItem()
          ..itemId = cartItem.item.id
          ..itemName = cartItem.item.itemName
          ..hsnCode = cartItem.item.hsnCode
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..unit = cartItem.unit ?? cartItem.item.primaryUnitName ?? cartItem.item.unit.value?.shortName ?? cartItem.item.unit.value?.unitName ?? 'PCS'
          ..rate = cartItem.rate
          ..discountAmount = cartItem.discountAmount
          ..discountPercent = cartItem.discountPercent
          ..taxableAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..gstPercent = cartItem.gstPercent
          ..gstAmount = cartItem.gstPercent * cartItem.rate * 0.01
          ..totalAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..batchNumber = cartItem.batchNumber
          ..expiryDate = cartItem.expiryDate
          ..mfgDate = cartItem.mfgDate;


        if (!kIsWeb) {
          orderItem.item.value = cartItem.item;
        }
        return orderItem;
      }).toList();

      await repo.saveOrder(order, orderItems);

      // Quiet background sync for newly saved order
      Future.microtask(() {
        try {
          ref.read(syncServiceProvider).syncPendingChangesQuietly();
        } catch (_) {}
      });

      ref.invalidate(filteredOrdersProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sales Order #${order.orderNumber} recorded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to save Sales Order', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: $e'),
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
    final cart = ref.watch(cartProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_isSaving) {
      return Scaffold(bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _saveOrder(isSaveAndNew: true),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Save & New'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveOrder(isSaveAndNew: false),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save & Close'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      body: Center(child: CircularProgressIndicator()));
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

    final summaryContent = NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
            left: BorderSide(color: Color(0xFF5E35B1), width: 5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Order Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Paid Amount with auto-fill checkbox
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: _isPaidAmountAutoFill,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _isPaidAmountAutoFill = val ?? false;
                        if (_isPaidAmountAutoFill) {
                          final totals = ref.read(cartProvider.notifier).calculateTotals(null);
                          final grandTotal = totals['grandTotal'] ?? 0.0;
                          _paidAmountController.text = grandTotal.toStringAsFixed(2);
                        } else {
                          _paidAmountController.clear();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Paid/Settled (₹)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() { _isPaidAmountAutoFill = false; });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final dropdownItems = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Credit', child: Text('Credit', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Cheque', child: Text('Cheque', style: TextStyle(fontSize: 13))),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? '', style: const TextStyle(fontSize: 13)),
                        )),
                      ];
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode, style: const TextStyle(fontSize: 13))));
                      }
                      return DropdownButtonFormField<String>(
                        value: _paymentMode.isNotEmpty ? _paymentMode : 'Cash',
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          prefixIcon: Icon(Icons.payment, size: 18),
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('Error'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1,
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
                      decoration: const InputDecoration(
                        labelText: 'Expected Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.event_outlined, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_dueDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _remarksController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Notes',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Discounts & Attachments', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _isDiscountPercent,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: true, child: Text('%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: false, child: Text('₹', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _isDiscountPercent = val;
                                  final double? amt = double.tryParse(_discountController.text);
                                  if (_isDiscountPercent) {
                                    ref.read(cartProvider.notifier).setOrderDiscounts(amt, null); // Reused method
                                  } else {
                                    ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      if (_isDiscountPercent) {
                        ref.read(cartProvider.notifier).setOrderDiscounts(amt, null);
                      } else {
                        ref.read(cartProvider.notifier).setOrderDiscounts(null, amt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                         _attachedImage = _attachedImage == null ? 'attached.jpg' : null;
                      });
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Attachment',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: const Icon(Icons.image_outlined, size: 18),
                        suffixIcon: _attachedImage != null 
                           ? IconButton(icon: const Icon(Icons.close, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), onPressed: () => setState(()=> _attachedImage = null)) 
                           : null,
                      ),
                      child: Text(_attachedImage != null ? 'Image Attached' : 'Add Image', style: TextStyle(fontSize: 13, color: _attachedImage != null ? Colors.green : Colors.grey)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 20),
            const SizedBox.shrink(), // old save button
          ],
        ),
      ),
      ),
    );

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: Text(widget.orderUuid != null ? 'Edit Sales Order' : 'Record Sales Order'),
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
          : Builder(
              builder: (context) {
          final cart = ref.watch(cartProvider);
          return FutureBuilder<Settings?>(
            future: ref.read(databaseServiceProvider).isar.settings.filter().idGreaterThan(-1).findFirst(),
            builder: (context, snapshot) {
              final totals = ref.read(cartProvider.notifier).calculateTotals(snapshot.data?.companyGST);
              final grandTotal = totals['grandTotal'] ?? 0.0;
              return Container(
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
                          'Grand Total (${cart.items.length} items)',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Save Sales Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _saveOrder,
                      style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPartyAndHeaderCard(ThemeData theme) {
    final partiesAsync = ref.watch(partiesListProvider);
    final cart = ref.watch(cartProvider);

    return NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
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
            partiesAsync.when(
              data: (parties) {
                final customerParties = parties.where((p) => p.partyType != 'Supplier').toList();
                return SearchablePartyDropdown(
                  parties: customerParties,
                  selectedParty: cart.selectedParty != null && customerParties.any((p) => p.uuid == cart.selectedParty!.uuid)
                      ? customerParties.firstWhere((p) => p.uuid == cart.selectedParty!.uuid)
                      : null,
                  labelText: 'Select Customer Account',
                  onChanged: (party) {
                    ref.read(cartProvider.notifier).setParty(party);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading customers: $e'),
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
                        'GST: ${cart.selectedParty!.gstNumber ?? "Unregistered"} | City: ${cart.selectedParty!.city ?? "N/A"} | Current Outstanding: ₹${cart.selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            ResponsiveFormRow(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _orderDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _orderDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'Order Date',  isDense: true),
                      child: Text(DateFormat('dd-MM-yyyy').format(_orderDate), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ResponsiveFormRow(children: [ Expanded(child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : _salesmenList.first,
                          decoration: InputDecoration(
                            labelText: 'Salesman Name',
                            
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'ADD_NEW_SALESMAN',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Select...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text('+ Add New', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            ..._salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSalesman = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.person_add_alt_1),
                        tooltip: 'Add Salesman',
                        onPressed: _showAddSalesmanDialog,
                      ),
                    ],
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

    return NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
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
                            return name.contains(query) || code.contains(query);
                          });
                        },
                        optionsMaxHeight: 300,
                        onSelected: (item) {
                          ref.read(cartProvider.notifier).addItem(item);
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
                                      title: Text(item.itemName ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            decoration: InputDecoration(
                              labelText: 'Type product name to add...',
                              prefixIcon: Icon(Icons.search),
                              
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
                  onPressed: () { FullScreenItemEntry.show(context, onAdd: (data) { _addFullScreenItemLine(data); ref.invalidate(filteredItemsProvider); }); },
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _addFullScreenItemLine(FullScreenItemEntryData data) {
    final item = data.item;

    final newItem = OrderItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = data.quantity
      ..unit = data.unit
      ..rate = data.rate
      ..discountAmount = data.discountAmount // some models use discountAmount, some use discount
      ..batchNumber = data.batchNumber
      ..mfgDate = data.mfgDate?.toIso8601String()
      ..expiryDate = data.expDate?.toIso8601String();
      
    newItem.item.value = item;

    final notifier = ref.read(cartProvider.notifier);
    notifier.addItem(newItem.item.value!);
    final cart = ref.read(cartProvider);
    
    // Different providers have slightly different updateItemAt arguments
    try {
      notifier.updateItemAt(
        cart.items.length - 1,
        quantity: data.quantity,
        rate: data.rate,
        discountAmount: data.discountAmount,
        discountPercent: data.discountPercent,
        unit: data.unit,
        batchNumber: data.batchNumber ?? '',
        mfgDate: data.mfgDate?.toIso8601String() ?? '',
        expiryDate: data.expDate?.toIso8601String() ?? '',
      );
    } catch(e) {
      // Fallback if some arguments like discountPercent are not supported
      notifier.updateItemAt(
        cart.items.length - 1,
        quantity: data.quantity,
        rate: data.rate,
        discountAmount: data.discountAmount,
        unit: data.unit,
        batchNumber: data.batchNumber ?? '',
        mfgDate: data.mfgDate?.toIso8601String() ?? '',
        expiryDate: data.expDate?.toIso8601String() ?? '',
      );
    }
    
    if (data.saleRate != (item.sellRate ?? 0.0) || data.purchaseRate != (item.buyRate ?? 0.0)) {
        item.sellRate = data.saleRate;
        item.buyRate = data.purchaseRate;
        item.updatedAt = DateTime.now();
        item.isSynced = false;
        try {
          ref.invalidate(itemsListProvider);
        } catch (_) {}
    }
  }

  Widget _buildCartItemsTable(ThemeData theme, OrderCart cart) {
    if (cart.items.isEmpty) {
      return NeuCard(
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

    return NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
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
                 return OrderCartItemRow(
                   index: index,
                   cartItem: cartItem,
                   isGstInclusive: cart.isGstInclusive,
                 );
               },
             ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () { FullScreenItemEntry.show(context, onAdd: (data) { _addFullScreenItemLine(data); ref.invalidate(filteredItemsProvider); }); },
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
    final cart = ref.watch(cartProvider);
    return FutureBuilder<Settings?>(
      future: ref.read(databaseServiceProvider).isar.settings.filter().idGreaterThan(-1).findFirst(),
      builder: (context, snapshot) {
        final companyGst = snapshot.data?.companyGST;
        final totals = ref.read(cartProvider.notifier).calculateTotals(companyGst);

        final cleanCompany = companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final cleanParty = cart.selectedParty?.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

        final totalGst = totals['totalGST'] ?? 0.0;
        final cgst = isLocal ? totalGst / 2.0 : 0.0;
        final sgst = isLocal ? totalGst / 2.0 : 0.0;
        final igst = isLocal ? 0.0 : totalGst;

        // Dynamic Tax Slab Calculation
        final gstRates = cart.items.map((i) => i.gstPercent).toSet().toList();
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
            _buildSummaryRow('Subtotal (Taxable Value)', totals['subtotal']!, theme),
            _buildSummaryRow('Discounts Total', -totals['discountAmount']!, theme),
            if (isLocal) ...[
              _buildSummaryRow(cgstLabel, cgst, theme),
              _buildSummaryRow(sgstLabel, sgst, theme),
            ] else ...[
              _buildSummaryRow(igstLabel, igst, theme),
            ],
            _buildSummaryRow('Round Off', totals['roundOff']!, theme),
            const Divider(),
            _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double val, ThemeData theme, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
              color: isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCartItemRow extends ConsumerWidget {
  final bool isFixedAsset;
  final int index;
  final CartItemState cartItem;
  final bool isGstInclusive;
  const OrderCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enableItemDesc = ref.watch(sharedPreferencesProvider).getBool('enable_item_wise_description') ?? false;
    
    DateTime? parseDate(String? d) {
      if (d == null || d.isEmpty) return null;
      try {
        final parts = d.split('/');
        if (parts.length == 2) {
          return DateTime(int.parse(parts[1]), int.parse(parts[0]));
        }
        return DateTime.parse(d);
      } catch (e) {
        return null;
      }
    }

    return NeuCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          FullScreenItemEntry.show(
            context,
            isPurchase: false,
            isFixedAsset: isFixedAsset,
            excludeBundles: !(cartItem.item.isBundle ?? false),
            onlyBundles: cartItem.item.isBundle ?? false,
            initialData: FullScreenItemEntryData(
              item: cartItem.item,
              quantity: cartItem.quantity,
              rate: cartItem.rate,
              discountAmount: cartItem.discountAmount,
              discountPercent: cartItem.discountPercent,
              gstRate: cartItem.gstPercent,
              unit: cartItem.unit ?? 'PCS',
              batchNumber: cartItem.batchNumber,
              mfgDate: parseDate(cartItem.mfgDate),
              expDate: parseDate(cartItem.expiryDate),
              saleRate: cartItem.item.sellRate ?? cartItem.rate,
              purchaseRate: cartItem.item.buyRate ?? 0.0,
              isSaleRateWithTax: false,
              isPurchaseRateWithTax: false,
            ),
            onAdd: (data) {
              ref.read(cartProvider.notifier).updateItemAt(
                index,
                quantity: data.quantity,
                unit: data.unit,
                rate: data.rate,
                
                discountPercent: data.discountPercent,
                discountAmount: data.discountAmount,
                batchNumber: data.batchNumber,
                mfgDate: data.mfgDate != null ? DateFormat('MM/yyyy').format(data.mfgDate!) : null,
                expiryDate: data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null,
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${index + 1}  ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Expanded(
                    child: Text(
                      cartItem.item.itemName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    '₹ ${cartItem.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: ${cartItem.quantity} ${cartItem.unit ?? 'PCS'} x Rate: ${cartItem.rate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Subtotal: ${(cartItem.quantity * cartItem.rate).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (cartItem.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Discount: -₹ ${cartItem.discountAmount.toStringAsFixed(2)}${cartItem.discountPercent > 0 ? ' (${cartItem.discountPercent.toStringAsFixed(2)}%)' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              if (cartItem.taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tax @ ${cartItem.gstPercent}%: +₹ ${cartItem.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              if (enableItemDesc && cartItem.description != null && cartItem.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Desc: ${cartItem.description}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                  ),
                ),
              Align(
             alignment: Alignment.bottomRight,
             child: InkWell(
               onTap: () => ref.read(cartProvider.notifier).removeItemAt(index),
               child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
             ),
           ),
        ],
          ),
        ),
      ),
    );
  }
}
