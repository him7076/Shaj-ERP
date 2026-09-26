import 'dart:io';
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


class AddEditInvoiceScreen extends ConsumerStatefulWidget {
  final String? invoiceUuid;
  final String? sourceOrderUuid;
  const AddEditInvoiceScreen({Key? key, this.invoiceUuid, this.sourceOrderUuid}) : super(key: key);

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
              decoration: const InputDecoration(
                labelText: 'Salesman Name',
                border: OutlineInputBorder(),
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

  bool _isPaidAmountAutoFill = false;

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
          final nextNo = await repo.generateNextInvoiceNumber();
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
        final nextNo = await ref.read(invoiceRepositoryProvider).generateNextInvoiceNumber();
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
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
        ..createdBy = _selectedSalesman
        ..linkedMachineUuid = cart.linkedMachineUuid
        ..isServiceSameAsCurrent = cart.isServiceSameAsCurrent
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
        Navigator.pop(context, true);
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
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? null : const Border(
            left: BorderSide(color: Color(0xFF5E35B1), width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // ── Section A: Invoice Details ──
            Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Invoice Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _invoiceType,
              decoration: const InputDecoration(labelText: 'Billing Type', border: OutlineInputBorder(), isDense: true),
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


            // ── Section B: Payment & Discounts ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Payment & Discounts', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            // Paid Amount with auto-fill checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount (\u20b9)',
                      border: OutlineInputBorder(),
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
              ],
            ),
            const SizedBox(height: 10),
            // Due Date
            InkWell(
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
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.event_outlined, size: 18),
                ),
                child: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
              ),
            ),
            const SizedBox(height: 10),
            // Payment Mode — always visible
            ref.watch(bankAccountsListProvider).when(
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
                          labelText: 'Payment Mode',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.payment, size: 18),
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paymentMode = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      tooltip: 'Add Payment Type',
                      onPressed: _showAddPaymentModeDialog,
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.payment, size: 18),
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
            const SizedBox(height: 10),
            // Discount Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Disc %', border: OutlineInputBorder(), isDense: true),
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
                    decoration: const InputDecoration(labelText: 'Disc \u20b9', border: OutlineInputBorder(), isDense: true),
                    onChanged: (val) {
                      final double? amt = double.tryParse(val);
                      ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks / Terms',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
              ),
            ),

            // ── Section C: Bill Summary ──
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save & Print Invoice'),
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Unsaved Changes Warning'),
            content: const Text('You have unsaved items in this invoice. Are you sure you want to exit and discard changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Continue Editing'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                ? 'Edit Sales Invoice ${_voucherNumberDisplay.isNotEmpty ? "(#$_voucherNumberDisplay)" : ""}'
                : 'Direct Tax Invoice ${_voucherNumberDisplay.isNotEmpty ? "(#$_voucherNumberDisplay)" : ""}',
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
                              const SizedBox(height: 16),
                              _buildCartItemsTable(theme, cart),
                              const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 500, // Fixed height for POS grid on mobile
                      child: mainContent,
                    ),
                    const SizedBox(height: 16),
                    _buildCartItemsTable(theme, cart),
                    const SizedBox(height: 16),
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
        bottomNavigationBar: null,
      ),
    );
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
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
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
                          '₹${cart.selectedParty!.outstandingBalance?.toStringAsFixed(2) ?? "0.00"}',
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
                              decoration: const InputDecoration(
                                labelText: 'Link Machinery / Service',
                                border: OutlineInputBorder(),
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
            Row(
              children: [
                // Invoice Date
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
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Salesman
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<String>(
                        textEditingController: TextEditingController(text: _selectedSalesman),
                        focusNode: FocusNode(),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) return _salesmenList;
                          return _salesmenList.where((s) => s.toLowerCase().contains(query)).toList();
                        },
                        onSelected: (String s) {
                          setState(() {
                            _selectedSalesman = s;
                          });
                          FocusScope.of(context).unfocus();
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      color: Colors.blue.withOpacity(0.1),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.add, color: Colors.blue, size: 20),
                                        title: const Text('+ Add New Salesman', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          _showAddSalesmanDialog();
                                        },
                                      ),
                                    ),
                                    Flexible(
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            dense: true,
                                            title: Text(option, style: const TextStyle(fontSize: 13)),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Salesman',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              prefixIcon: Icon(Icons.badge_outlined, size: 18),
                            ),
                          );
                        },
                      );
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
          borderRadius: BorderRadius.circular(16),
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
                        final selectedItem = await ItemSearchPickerModal.show(context, excludeBundles: true);
                        if (selectedItem != null) {
                          await _handleItemAdded(selectedItem);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (ref.read(sharedPreferencesProvider).getBool('enable_bundle_management') ?? false) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final selectedItem = await ItemSearchPickerModal.show(context, onlyBundles: true);
                          if (selectedItem != null) {
                            await _handleItemAdded(selectedItem);
                          }
                        },
                        icon: const Icon(Icons.extension_rounded, size: 18),
                        label: const Text('Add Bundle'),
                        style: ElevatedButton.styleFrom(
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
        borderRadius: BorderRadius.circular(16),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        decoration: const BoxDecoration(
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
                 );
               },
             ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selectedItem = await ItemSearchPickerModal.show(context, excludeBundles: true);
                      if (selectedItem != null) {
                        await _handleItemAdded(selectedItem);
                      }
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
                        final selectedItem = await ItemSearchPickerModal.show(context, onlyBundles: true);
                        if (selectedItem != null) {
                          await _handleItemAdded(selectedItem);
                        }
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
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(),
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
  final int index;
  final CartItemState cartItem;
  final bool isGstInclusive;
  const InvoiceCartItemRow({Key? key, required this.index, required this.cartItem, required this.isGstInclusive}) : super(key: key);

  @override
  ConsumerState<InvoiceCartItemRow> createState() => _InvoiceCartItemRowState();
}

