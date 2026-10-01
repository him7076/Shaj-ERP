import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_payment_mode_dropdown.dart';
import 'package:business_sahaj_erp/core/widgets/round_off_field.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/full_screen_item_entry.dart';
import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/widgets/item_search_picker_modal.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/core/widgets/variant_dropdown_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
class AddEditDebitNoteScreen extends ConsumerStatefulWidget {
  final String? parentDebitNoteUuid;
  final String? initialInvoiceNumber;
  final String? initialInvoiceUuid;
  const AddEditDebitNoteScreen({Key? key, this.parentDebitNoteUuid, this.initialInvoiceNumber, this.initialInvoiceUuid}) : super(key: key);

  @override
  ConsumerState<AddEditDebitNoteScreen> createState() => _AddEditDebitNoteScreenState();
}

class _AddEditDebitNoteScreenState extends ConsumerState<AddEditDebitNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _originalBillNumberController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0.0');
  final _productSearchController = TextEditingController();
  final ScrollController _itemsScrollController = ScrollController();

  Party? _selectedParty;
  List<DebitNoteItem> _draftItems = [];
  DateTime _debitNoteDate = DateTime.now();
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
  DebitNote? _existingDebitNote;
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

    bool _isDiscountPercent = false;
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
    });
    _loadPaymentModes();
    _initValues();
  }

  void _initValues() async {
    final repo = ref.read(debitNoteRepositoryProvider);
    final isar = ref.read(databaseServiceProvider).isar;
    final settings = await isar.settings.filter().idGreaterThan(-1).findFirst();
    _companyGst = settings?.companyGST;

    if (widget.parentDebitNoteUuid != null && widget.parentDebitNoteUuid!.isNotEmpty) {
      DebitNote? debitNote = await isar.debitNotes.filter().uuidEqualTo(widget.parentDebitNoteUuid).findFirst();
      if (debitNote == null) {
        final idVal = int.tryParse(widget.parentDebitNoteUuid!);
        if (idVal != null) {
          debitNote = await isar.debitNotes.get(idVal);
        }
      }

      if (debitNote != null) {
        _existingDebitNote = debitNote;
        _billNumberController.text = debitNote.debitNoteNumber ?? '';
        _originalBillNumberController.text = debitNote.originalPurchaseNumber ?? '';
        _debitNoteDate = debitNote.debitNoteDate ?? DateTime.now();
        final remarksText = debitNote.remarks ?? '';
        _remarksController.text = remarksText;
        
        _discountController.text = debitNote.discountAmount?.toString() ?? '0.0';

        Party? party;
        if (debitNote.partyId != null && debitNote.partyId! > 0) {
          party = await isar.partys.get(debitNote.partyId!);
        }
        if (party == null && debitNote.partyName != null && debitNote.partyName!.isNotEmpty) {
          party = await isar.partys.filter().partyNameEqualTo(debitNote.partyName!).findFirst();
        }
        if (party == null) {
          try { await debitNote.party.load(); } catch (_) {}
          try { party = debitNote.party.value; } catch (_) {}
        }
        _selectedParty = party ?? (Party()
          ..partyName = debitNote.partyName
          ..gstNumber = debitNote.gstNumber
          ..addressLine1 = debitNote.address);

        List<DebitNoteItem> itemsList = [];
        final pId = debitNote.id;
        final pUuid = debitNote.uuid;


        if (itemsList.isEmpty && pId != 0 && pId != Isar.autoIncrement) {
          itemsList = await isar.debitNoteItems
              .filter()
              .parentDebitNoteIdEqualTo(pId)
              .findAll();
        }
        if (itemsList.isEmpty) {
          try { await debitNote.debitNoteItems.load(); } catch (_) {}
          try { itemsList = debitNote.debitNoteItems.toList(); } catch (_) {}
        }

        for (var pi in itemsList) {
          Item? dbItem;
          if (pi.itemId != null && pi.itemId! > 0) {
            try { dbItem = await isar.items.get(pi.itemId!); } catch (_) {}
          }
          if (dbItem == null && pi.itemName != null && pi.itemName!.isNotEmpty) {
            try { dbItem = await isar.items.filter().itemNameEqualTo(pi.itemName!).findFirst(); } catch (_) {}
          }
          if (dbItem == null) {
            try { await pi.item.load(); } catch (_) {}
            try { dbItem = pi.item.value; } catch (_) {}
          }
          if (dbItem != null) {
            try { pi.item.value = dbItem; } catch (_) {}
            try { await dbItem.unit.load(); } catch (_) {}
          }
        }

        _draftItems = List<DebitNoteItem>.from(itemsList);
        _recalculateTotals();
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      final numStr = await repo.generateNextDebitNoteNumber();
      _billNumberController.text = numStr;
      if (widget.initialInvoiceNumber != null) {
        _originalBillNumberController.text = widget.initialInvoiceNumber!;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _billNumberController.dispose();
    _originalBillNumberController.dispose();
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

    final discInput = double.tryParse(_discountController.text) ?? 0.0;
    _discountAmount = _isDiscountPercent ? (sub * (discInput / 100.0)) : discInput;
    final double rawTotal = (sub - _discountAmount) + tax;
    _roundOff = _customRoundOff ?? (rawTotal.roundToDouble() - rawTotal);

    setState(() {
      _subtotal = sub;
      _taxableAmount = sub - _discountAmount;
      _totalGST = tax;
      _grandTotal = rawTotal + _roundOff;
    });
  }


  void _addFullScreenItemLine(FullScreenItemEntryData data) {
    final item = data.item;

    final newItem = DebitNoteItem()
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

    setState(() { _draftItems.add(newItem); });
    _recalculateTotals();
  }

  void _addItemLine(SelectedProductData data) async {
    final item = data.item;
    try {
      await item.unit.load();
    } catch (_) {}

    final primaryUnitName = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';

    final newItem = DebitNoteItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..selectedSubItemUuid = data.selectedSubItem?.uuid
      ..selectedSubItemName = data.selectedSubItem?.name
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
        const SnackBar(content: Text('Please add at least one item to debitNote.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String currentRemarks = _remarksController.text.trim();

      final debitNote = _existingDebitNote ?? DebitNote();
      if (_existingDebitNote == null) {
        debitNote.uuid ??= Uuid().v4();
        debitNote.debitNoteNumber = _billNumberController.text.trim();
        debitNote.createdAt = DateTime.now();
        debitNote.version = 1;
      } else {
        debitNote.uuid ??= Uuid().v4();
        debitNote.version = _existingDebitNote!.version + 1;
      }

      debitNote
        ..debitNoteDate = _debitNoteDate
        ..debitNoteNumber = _billNumberController.text.trim()
        ..originalPurchaseNumber = _originalBillNumberController.text.trim()
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
        ..remarks = currentRemarks
        ..updatedAt = DateTime.now()
      ..paymentMode = _paymentMode
      ..discountType = _isDiscountPercent ? 'percentage' : 'flat'
      ..discountPercent = _isDiscountPercent ? (double.tryParse(_discountController.text) ?? 0.0) : 0.0
      ..attachedImage = _attachedImage
      ..isSynced = false;

      if (!kIsWeb) {
        debitNote.party.value = _selectedParty;
      }

      await Future.delayed(Duration.zero);
      final repo = ref.read(debitNoteRepositoryProvider);
      await repo.saveDebitNote(debitNote, _draftItems);
      final success = true;

      ref.invalidate(dashboardAnalyticsProvider);

      // Lightweight non-blocking quiet background sync
      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DebitNote invoice saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save debitNote: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  
  void _showLinkBillsModal() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account first.')));
      return;
    }

    final isar = ref.read(databaseServiceProvider).isar;
    List<dynamic> pendingBills = [];
    
    if (false) {
      // Credit Note -> Link to Sales Invoices
      final invoices = await isar.invoices.filter()
          .partyNameEqualTo(_selectedParty!.partyName)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = invoices.where((inv) {
        final grandTotal = inv.grandTotal ?? 0.0;
        final pendingAmount = inv.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _originalBillNumberController.text == inv.invoiceNumber;
      }).toList();
    } else {
      // Debit Note -> Link to Purchases
      final purchases = await isar.purchases.filter()
          .partyNameEqualTo(_selectedParty!.partyName)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = purchases.where((pur) {
        final grandTotal = pur.grandTotal ?? 0.0;
        final pendingAmount = pur.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _originalBillNumberController.text == pur.purchaseNumber;
      }).toList();
    }

    if (pendingBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending bills found for this account.')));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Link Bill'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: pendingBills.map((bill) {
                      final isLinked = _originalBillNumberController.text == (false ? bill.invoiceNumber : bill.purchaseNumber);
                      final grandTotal = bill.grandTotal ?? 0.0;
                      final pendingToPay = bill.pendingAmount ?? grandTotal;
                      final billNo = false ? bill.invoiceNumber : bill.purchaseNumber;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: isLinked ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: isLinked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isLinked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  }
                                });
                                setState((){});
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill #${billNo ?? bill.uuid.substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total: ₹${grandTotal.toStringAsFixed(2)} | Pending: ₹${pendingToPay.toStringAsFixed(2)}',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isLinked)
                              IconButton(
                                tooltip: 'Unlink',
                                icon: const Icon(Icons.link_off_rounded, color: Colors.red, size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    _originalBillNumberController.clear();
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  });
                                  setState((){});
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget build(BuildContext context) {
if (_isPaidAmountAutoFill) {
       final currentPaid = double.tryParse(_paidAmountController.text) ?? 0.0;
       if ((currentPaid - _grandTotal).abs() > 0.01) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
               _paidAmountController.text = _grandTotal.toStringAsFixed(2);
             }
          });
       }
    }

    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_isSaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPartyAndHeaderCard(theme),
        const SizedBox(height: 12),
        _buildCartItemsTable(theme),
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
                          _paidAmountController.text = _grandTotal.toStringAsFixed(2);
                        } else {
                          _paidAmountController.clear();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Received Amount (₹)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _isPaidAmountAutoFill = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showLinkBillsModal,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Link'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: ref.watch(bankAccountsListProvider).when(
                    data: (accounts) {
                      final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                      final modes = ['Cash', 'Credit', 'Cheque', 'UPI', 'Bank Transfer', ...activeAccounts.map((a) => a.bankName ?? '')].toSet().toList();
                      return SearchablePaymentModeDropdown(
                        paymentModes: modes,
                        selectedMode: _paymentMode,
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMode = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: ToggleButtons(
                            isSelected: [_isDiscountPercent, !_isDiscountPercent],
                            onPressed: (idx) {
                                  setState(() {
                                    bool newIsPercent = idx == 0;
                                    if (newIsPercent == _isDiscountPercent) return;
                                    
                                    _isDiscountPercent = newIsPercent;
                                    
                                    if (_isDiscountPercent) {
                                       double percent = 0.0;
                                       if (_subtotal > 0) percent = (_discountAmount / _subtotal) * 100.0;
                                       _discountController.text = (percent % 1 == 0) ? percent.toInt().toString() : percent.toStringAsFixed(2);
                                    } else {
                                       _discountController.text = (_discountAmount % 1 == 0) ? _discountAmount.toInt().toString() : _discountAmount.toStringAsFixed(2);
                                    }
                                    _recalculateTotals();
                                  });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                            children: const [
                              Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) => _recalculateTotals(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              decoration: InputDecoration(labelText: 'Remarks / Notes', ),
            ),
            const Divider(height: 32),
            _buildTotalsSummaryPanel(theme),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save DebitNote Bill'),
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
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
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: Text(
          widget.parentDebitNoteUuid != null
              ? 'Edit DebitNote ${_billNumberController.text.isNotEmpty ? "(#${_billNumberController.text})" : ""}'
              : 'New DebitNote ${_billNumberController.text.isNotEmpty ? "(#${_billNumberController.text})" : ""}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  const SizedBox(height: 12),
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
              label: const Text('Save DebitNote Bill', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier Party Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            partiesAsync.when(
              data: (parties) {
                final supplierParties = parties; // All parties
                return SearchablePartyDropdown(
                  parties: supplierParties,
                  selectedParty: _selectedParty != null && supplierParties.any((p) => (p.uuid != null && p.uuid == _selectedParty!.uuid) || p.id == _selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == _selectedParty!.partyName?.trim().toLowerCase()))
                      ? supplierParties.firstWhere((p) => (p.uuid != null && p.uuid == _selectedParty!.uuid) || p.id == _selectedParty!.id || (p.partyName != null && p.partyName?.trim().toLowerCase() == _selectedParty!.partyName?.trim().toLowerCase()))
                      : _selectedParty,
                  labelText: 'Select Account',
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
                        initialDate: _debitNoteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => _debitNoteDate = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'DebitNote Date',  isDense: true),
                      child: Text(DateFormat('dd-MM-yyyy').format(_debitNoteDate), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
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



  Widget _buildCartItemsTable(ThemeData theme) {
    if (_draftItems.isEmpty) {
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
                        FullScreenItemEntry.show(
      context, isPurchase: true,
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        _addItemLine(tempSelected);
        setState(() {
           if (_draftItems.isNotEmpty) {
             _draftItems.last.quantity = data.quantity;
             _draftItems.last.discount = data.discountAmount;
           }
        });
        _recalculateTotals();
        
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
                          FullScreenItemEntry.show(
      context, onlyBundles: true, isPurchase: true,
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        _addItemLine(tempSelected);
        setState(() {
           if (_draftItems.isNotEmpty) {
             _draftItems.last.quantity = data.quantity;
             _draftItems.last.discount = data.discountAmount;
           }
        });
        _recalculateTotals();
        
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      FullScreenItemEntry.show(
      context, isPurchase: true,
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        _addItemLine(tempSelected);
        setState(() {
           if (_draftItems.isNotEmpty) {
             _draftItems.last.quantity = data.quantity;
             _draftItems.last.discount = data.discountAmount;
           }
        });
        _recalculateTotals();
        
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
                        FullScreenItemEntry.show(
      context, onlyBundles: true, isPurchase: true,
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        
        _addItemLine(tempSelected);
        setState(() {
           if (_draftItems.isNotEmpty) {
             _draftItems.last.quantity = data.quantity;
             _draftItems.last.discount = data.discountAmount;
           }
        });
        _recalculateTotals();
        
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
                child: RoundOffField(value: _roundOff, onChanged: (val) { setState(() { _customRoundOff = double.tryParse(val); }); _recalculateTotals(); }),
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

class PurchaseCartItemRow extends ConsumerWidget {
  final int index;
  final DebitNoteItem item;
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

    final double qty = item.quantity ?? 1.0;
    final double rate = item.rate ?? 0.0;
    final double discountAmount = item.discount ?? 0.0;
    final double gstPct = item.gstRate ?? 0.0;
    final double total = item.totalAmount ?? 0.0;
    final double taxAmount = item.gstAmount ?? 0.0;

    return NeuCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.item.value == null) return;
          FullScreenItemEntry.show(
            context,
            isPurchase: true,
            isFixedAsset: false,
            excludeBundles: false,
            onlyBundles: false,
            initialData: FullScreenItemEntryData(
              item: item.item.value!,
              quantity: qty,
              rate: rate,
              discountAmount: discountAmount,
              discountPercent: 0.0,
              gstRate: gstPct,
              unit: item.unit ?? 'PCS',
              batchNumber: item.batchNumber,
              mfgDate: parseDate(item.mfgDate),
              expDate: parseDate(item.expiryDate),
              saleRate: item.item.value!.sellRate ?? rate,
              purchaseRate: item.item.value!.buyRate ?? 0.0,
              isSaleRateWithTax: false,
              isPurchaseRateWithTax: false,
              description: item.description,
            ),
            onAdd: (data) {
              item.unit = data.unit;
              item.batchNumber = data.batchNumber;
              item.mfgDate = data.mfgDate != null ? DateFormat('MM/yyyy').format(data.mfgDate!) : null;
              item.expiryDate = data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null;
              item.description = data.item.description;
              
              onChanged(data.quantity, data.rate, data.discountAmount, data.gstRate);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${index + 1}  ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Expanded(
                    child: Text(
                      item.itemName ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    '₹ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              if (item.description != null && item.description!.isNotEmpty &&
                  (item.item.value?.isBundle == true
                      ? (ref.watch(sharedPreferencesProvider).getBool('enable_bundle_description') ?? false)
                      : (ref.watch(sharedPreferencesProvider).getBool('enable_item_description') ?? false)))
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(item.description!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: ${qty} ${item.unit ?? 'PCS'} x Rate: ${rate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Subtotal: ${(qty * rate).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Discount: -₹ ${discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              if (taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tax @ ${gstPct}%: +₹ ${taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              if (enableItemDesc && item.description != null && item.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Desc: ${item.description}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                  ),
                ),
              Align(
             alignment: Alignment.bottomRight,
             child: InkWell(
               onTap: onDelete,
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
