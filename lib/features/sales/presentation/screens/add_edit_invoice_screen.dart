import 'dart:io';
import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';
import 'package:business_sahaj_erp/features/sales/presentation/widgets/pos_product_grid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/machinery_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/unsaved_changes_provider.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/widgets/item_search_picker_modal.dart' show ItemSearchPickerModal, SelectedProductData;
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/widgets/variant_dropdown_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:business_sahaj_erp/core/widgets/full_screen_item_entry.dart';


class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  final String? invoiceUuid;
  final String? sourceOrderUuid;
  final bool isFixedAsset;
  const AddEditInvoiceScreen({Key? key, this.invoiceUuid, this.sourceOrderUuid, this.isFixedAsset = false}) : super(key: key);

  @override
  ConsumerState<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends ConsumerState<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final ScrollController _itemsScrollController = ScrollController();
  Order? _sourceOrder;

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
  List<String> _paymentModesList = ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'Credit'];

  List<String> _salesmenList = ['Default Salesman', 'Salesperson 1', 'Salesperson 2'];
  String _selectedSalesman = 'Default Salesman';

  String _voucherNumberDisplay = '';

  void _loadSalesmenAndModes() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final customS = prefs.getStringList('custom_salesmen_list') ?? [];
      final customP = prefs.getStringList('custom_payment_modes_list') ?? [];
      setState(() {
        _salesmenList = ['Default Salesman', 'Salesperson 1', 'Salesperson 2', ...customS].toSet().toList();
        _paymentModesList = ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'Credit', ...customP].toSet().toList();
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
              decoration: InputDecoration(
                labelText: 'Payment Mode Name (e.g. Finance, EMI)',
                
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

  bool _isPaidAmountAutoFill = false;

    bool _isDiscountPercent = true;
  String? _attachedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      if (mounted) {
        setState(() {
          _isPaidAmountAutoFill = prefs.getBool('auto_fill_paid_amount') ?? false;
        });
      }
      _loadSalesmenAndModes();
      ref.read(invoiceCartProvider.notifier).clear();
      if (widget.invoiceUuid != null) {
        await _loadInvoiceData();
      } else if (widget.sourceOrderUuid != null) {
        await _loadOrderDataForConversion();
      } else {
        try {
          final repo = ref.read(invoiceRepositoryProvider);
          final nextNo = await repo.generateNextInvoiceNumber(isFixedAsset: widget.isFixedAsset);
          if (mounted) {
            setState(() => _voucherNumberDisplay = nextNo);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _loadInvoiceData() async {
    try {
      final db = ref.read(databaseServiceProvider).isar;
      final invoice = await db.invoices.filter().uuidEqualTo(widget.invoiceUuid).findFirst();
      if (invoice != null) {
        _existingInvoice = invoice;
        _voucherNumberDisplay = invoice.invoiceNumber ?? '';
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
        if ((invoice.paidAmount ?? 0.0) > 0 && invoice.paidAmount == invoice.grandTotal) {
           _isPaidAmountAutoFill = true;
        }
        final double subVal = invoice.subtotal ?? 0.0;
        final double discAmtVal = invoice.discountAmount ?? 0.0;
        _discountController.text = discAmtVal.toString();
        final double discPctVal = subVal > 0 ? (discAmtVal / subVal * 100) : 0.0;
        _discountPercentController.text = discPctVal.toStringAsFixed(1);

        Party? party;
        if (invoice.partyId != null && invoice.partyId! > 0) {
          party = await db.partys.get(invoice.partyId!);
        }
        if (party == null && invoice.partyName != null && invoice.partyName!.isNotEmpty) {
          party = await db.partys.filter().partyNameEqualTo(invoice.partyName!).findFirst();
        }
        if (party == null) {
          try { await invoice.party.load(); } catch (_) {}
          try { party = invoice.party.value; } catch (_) {}
        }

        if (party != null) {
          List<InvoiceItem> itemsList = await db.invoiceItems
              .filter()
              .isDeletedEqualTo(false)
              .and()
              .group((q) => q.parentInvoiceIdEqualTo(invoice.id).or().parentInvoiceUuidEqualTo(invoice.uuid))
              .findAll();
          
          if (itemsList.isEmpty) {
            try { await invoice.invoiceItems.load(); } catch (_) {}
            try { itemsList = invoice.invoiceItems.where((i) => !i.isDeleted).toList(); } catch (_) {}
          }
          
          itemsList = itemsList.where((i) => i.uuid == null || !i.uuid!.endsWith("_BNDLCOMP")).toList();

          final List<CartItemState> cartItems = [];
          for (var item in itemsList) {
            Item? dbItem;
            if (item.itemId != null && item.itemId! > 0) {
              dbItem = await db.items.get(item.itemId!);
            }
            if (dbItem == null && item.itemName != null && item.itemName!.isNotEmpty) {
              dbItem = await db.items.filter().itemNameEqualTo(item.itemName!).findFirst();
            }
            if (dbItem == null) {
              try { await item.item.load(); } catch (_) {}
              try { dbItem = item.item.value; } catch (_) {}
            }
            if (dbItem != null) {
              final totalBase = (item.rate ?? 0.0) * (item.quantity ?? 1.0);
              final discPct = totalBase > 0 ? ((item.discount ?? 0.0) / totalBase) * 100.0 : 0.0;

              cartItems.add(
                CartItemState(
                  item: dbItem,
                  quantity: item.quantity ?? 1.0,
                  freeQuantity: item.freeQuantity ?? 0.0,
                  unit: (item.unit != null && item.unit!.isNotEmpty && item.unit != 'PCS') 
                      ? item.unit! 
                      : (dbItem.primaryUnitName ?? dbItem.unit.value?.shortName ?? item.unit ?? 'PCS'),
                  rate: item.rate ?? 0.0,
                  discountPercent: discPct,
                  discountAmount: item.discount ?? 0.0,
                  gstPercent: item.gstRate ?? 18.0,
                  batchNumber: item.batchNumber,
                  expiryDate: item.expiryDate,
                  mfgDate: item.mfgDate,
                  bundleComponentUuids: item.isBundle ? (item.bundleComponentUuids ?? dbItem.bundleComponentUuids) : null,
                  bundleComponentQuantities: item.isBundle ? (item.bundleComponentQuantities ?? dbItem.bundleComponentQuantities) : null,
                  bundleComponentUnits: item.isBundle ? (item.bundleComponentUnits ?? dbItem.bundleComponentUnits) : null,
                ),
              );
            }
          }

          ref.read(invoiceCartProvider.notifier).loadInvoice(
            party: party,
            invoice: invoice,
            items: cartItems,
            isGstInclusive: false,
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

  Future<void> _loadOrderDataForConversion() async {
    try {
      final db = ref.read(databaseServiceProvider).isar;
      final order = await db.orders.filter().uuidEqualTo(widget.sourceOrderUuid).findFirst();
      if (order != null) {
        _sourceOrder = order;
        final nextNo = await ref.read(invoiceRepositoryProvider).generateNextInvoiceNumber(isFixedAsset: widget.isFixedAsset);
        _voucherNumberDisplay = nextNo;
        _remarksController.text = 'Converted from Sales Order #${order.orderNumber}';

        if (order.createdBy != null && order.createdBy!.isNotEmpty) {
          _selectedSalesman = order.createdBy!;
          if (!_salesmenList.contains(_selectedSalesman)) {
            _salesmenList.add(_selectedSalesman);
          }
        }

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

          final List<CartItemState> cartItems = [];
          for (var item in orderItemsList) {
            Item? dbItem;
            if (item.itemId != null && item.itemId! > 0) {
              dbItem = await db.items.get(item.itemId!);
            }
            if (dbItem == null && item.itemName != null && item.itemName!.isNotEmpty) {
              dbItem = await db.items.filter().itemNameEqualTo(item.itemName!).findFirst();
            }
            if (dbItem == null) {
              try { await item.item.load(); } catch (_) {}
              try { dbItem = item.item.value; } catch (_) {}
            }

            if (dbItem != null) {
              final totalBase = (item.rate ?? 0.0) * (item.quantity ?? 1.0);
              final discPct = totalBase > 0 ? ((item.discountAmount ?? 0.0) / totalBase) * 100.0 : 0.0;

              cartItems.add(
                CartItemState(
                  item: dbItem,
                  quantity: item.quantity ?? 1.0,
                  freeQuantity: item.freeQuantity ?? 0.0,
                  unit: (item.unit != null && item.unit!.isNotEmpty && item.unit != 'PCS')
                      ? item.unit!
                      : (dbItem.primaryUnitName ?? dbItem.unit.value?.shortName ?? item.unit ?? 'PCS'),
                  rate: item.rate ?? 0.0,
                  discountPercent: discPct,
                  discountAmount: item.discountAmount ?? 0.0,
                  gstPercent: item.gstPercent ?? dbItem.gstRate ?? 18.0,
                  batchNumber: item.batchNumber,
                  expiryDate: item.expiryDate,
                  mfgDate: item.mfgDate,
                ),
              );
            }
          }

          final cartNotifier = ref.read(invoiceCartProvider.notifier);
          cartNotifier.setParty(party);
          cartNotifier.state = cartNotifier.state.copyWith(
            items: cartItems,
            isGstInclusive: false,
            remarks: _remarksController.text,
          );
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales order: $e')),
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

  Future<void> _saveInvoice({bool isSaveAndNew = false}) async {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Text('- $msg', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                )),
                const SizedBox(height: 12),
                const Text('Do you want to proceed and save this transaction anyway?'),
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

      final repo = ref.read(invoiceRepositoryProvider);
      final companySettings = await ref.read(databaseServiceProvider).isar.settings.filter().idGreaterThan(-1).findFirst();
      final companyGst = companySettings?.companyGST;

      final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(companyGst);
      final nextInvNum = await repo.generateNextInvoiceNumber(isFixedAsset: widget.isFixedAsset);

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
        ..createdBy = _selectedSalesman
        ..linkedMachineUuid = cart.linkedMachineUuid
        ..isServiceSameAsCurrent = cart.isServiceSameAsCurrent
        ..updatedAt = DateTime.now()
      ..paymentMode = _paymentMode
      ..discountType = _isDiscountPercent ? 'percentage' : 'flat'
      ..discountPercent = _isDiscountPercent ? (double.tryParse(_discountController.text) ?? 0.0) : 0.0
      ..attachedImage = _attachedImage
      ..isSynced = false
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
          ..unit = cartItem.unit ?? cartItem.item.primaryUnitName ?? (!kIsWeb ? cartItem.item.unit.value?.shortName : '') ?? (!kIsWeb ? cartItem.item.unit.value?.unitName : '') ?? 'PCS'
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..rate = cartItem.rate
          ..buyRate = cartItem.buyRate
          ..discount = cartItem.discountAmount
          ..taxableAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..gstRate = cartItem.gstPercent
          ..gstAmount = cartItem.gstPercent * cartItem.rate * 0.01
          ..totalAmount = cartItem.quantity * cartItem.rate - cartItem.discountAmount
          ..batchNumber = cartItem.batchNumber
          ..expiryDate = cartItem.expiryDate
          ..mfgDate = cartItem.mfgDate
          ..isBundle = cartItem.item.isBundle
          ..bundleComponentUuids = cartItem.bundleComponentUuids
          ..bundleComponentQuantities = cartItem.bundleComponentQuantities
          ..bundleComponentUnits = cartItem.bundleComponentUnits;


        if (!kIsWeb) {
          invItem.item.value = cartItem.item;
        }
        return invItem;
      }).toList();

      if (_sourceOrder != null) {
        invoice
          ..sourceOrderId = _sourceOrder!.id
          ..sourceOrderNumber = _sourceOrder!.orderNumber;
      }

      await Future.delayed(const Duration(milliseconds: 100)); // Yield event loop to let loader render
      
      // Safety timeout to prevent infinite UI freeze if Isar transaction deadlocks
      await repo.saveInvoice(invoice, invoiceItems).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Database operation timed out. Please try again.'),
      );

      if (_sourceOrder != null) {
        final isar = ref.read(databaseServiceProvider).isar;
        _sourceOrder!.status = 'Converted To Sale';
        _sourceOrder!.updatedAt = DateTime.now();
        _sourceOrder!.version += 1;
        _sourceOrder!.isSynced = false;

        await isar.writeTxn(() async {
          await isar.orders.put(_sourceOrder!);
          final q = SyncQueue()
            ..uuid = Uuid().v4()
            ..entityType = 'Order'
            ..entityId = _sourceOrder!.id
            ..entityUuid = _sourceOrder!.uuid
            ..operation = 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(q);
        });
        ref.invalidate(filteredOrdersProvider);
      }

      if (cart.linkedMachineUuid != null && cart.isServiceSameAsCurrent != true) {
        final isar = ref.read(databaseServiceProvider).isar;
        final machinery = await isar.collection<Machinery>().filter().uuidEqualTo(cart.linkedMachineUuid).findFirst();
        if (machinery != null) {
          machinery.lastServiceDate = _invoiceDate;
          if ((machinery.serviceIntervalMonths ?? 0) > 0 || (machinery.serviceIntervalDays ?? 0) > 0) {
             machinery.nextServiceDate = DateTime(
               _invoiceDate.year, 
               _invoiceDate.month + (machinery.serviceIntervalMonths ?? 0), 
               _invoiceDate.day + (machinery.serviceIntervalDays ?? 0)
             );
          }
          await ref.read(machineryProvider).saveMachinery(machinery);
        }
      }

      ref.invalidate(filteredInvoicesProvider);
      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(dashboardAnalyticsProvider);
      ref.read(unsavedChangesProvider.notifier).state = false;

      // Lightweight non-blocking quiet background sync
      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      if (mounted) {
        
        if (isSaveAndNew) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AddEditInvoiceScreen()),
          );
        } else {
          Navigator.pop(context, true);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sourceOrder != null
                ? 'Sales Order #${_sourceOrder!.orderNumber} converted to Invoice #${invoice.invoiceNumber}!'
                : 'Direct Invoice #${invoice.invoiceNumber} recorded!'),
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
ref.listen(invoiceCartProvider, (prev, next) {
      if (_isPaidAmountAutoFill) {
        final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(null);
        final grandTotal = totals['grandTotal'] ?? 0.0;
        final currentPaid = double.tryParse(_paidAmountController.text) ?? 0.0;
        if ((currentPaid - grandTotal).abs() > 0.01) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _paidAmountController.text = grandTotal.toStringAsFixed(2);
              ref.read(invoiceCartProvider.notifier).setPaidAmount(grandTotal);
            }
          });
        }
      }
    });

    final theme = Theme.of(context);
    final cart = ref.watch(invoiceCartProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_isSaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prefs = ref.watch(sharedPreferencesProvider);
    final isRestaurantMode = prefs.getBool('enable_restaurant_mode') ?? false;

    final mainContent = isRestaurantMode
        ? const POSProductGrid()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPartyAndHeaderCard(theme),
              const SizedBox(height: 10),
              _buildCartItemsTable(theme, cart),
            ],
          );

    final summaryContent = NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
            left: BorderSide(color: Color(0xFF5E35B1), width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // -- Section A: Invoice Details --
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Invoice Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                          final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(null);
                          final grandTotal = totals['grandTotal'] ?? 0.0;
                          _paidAmountController.text = grandTotal.toStringAsFixed(2);
                          ref.read(invoiceCartProvider.notifier).setPaidAmount(grandTotal);
                        } else {
                          _paidAmountController.clear();
                          ref.read(invoiceCartProvider.notifier).setPaidAmount(0.0);
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
                      labelText: 'Paid (₹)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _isPaidAmountAutoFill = false;
                      });
                      final double? amt = double.tryParse(val);
                      if (amt != null) {
                        ref.read(invoiceCartProvider.notifier).setPaidAmount(amt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Payment Mode Dropdown
                Expanded(
                  flex: 2,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      // Only Cash, Credit, Cheque and active bank accounts
                      final dropdownItems = <DropdownMenuItem<String>>[
                        const DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Credit', child: Text('Credit', style: TextStyle(fontSize: 13))),
                        const DropdownMenuItem(value: 'Cheque', child: Text('Cheque', style: TextStyle(fontSize: 13))),
                        ...activeAccounts.map((acc) => DropdownMenuItem(
                          value: acc.accountName,
                          child: Text(acc.accountName ?? '', style: const TextStyle(fontSize: 13)),
                        )),
                      ];
                      
                      // Ensure selected value is valid
                      if (_paymentMode.isNotEmpty && !dropdownItems.any((item) => item.value == _paymentMode)) {
                        dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode, style: const TextStyle(fontSize: 13))));
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: _paymentMode.isNotEmpty ? _paymentMode : 'Cash',
                        decoration: InputDecoration(
                          labelText: 'Payment Mode',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          prefixIcon: const Icon(Icons.payment, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _showAddPaymentModeDialog,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ADD_NEW_PAYMENT',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Select...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                Text('+ Add New', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          ...dropdownItems,
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  )
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _invoiceType,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Billing Type',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
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
                ),
                const SizedBox(width: 8),
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
                        labelText: 'Due Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.event_outlined, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_dueDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),

            // -- Section B: Payment & Discounts --
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
                                  // trigger re-calc
                                  final double? amt = double.tryParse(_discountController.text);
                                  if (_isDiscountPercent) {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(amt, null);
                                  } else {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
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
                        ref.read(invoiceCartProvider.notifier).setDiscounts(amt, null);
                      } else {
                        ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _remarksController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Remarks / Terms',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
              ),
            ),

            // -- Section C: Bill Summary --
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            Row(
              children: [
                Icon(Icons.receipt_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bill Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 12),
            const SizedBox.shrink(), // old save button
          ],
        ),
      ),
      ),
    );


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (cart.items.isEmpty) {
          Navigator.of(context).pop();
          return;
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Unsaved Changes Warning'),
            content: const Text('You have unsaved items in this invoice. Are you sure you want to exit and discard changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Continue Editing'),
              ),
              ElevatedButton(
                style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard & Exit'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
          title: Text(
            widget.invoiceUuid != null
                ? 'Edit Sales Invoice ${_voucherNumberDisplay.isNotEmpty ? "(#${_voucherNumberDisplay})" : ""}'
                : 'Direct Tax Invoice ${_voucherNumberDisplay.isNotEmpty ? "(#${_voucherNumberDisplay})" : ""}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 10.0, vertical: 8.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3, 
                    child: isRestaurantMode 
                        ? SizedBox(height: MediaQuery.of(context).size.height - 180, child: mainContent)
                        : mainContent,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2, 
                    child: isRestaurantMode 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPartyAndHeaderCard(theme),
                              const SizedBox(height: 12),
                              _buildCartItemsTable(theme, cart),
                              const SizedBox(height: 12),
                              summaryContent,
                            ],
                          )
                        : summaryContent,
                  ),
                ],
              )
            : Column(
                children: [
                  if (isRestaurantMode) ...[
                    _buildPartyAndHeaderCard(theme),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 500, // Fixed height for POS grid on mobile
                      child: mainContent,
                    ),
                    const SizedBox(height: 12),
                    _buildCartItemsTable(theme, cart),
                    const SizedBox(height: 12),
                    summaryContent,
                  ] else ...[
                    mainContent,
                    const SizedBox(height: 10),
                    summaryContent,
                  ],
                  const SizedBox(height: 80),
                ],
              ),
        ),
        bottomNavigationBar: SafeArea(
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
                    onPressed: _isSaving ? null : () => _saveInvoice(isSaveAndNew: true),
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
                    onPressed: _isSaving ? null : () => _saveInvoice(isSaveAndNew: false),
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
      ),
    );
  }

  void _addFullScreenItemLine(FullScreenItemEntryData data) {
    final item = data.item;

    final newItem = InvoiceItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = data.quantity
      ..unit = data.unit
      ..rate = data.rate
      ..discount = data.discountAmount // some models use discountAmount, some use discount
      ..batchNumber = data.batchNumber
      ..mfgDate = data.mfgDate?.toIso8601String()
      ..expiryDate = data.expDate?.toIso8601String();
      
    newItem.item.value = item;

    final notifier = ref.read(invoiceCartProvider.notifier);
    notifier.addItem(newItem.item.value!);
    final cart = ref.read(invoiceCartProvider);
    
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

  Future<void> _handleItemAdded(SelectedProductData data) async {
    ref.read(invoiceCartProvider.notifier).addItem(
      data.item, 
      selectedSubItemUuid: data.selectedSubItem?.uuid, 
      selectedSubItemName: data.selectedSubItem?.name,
    );
    ref.invalidate(filteredItemsProvider);
  }

  Widget _buildPartyAndHeaderCard(ThemeData theme) {
    final partiesAsync = ref.watch(partiesListProvider);
    final cart = ref.watch(invoiceCartProvider);

    return NeuCard(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
            left: BorderSide(color: Color(0xFF1E88E5), width: 5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Billing Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            partiesAsync.when(
                data: (parties) {
                  final listWithCash = parties.any((p) => p.partyName?.toLowerCase() == 'cash') 
                      ? parties 
                      : [Party()..partyName = 'Cash'..id = -1, ...parties];
                      
                  return SearchablePartyDropdown(
                    parties: listWithCash,
                    selectedParty: cart.selectedParty != null && listWithCash.any((p) => (p.uuid != null && p.uuid == cart.selectedParty!.uuid) || p.id == cart.selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == cart.selectedParty!.partyName?.trim().toLowerCase()))
                        ? listWithCash.firstWhere((p) => (p.uuid != null && p.uuid == cart.selectedParty!.uuid) || p.id == cart.selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == cart.selectedParty!.partyName?.trim().toLowerCase()))
                        : cart.selectedParty,
                    labelText: 'Select Billing Party / Customer Account',
                    onChanged: (party) {
                      ref.read(invoiceCartProvider.notifier).setParty(party);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading customers: $e'),
              ),
            if (cart.selectedParty != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, size: 15, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('GST: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        Expanded(child: Text(cart.selectedParty!.gstNumber ?? 'Unregistered', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('Addr: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        Expanded(child: Text(cart.selectedParty!.city ?? 'N/A', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 15, color: (cart.selectedParty!.outstandingBalance ?? 0) > 0 ? Colors.red : Colors.green),
                        const SizedBox(width: 6),
                        Text('Outstanding: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        Text(
                          '?${cart.selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: (cart.selectedParty!.outstandingBalance ?? 0) > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (ref.read(sharedPreferencesProvider).getBool('enable_machinery_management') ?? false) ...[
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final machineriesAsync = ref.watch(machineryListProvider);
                    return machineriesAsync.when(
                      data: (machineries) {
                        final partyMachineries = machineries.where((m) => m.partyUuid == cart.selectedParty!.uuid).toList();
                        if (partyMachineries.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: partyMachineries.any((m) => m.uuid == cart.linkedMachineUuid) ? cart.linkedMachineUuid : null,
                              decoration: InputDecoration(
                                labelText: 'Link Machinery / Service',
                                
                                prefixIcon: Icon(Icons.precision_manufacturing_rounded),
                              ),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('No Machine Linked')),
                                ...partyMachineries.map((m) => DropdownMenuItem(
                                  value: m.uuid, 
                                  child: Text('${m.machineName} (${m.modelNumber ?? 'No model'})'),
                                )),
                              ],
                              onChanged: (val) {
                                ref.read(invoiceCartProvider.notifier).setLinkedMachine(val, sameAsCurrent: false);
                              },
                            ),
                            if (cart.linkedMachineUuid != null) ...[
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                title: const Text('Early inspection / Same service?', style: TextStyle(fontSize: 12)),
                                subtitle: const Text('Won\'t reschedule next service date', style: TextStyle(fontSize: 10)),
                                dense: true,
                                value: cart.isServiceSameAsCurrent ?? false,
                                onChanged: (val) {
                                  ref.read(invoiceCartProvider.notifier).setLinkedMachine(cart.linkedMachineUuid, sameAsCurrent: val);
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ]
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ],
            const Divider(height: 20),
                        // Invoice Date & Salesman
            Row(
              children: [
                Expanded(
                  flex: 1,
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
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_invoiceDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : null,
                                  hint: const Text('Select Salesman', style: TextStyle(fontSize: 13)),
                                  icon: const SizedBox.shrink(),
                                  decoration: InputDecoration(
                                    labelText: 'Salesman Name',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedSalesman.isNotEmpty && _selectedSalesman != 'Default Salesman')
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() => _selectedSalesman = ''),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.person_add, size: 18),
                                          onPressed: _showAddSalesmanDialog,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
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
      return NeuCard(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No product lines added yet.', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        FullScreenItemEntry.show(context, excludeBundles: true, isFixedAsset: widget.isFixedAsset, onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        await _handleItemAdded(tempSelected);
        // Post-update qty and discount
        ref.read(invoiceCartProvider.notifier).updateItem(
          data.item.uuid ?? '',
          quantity: data.quantity,
          discountAmount: data.discountAmount,
        );
        
      },
    );
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Add Item'),
                      style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (ref.read(sharedPreferencesProvider).getBool('enable_bundle_management') ?? false) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FullScreenItemEntry.show(context, onlyBundles: true, isFixedAsset: widget.isFixedAsset, onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        await _handleItemAdded(tempSelected);
        // Post-update qty and discount
        ref.read(invoiceCartProvider.notifier).updateItem(
          data.item.uuid ?? '',
          quantity: data.quantity,
          discountAmount: data.discountAmount,
        );
        
      },
    );
                        },
                        icon: const Icon(Icons.extension_rounded, size: 18),
                        label: const Text('Add Bundle'),
                        style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
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
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
            left: BorderSide(color: Color(0xFFFB8C00), width: 5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cart Items', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             ListView.separated(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: cart.items.length,
               separatorBuilder: (context, index) => const Divider(height: 16),
               itemBuilder: (context, index) {
                 final cartItem = cart.items[index];
                 return InvoiceCartItemRow(
                   index: index,
                   cartItem: cartItem,
                   isGstInclusive: cart.isGstInclusive,
                   isFixedAsset: widget.isFixedAsset,
                 );
               },
             ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      FullScreenItemEntry.show(context, excludeBundles: true, isFixedAsset: widget.isFixedAsset, onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        await _handleItemAdded(tempSelected);
        // Post-update qty and discount
        ref.read(invoiceCartProvider.notifier).updateItem(
          data.item.uuid ?? '',
          quantity: data.quantity,
          discountAmount: data.discountAmount,
        );
        
      },
    );
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                if (ref.read(sharedPreferencesProvider).getBool('enable_bundle_management') ?? false) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        FullScreenItemEntry.show(context, onlyBundles: true, isFixedAsset: widget.isFixedAsset, onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        await _handleItemAdded(tempSelected);
        // Post-update qty and discount
        ref.read(invoiceCartProvider.notifier).updateItem(
          data.item.uuid ?? '',
          quantity: data.quantity,
          discountAmount: data.discountAmount,
        );
        
      },
    );
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: Colors.orange.shade700),
                        foregroundColor: Colors.orange.shade900,
                      ),
                      icon: const Icon(Icons.extension_rounded, size: 18),
                      label: const Text('Add Bundle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ],
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
      future: ref.read(databaseServiceProvider).isar.settings.filter().idGreaterThan(-1).findFirst(),
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

        // Margin Calculation
        final prefs = ref.watch(sharedPreferencesProvider);
        final enableBuyPrice = prefs.getBool('enable_sales_buy_price') ?? false;
        double totalBuyCost = 0.0;
        if (enableBuyPrice) {
          for (var item in cart.items) {
            totalBuyCost += (item.buyRate ?? 0.0) * item.quantity;
          }
        }
        final double grossMargin = (totals['subtotal'] ?? 0.0) - totalBuyCost;

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Round Off', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                      if (cart.customRoundOff != null)
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.blue),
                          tooltip: 'Reset to Auto Round Off',
                          onPressed: () {
                            ref.read(invoiceCartProvider.notifier).setCustomRoundOff(null);
                          },
                        ),
                    ],
                  ),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: totals['roundOff']!.toStringAsFixed(2),
                      key: ValueKey('roundoff_${cart.customRoundOff}_${totals['roundOff']}'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          ref.read(invoiceCartProvider.notifier).setCustomRoundOff(parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            _buildSummaryRow('GRAND TOTAL', totals['grandTotal']!, theme, isBold: true),
            _buildSummaryRow('Pending Outstanding', totals['pendingAmount']!, theme, isPending: true),
            
            if (enableBuyPrice) ...[
              const Divider(),
              _buildSummaryRow('Est. Gross Margin', grossMargin, theme, isBold: true),
            ],
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
            '?${val.toStringAsFixed(2)}',
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

class InvoiceCartItemRow extends ConsumerWidget {
  final bool isFixedAsset;
  final int index;
  final CartItemState cartItem;
  final bool isGstInclusive;
  const InvoiceCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false}) : super(key: key);

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
              ref.read(invoiceCartProvider.notifier).updateItemAt(
                index,
                quantity: data.quantity,
                unit: data.unit,
                rate: data.rate,
                buyRate: data.purchaseRate,
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
               onTap: () => ref.read(invoiceCartProvider.notifier).removeItemAt(index),
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