class _InvoiceCartItemRowState extends ConsumerState<InvoiceCartItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _freeQtyController;
  late TextEditingController _rateExclController;
  late TextEditingController _rateInclController;
  late TextEditingController _buyRateController;
  late TextEditingController _discPercentController;
  late TextEditingController _discAmountController;
  late TextEditingController _batchController;
  late TextEditingController _mfgDateController;
  late TextEditingController _expDateController;
  late TextEditingController _descController;

  bool _isUpdatingLocally = false;
  bool _showMoreDetails = false;

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
    _buyRateController = TextEditingController(text: (item.buyRate ?? 0.0).toStringAsFixed(2));
    _discPercentController = TextEditingController(text: item.discountPercent.toString());
    _discAmountController = TextEditingController(text: item.discountAmount.toString());
    _batchController = TextEditingController(text: item.batchNumber ?? '');
    _mfgDateController = TextEditingController(text: item.mfgDate ?? '');
    _expDateController = TextEditingController(text: item.expiryDate ?? '');
    _descController = TextEditingController(text: item.description ?? '');
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
    _updateIfChanged(_buyRateController, (item.buyRate ?? 0.0).toStringAsFixed(2));
    _updateIfChanged(_discPercentController, item.discountPercent.toString());
    _updateIfChanged(_discAmountController, item.discountAmount.toString());
    
    if (_descController.text != (item.description ?? '')) {
      _descController.text = item.description ?? '';
    }
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
    _buyRateController.dispose();
    _discPercentController.dispose();
    _discAmountController.dispose();
    _batchController.dispose();
    _mfgDateController.dispose();
    _expDateController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _showBundleComponentsDialog() async {
    final item = widget.cartItem;
    
    // Create local copies of components to edit
    List<String> uuids = item.bundleComponentUuids != null ? List.from(item.bundleComponentUuids!) : [];
    List<double> quantities = List.from(item.bundleComponentQuantities ?? []);
    List<String> units = List.from(item.bundleComponentUnits ?? []);
    List<double> rates = List.from(item.bundleComponentRates ?? []);
    List<double> buyRates = List.from(item.bundleComponentBuyRates ?? []);
    List<double> gstRates = List.from(item.bundleComponentGstPercents ?? []);
    List<String> descriptions = List.from(item.bundleComponentDescriptions ?? []);
    
    // Ensure lists match length
    while (quantities.length < uuids.length) quantities.add(1.0);
    while (units.length < uuids.length) units.add('PCS');
    while (rates.length < uuids.length) rates.add(0.0);
    while (buyRates.length < uuids.length) buyRates.add(0.0);
    while (gstRates.length < uuids.length) gstRates.add(0.0);
    while (descriptions.length < uuids.length) descriptions.add('');

    final itemRepo = ref.read(itemRepositoryProvider);
    final allItems = await itemRepo.getAll();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(ctx).size.height,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bundle Components: ${item.item.itemName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: uuids.length,
                        itemBuilder: (context, index) {
                          final cUuid = uuids[index];
                          final cItem = allItems.where((i) => i.uuid == cUuid).firstOrNull;
                          if (cItem == null) return const SizedBox.shrink();
                          
                          return NeuCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cItem.itemName ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setSheetState(() {
                                            uuids.removeAt(index);
                                            quantities.removeAt(index);
                                            units.removeAt(index);
                                            rates.removeAt(index);
                                            buyRates.removeAt(index);
                                            gstRates.removeAt(index);
                                            descriptions.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: quantities[index].toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val);
                                            if (parsed != null) quantities[index] = parsed;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: units[index],
                                          isExpanded: true,
                                          decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), isDense: true),
                                          items: [
                                            if (cItem.primaryUnitName != null && cItem.primaryUnitName!.isNotEmpty) cItem.primaryUnitName!,
                                            if (cItem.secondaryUnit != null && cItem.secondaryUnit!.isNotEmpty) cItem.secondaryUnit!,
                                            if (cItem.tertiaryUnit != null && cItem.tertiaryUnit!.isNotEmpty) cItem.tertiaryUnit!,
                                            if (cItem.primaryUnitName == null || cItem.primaryUnitName!.isEmpty) 'PCS',
                                          ].toSet().map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              units[index] = val;
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
                                          initialValue: rates[index].toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Selling Rate', border: OutlineInputBorder(), isDense: true),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val);
                                            if (parsed != null) rates[index] = parsed;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: gstRates[index].toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder(), isDense: true),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val);
                                            if (parsed != null) gstRates[index] = parsed;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (ref.watch(sharedPreferencesProvider).getBool('enable_sales_buy_price') ?? false)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: TextFormField(
                                        initialValue: buyRates[index].toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Buy Price', border: OutlineInputBorder(), isDense: true),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val);
                                          if (parsed != null) buyRates[index] = parsed;
                                        },
                                      ),
                                    ),
                                  if (ref.watch(sharedPreferencesProvider).getBool('enable_item_descriptions') ?? false)
                                    TextFormField(
                                      initialValue: descriptions[index],
                                      maxLines: 2,
                                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true),
                                      onChanged: (val) {
                                        descriptions[index] = val;
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Component to this Bundle'),
                      onPressed: () async {
                        final selected = await ItemSearchPickerModal.show(ctx, excludeBundles: true);
                        if (selected != null && selected.item.uuid != null) {
                          if (!uuids.contains(selected.item.uuid)) {
                            setSheetState(() {
                              uuids.add(selected.item.uuid!);
                              quantities.add(1.0);
                              units.add(selected.item.primaryUnitName ?? 'PCS');
                              rates.add(selected.item.sellRate ?? 0.0);
                              buyRates.add(selected.item.buyRate ?? 0.0);
                              gstRates.add(selected.item.gstRate ?? 18.0);
                              descriptions.add(selected.item.description ?? '');
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      child: const Text('Save Components'),
                      onPressed: () {
                        ref.read(invoiceCartProvider.notifier).updateItemAt(
                          widget.index,
                          bundleComponentUuids: uuids,
                          bundleComponentQuantities: quantities,
                          bundleComponentUnits: units,
                          bundleComponentRates: rates,
                          bundleComponentBuyRates: buyRates,
                          bundleComponentGstPercents: gstRates,
                          bundleComponentDescriptions: descriptions,
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(sharedPreferencesProvider);
    final bool enableBuyPrice = prefs.getBool('enable_sales_buy_price') ?? false;
    final item = widget.cartItem;
    final primaryUnit = item.item.primaryUnitName ?? item.item.unit.value?.shortName ?? item.item.unit.value?.unitName ?? 'PCS';
    final secondaryUnit = item.item.secondaryUnit;
    final List<String> availableUnits = [
      primaryUnit,
      if (secondaryUnit != null && secondaryUnit.isNotEmpty && secondaryUnit != primaryUnit) secondaryUnit,
    ];
    final selectedUnit = item.unit ?? primaryUnit;

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (!isDesktop) {
      // Mobile-optimized item card layout with expandable advanced inputs
      return NeuCard(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Index, Name & Delete Button
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item.itemName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        VariantDropdownWidget(
                          item: item.item,
                          selectedSubItemUuid: item.selectedSubItemUuid,
                          onChanged: (sub) {
                            if (sub != null) {
                              final newRate = sub.sellPrice ?? sub.buyPrice ?? item.rate;
                              ref.read(invoiceCartProvider.notifier).updateItemAt(
                                widget.index,
                                selectedSubItemUuid: sub.uuid,
                                selectedSubItemName: sub.name,
                                rate: newRate,
                                quantity: 1,
                              );
                              _qtyController.text = '1';
                              if (widget.isGstInclusive) {
                                _rateInclController.text = newRate.toStringAsFixed(2);
                                _rateExclController.text = (newRate / (1 + item.gstPercent / 100)).toStringAsFixed(2);
                              } else {
                                _rateExclController.text = newRate.toStringAsFixed(2);
                                _rateInclController.text = (newRate * (1 + item.gstPercent / 100)).toStringAsFixed(2);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (item.item.isBundle && (ref.read(sharedPreferencesProvider).getBool('enable_bundle_management') ?? false))
                    TextButton.icon(
                      icon: const Icon(Icons.extension, size: 16),
                      label: const Text('Components'),
                      onPressed: _showBundleComponentsDialog,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () {
                      ref.read(invoiceCartProvider.notifier).removeItemAt(widget.index);
                    },
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
                            final current = item.quantity;
                            if (current > 1) {
                              final next = current - 1;
                              _qtyController.text = next.toInt().toString();
                              ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, quantity: next);
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
                              final double? qty = double.tryParse(val);
                              if (qty != null && qty >= 0) {
                                ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, quantity: qty);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                          onPressed: () {
                            final next = item.quantity + 1;
                            _qtyController.text = next.toInt().toString();
                            ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, quantity: next);
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
                          ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, unit: val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rate Row: Rate Input + Tax Mode
              Row(
                children: [
                  // Rate Input Box — takes most space
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: widget.isGstInclusive ? _rateInclController : _rateExclController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: widget.isGstInclusive ? 'Rate Incl (\u20b9)' : 'Rate Excl (\u20b9)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                      ),
                      onChanged: (val) {
                        final double? parsed = double.tryParse(val);
                        if (parsed != null) {
                          ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, rate: parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tax Mode Toggle — compact
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<bool>(
                      isExpanded: true,
                      value: widget.isGstInclusive,
                      decoration: const InputDecoration(
                        labelText: 'Tax',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: false, child: Text('Excl', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: true, child: Text('Incl', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(invoiceCartProvider.notifier).toggleGstInclusive(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Buy Price Row — conditional, full width
              if (enableBuyPrice) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _buyRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Buy / Cost Price (\u20b9)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag_outlined, size: 16),
                  ),
                  onChanged: (val) {
                    final double? parsed = double.tryParse(val);
                    if (parsed != null) {
                      ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, buyRate: parsed);
                    }
                  },
                ),
              ],
              const SizedBox(height: 6),

              // Advanced Details Toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showMoreDetails = !_showMoreDetails;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showMoreDetails ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showMoreDetails ? 'Less Details' : 'More Details',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Details Panel
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _freeQtyController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Free Qty', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? fq = double.tryParse(val);
                                  if (fq != null) {
                                    ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, freeQuantity: fq);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _discAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Disc \u20b9', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final double? da = double.tryParse(val);
                                  if (da != null) {
                                    ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, discountAmount: da);
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
                                  ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, batchNumber: val.trim());
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _mfgDateController,
                                decoration: const InputDecoration(labelText: 'Mfg Date', isDense: true, border: OutlineInputBorder()),
                                onChanged: (val) {
                                  ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, mfgDate: val.trim());
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expDateController,
                          decoration: const InputDecoration(labelText: 'Expiry (e.g. 12/28)', isDense: true, border: OutlineInputBorder()),
                          onChanged: (val) {
                            ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, expiryDate: val.trim());
                          },
                        ),
                        if (ref.read(sharedPreferencesProvider).getBool('enable_item_descriptions') ?? false) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descController,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'Item Description', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, description: val.trim());
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                crossFadeState: _showMoreDetails ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 6),
              // Item Total Summary Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.percent, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'GST ${item.gstPercent.toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '\u20b9${item.calculateItemTotal(widget.isGstInclusive).toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.item.itemName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  VariantDropdownWidget(
                    item: item.item,
                    selectedSubItemUuid: item.selectedSubItemUuid,
                    onChanged: (sub) {
                      if (sub != null) {
                        final newRate = sub.sellPrice ?? sub.buyPrice ?? item.rate;
                        ref.read(invoiceCartProvider.notifier).updateItemAt(
                          widget.index,
                          selectedSubItemUuid: sub.uuid,
                          selectedSubItemName: sub.name,
                          rate: newRate,
                          quantity: 1,
                        );
                        _qtyController.text = '1';
                        if (widget.isGstInclusive) {
                          _rateInclController.text = newRate.toStringAsFixed(2);
                          _rateExclController.text = (newRate / (1 + item.gstPercent / 100)).toStringAsFixed(2);
                        } else {
                          _rateExclController.text = newRate.toStringAsFixed(2);
                          _rateInclController.text = (newRate * (1 + item.gstPercent / 100)).toStringAsFixed(2);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            if (item.item.isBundle && (ref.read(sharedPreferencesProvider).getBool('enable_bundle_management') ?? false))
              TextButton.icon(
                icon: const Icon(Icons.extension, size: 16),
                label: const Text('Components'),
                onPressed: _showBundleComponentsDialog,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(invoiceCartProvider.notifier).removeItemAt(widget.index);
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
                    ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, quantity: qty);
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
                      final conv = item.item.conversionFactor ?? 1.0;
                      if (conv > 0 && conv != 1.0) {
                        double currentRate = item.rate;
                        double newRate = currentRate;
                        if (oldUnit == primaryUnit && newUnit == secondaryUnit) {
                          newRate = currentRate / conv;
                        } else if (oldUnit == secondaryUnit && newUnit == primaryUnit) {
                          newRate = currentRate * conv;
                        }

                        final gstPct = item.gstPercent;
                        final double rateExcl = widget.isGstInclusive
                            ? newRate / (1 + gstPct / 100.0)
                            : newRate;
                        final double rateIncl = widget.isGstInclusive
                            ? newRate
                            : newRate * (1 + gstPct / 100.0);

                        _isUpdatingLocally = true;
                        _rateExclController.text = rateExcl.toStringAsFixed(2);
                        _rateInclController.text = rateIncl.toStringAsFixed(2);
                        _isUpdatingLocally = false;

                        ref.read(invoiceCartProvider.notifier).updateItemAt(
                          widget.index,
                          unit: newUnit,
                          rate: newRate,
                        );
                      } else {
                        ref.read(invoiceCartProvider.notifier).updateItemAt(
                          widget.index,
                          unit: newUnit,
                        );
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
                  
                  final gstPct = item.gstPercent;
                  final incl = excl * (1 + gstPct / 100.0);
                  
                  _isUpdatingLocally = true;
                  _rateInclController.text = incl.toStringAsFixed(2);
                  
                  final targetRate = widget.isGstInclusive ? incl : excl;
                  ref.read(invoiceCartProvider.notifier).updateItemAt(
                    widget.index,
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
                  ref.read(invoiceCartProvider.notifier).updateItemAt(
                    widget.index,
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
                    ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, discountPercent: pct);
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
                    ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, discountAmount: amt);
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
            if (enableBuyPrice) ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _buyRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Buy Price', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) {
                    final double? parsed = double.tryParse(val);
                    if (parsed != null) {
                      ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, buyRate: parsed);
                    }
                  },
                ),
              ),
            ],
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
                  ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, batchNumber: val.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _mfgDateController,
                decoration: const InputDecoration(labelText: 'MFG Date', hintText: 'MM/YYYY', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, mfgDate: val.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _expDateController,
                decoration: const InputDecoration(labelText: 'EXP Date', hintText: 'MM/YYYY', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(invoiceCartProvider.notifier).updateItemAt(widget.index, expiryDate: val.trim());
                },
              ),
            ),
          ],
        ),
      ],
    );

  }
}
