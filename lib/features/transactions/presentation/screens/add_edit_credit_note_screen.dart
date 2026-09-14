import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/unsaved_changes_provider.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/widgets/item_search_picker_modal.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:uuid/uuid.dart';

class AddEditCreditNoteScreen extends ConsumerStatefulWidget {
  final String? creditNoteUuid;
  final String? initialPartyUuid;
  final String? initialInvoiceNumber;
  final String? initialInvoiceUuid;

  const AddEditCreditNoteScreen({
    Key? key,
    this.creditNoteUuid,
    this.initialPartyUuid,
    this.initialInvoiceNumber,
    this.initialInvoiceUuid,
  }) : super(key: key);

  @override
  ConsumerState<AddEditCreditNoteScreen> createState() => _AddEditCreditNoteScreenState();
}

class _AddEditCreditNoteScreenState extends ConsumerState<AddEditCreditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final ScrollController _itemsScrollController = ScrollController();

  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _originalInvoiceController = TextEditingController();

  DateTime _creditNoteDate = DateTime.now();
  CreditNote? _existingCreditNote;
  String _voucherNumberDisplay = '';
  String? _companyGst;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(creditNoteCartProvider.notifier).clear();
      await _loadCompanySettings();

      if (widget.creditNoteUuid != null) {
        await _loadCreditNoteData();
      } else {
        try {
          final repo = ref.read(creditNoteRepositoryProvider);
          final nextNo = await repo.generateNextCreditNoteNumber();
          if (mounted) {
            setState(() => _voucherNumberDisplay = nextNo);
          }
        } catch (_) {}

        if (widget.initialPartyUuid != null) {
          final isar = ref.read(databaseServiceProvider).isar;
          final party = await isar.partys.filter().uuidEqualTo(widget.initialPartyUuid).findFirst();
          if (party != null) {
            ref.read(creditNoteCartProvider.notifier).setParty(party);
          }
        }
        if (widget.initialInvoiceNumber != null) {
          _originalInvoiceController.text = widget.initialInvoiceNumber!;
          ref.read(creditNoteCartProvider.notifier).setOriginalInvoice(widget.initialInvoiceNumber, widget.initialInvoiceUuid);
        }
      }
    });
  }

  Future<void> _loadCompanySettings() async {
    final isar = ref.read(databaseServiceProvider).isar;
    final companySettings = await isar.settings.filter().idGreaterThan(-1).findFirst();
    _companyGst = companySettings?.companyGST;
  }

  Future<void> _loadCreditNoteData() async {
    try {
      final db = ref.read(databaseServiceProvider).isar;
      final creditNote = await db.creditNotes.filter().uuidEqualTo(widget.creditNoteUuid).findFirst();
      if (creditNote != null) {
        _existingCreditNote = creditNote;
        _voucherNumberDisplay = creditNote.creditNoteNumber ?? '';
        _creditNoteDate = creditNote.creditNoteDate ?? DateTime.now();
        _remarksController.text = creditNote.remarks ?? '';
        _originalInvoiceController.text = creditNote.originalInvoiceNumber ?? '';
        
        final double subVal = creditNote.subtotal ?? 0.0;
        final double discAmtVal = creditNote.discountAmount ?? 0.0;
        _discountController.text = discAmtVal.toString();
        final double discPctVal = subVal > 0 ? (discAmtVal / subVal * 100) : 0.0;
        _discountPercentController.text = discPctVal.toStringAsFixed(1);

        Party? party;
        if (creditNote.partyId != null && creditNote.partyId! > 0) {
          party = await db.partys.get(creditNote.partyId!);
        }
        if (party == null && creditNote.partyName != null && creditNote.partyName!.isNotEmpty) {
          party = await db.partys.filter().partyNameEqualTo(creditNote.partyName!).findFirst();
        }

        if (party != null) {
          final itemsList = await db.creditNoteItems
              .filter()
              .isDeletedEqualTo(false)
              .and()
              .group((q) => q.parentCreditNoteIdEqualTo(creditNote.id).or().parentCreditNoteIdIsNull()) // Wait, actually I should link by parent ID properly. For Web Mock, parentCreditNoteId is used. For Isar, links are used.
              .findAll();
          
          final List<CreditNoteItem> realItems = [];
          try { await creditNote.creditNoteItems.load(); realItems.addAll(creditNote.creditNoteItems.where((i) => !i.isDeleted)); } catch (_) {}
          
          final effectiveItems = realItems.isNotEmpty ? realItems : itemsList;

          final List<CartItemState> cartItems = [];
          for (var item in effectiveItems) {
            Item? dbItem;
            if (item.itemId != null && item.itemId! > 0) {
              dbItem = await db.items.get(item.itemId!);
            }
            if (dbItem == null && item.itemName != null && item.itemName!.isNotEmpty) {
              dbItem = await db.items.filter().itemNameEqualTo(item.itemName!).findFirst();
            }

            if (dbItem != null) {
              final totalBase = (item.rate ?? 0.0) * (item.quantity ?? 1.0);
              final discPct = totalBase > 0 ? ((item.discount ?? 0.0) / totalBase) * 100.0 : 0.0;

              cartItems.add(
                CartItemState(
                  item: dbItem,
                  quantity: item.quantity ?? 1.0,
                  freeQuantity: item.freeQuantity ?? 0.0,
                  unit: item.unit ?? 'PCS',
                  rate: item.rate ?? 0.0,
                  discountPercent: discPct,
                  discountAmount: item.discount ?? 0.0,
                  gstPercent: item.gstRate ?? 18.0,
                  batchNumber: item.batchNumber,
                  expiryDate: item.expiryDate,
                  mfgDate: item.mfgDate,
                ),
              );
            }
          }

          ref.read(creditNoteCartProvider.notifier).loadCreditNote(
            party: party,
            creditNote: Transaction()..transactionDate = _creditNoteDate..remarks = creditNote.remarks..referenceNumber = creditNote.originalInvoiceNumber..linkedBillUuid = creditNote.uuid,
            items: cartItems,
            isGstInclusive: false,
          );
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading credit note: $e')));
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _discountController.dispose();
    _discountPercentController.dispose();
    _productSearchController.dispose();
    _originalInvoiceController.dispose();
    _itemsScrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _creditNoteDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _creditNoteDate = picked;
      });
      ref.read(creditNoteCartProvider.notifier).setDate(picked);
      ref.read(unsavedChangesProvider.notifier).state = true;
    }
  }

  void _onDiscountChanged() {
    final pct = double.tryParse(_discountPercentController.text);
    final amt = double.tryParse(_discountController.text);
    ref.read(creditNoteCartProvider.notifier).setDiscounts(pct, amt);
    ref.read(unsavedChangesProvider.notifier).state = true;
  }

  Future<void> _saveCreditNote() async {
    final cart = ref.read(creditNoteCartProvider);
    if (cart.selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer.')));
      return;
    }
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      final repo = ref.read(creditNoteRepositoryProvider);
      final totals = ref.read(creditNoteCartProvider.notifier).calculateTotals(_companyGst);

      final creditNote = _existingCreditNote ?? CreditNote();
      
      if (_existingCreditNote == null) {
         creditNote.uuid = const Uuid().v4();
         creditNote.creditNoteNumber = _voucherNumberDisplay;
      }

      creditNote
        ..creditNoteDate = _creditNoteDate
        ..originalInvoiceNumber = _originalInvoiceController.text.trim()
        ..partyId = cart.selectedParty!.id
        ..partyName = cart.selectedParty!.partyName
        ..gstNumber = cart.selectedParty!.gstNumber
        ..address = cart.selectedParty!.city
        ..subtotal = totals['subtotal']
        ..discountAmount = totals['discountAmount']
        ..taxableAmount = totals['subtotal']! - totals['discountAmount']!
        ..cgstAmount = totals['cgst']
        ..sgstAmount = totals['sgst']
        ..igstAmount = totals['igst']
        ..totalGST = totals['totalGST']
        ..roundOff = totals['roundOff']
        ..grandTotal = totals['grandTotal']
        ..remarks = _remarksController.text.trim()
        ..createdBy = auth.email ?? 'Admin';

      final List<CreditNoteItem> creditNoteItems = [];
      for (var cartItem in cart.items) {
        final taxRes = GstService().calculateTax(
          rate: cartItem.rate,
          quantity: cartItem.quantity,
          gstRatePercent: cartItem.gstPercent,
          isInclusive: cart.isGstInclusive,
          itemDiscountAmount: cartItem.discountAmount,
          companyGst: _companyGst,
          partyGst: cart.selectedParty?.gstNumber,
          partyState: cart.selectedParty?.state,
        );

        final item = CreditNoteItem()
          ..uuid = const Uuid().v4()
          ..itemId = cartItem.item.id
          ..itemName = cartItem.item.itemName
          ..hsnCode = cartItem.item.hsnCode
          ..quantity = cartItem.quantity
          ..freeQuantity = cartItem.freeQuantity
          ..unit = cartItem.unit
          ..rate = cartItem.rate
          ..discount = cartItem.discountAmount
          ..taxableAmount = taxRes.taxableAmount
          ..gstRate = cartItem.gstPercent
          ..gstAmount = taxRes.gstAmount
          ..totalAmount = taxRes.taxableAmount + taxRes.gstAmount
          ..batchNumber = cartItem.batchNumber
          ..mfgDate = cartItem.mfgDate
          ..expiryDate = cartItem.expiryDate;
          
        if (!kIsWeb) {
          item.item.value = cartItem.item;
        }
        creditNoteItems.add(item);
      }
      
      if (!kIsWeb) {
        creditNote.party.value = cart.selectedParty;
      }

      await repo.saveCreditNote(creditNote, creditNoteItems);

      ref.read(unsavedChangesProvider.notifier).state = false;
      ref.invalidate(filteredTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit Note saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save Credit Note: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final cartState = ref.watch(creditNoteCartProvider);
    final totals = ref.read(creditNoteCartProvider.notifier).calculateTotals(_companyGst);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(_existingCreditNote == null ? 'New Credit Note' : 'Edit Credit Note', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: const Text('SAVE'),
            onPressed: _isSaving ? null : _saveCreditNote,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _itemsScrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Voucher: $_voucherNumberDisplay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd MMM yyyy').format(_creditNoteDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SearchablePartyDropdown(
                                    selectedParty: cartState.selectedParty,
                                    onChanged: (party) {
                                      ref.read(creditNoteCartProvider.notifier).setParty(party);
                                      ref.read(unsavedChangesProvider.notifier).state = true;
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Party (Customer/Supplier) *',
                                      hintText: 'Search or select party',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.person),
                                    ),
                                  ),
                                ),
                                if (!isMobile) const SizedBox(width: 16),
                                if (!isMobile)
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _originalInvoiceController,
                                      decoration: InputDecoration(
                                        labelText: 'Original Invoice No.',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        prefixIcon: const Icon(Icons.receipt_long),
                                      ),
                                      onChanged: (val) {
                                        ref.read(creditNoteCartProvider.notifier).setOriginalInvoice(val, null);
                                        ref.read(unsavedChangesProvider.notifier).state = true;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            if (isMobile) const SizedBox(height: 16),
                            if (isMobile)
                              TextFormField(
                                controller: _originalInvoiceController,
                                decoration: InputDecoration(
                                  labelText: 'Original Invoice No.',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.receipt_long),
                                ),
                                onChanged: (val) {
                                  ref.read(creditNoteCartProvider.notifier).setOriginalInvoice(val, null);
                                  ref.read(unsavedChangesProvider.notifier).state = true;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Product Search
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: InkWell(
                          onTap: () async {
                            final item = await ItemSearchPickerModal.show(context);
                            if (item != null) {
                              ref.read(creditNoteCartProvider.notifier).addItem(item, qty: 1);
                              ref.read(unsavedChangesProvider.notifier).state = true;
                              _productSearchController.clear();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                Text('Tap to search and add product...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Items List
                    if (cartState.items.isNotEmpty)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartState.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildCartItemTile(context, index, cartState.items[index]);
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Totals
                    if (cartState.items.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMobile)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _remarksController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Remarks / Notes',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: (val) {
                                      ref.read(creditNoteCartProvider.notifier).setRemarks(val);
                                      ref.read(unsavedChangesProvider.notifier).state = true;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          if (!isMobile) const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _buildTotalRow('Subtotal', currencyFormat.format(totals['subtotal'])),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('Discount:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _discountPercentController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: '%', isDense: true, border: OutlineInputBorder()),
                                            onChanged: (val) {
                                              ref.read(creditNoteCartProvider.notifier).setDiscounts(double.tryParse(val), null);
                                              ref.read(unsavedChangesProvider.notifier).state = true;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _discountController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: 'Amt', isDense: true, border: OutlineInputBorder()),
                                            onChanged: (val) {
                                              ref.read(creditNoteCartProvider.notifier).setDiscounts(null, double.tryParse(val));
                                              ref.read(unsavedChangesProvider.notifier).state = true;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (totals['cgst']! > 0) ...[
                                      const SizedBox(height: 8),
                                      _buildTotalRow('CGST', currencyFormat.format(totals['cgst'])),
                                      const SizedBox(height: 4),
                                      _buildTotalRow('SGST', currencyFormat.format(totals['sgst'])),
                                    ],
                                    if (totals['igst']! > 0) ...[
                                      const SizedBox(height: 8),
                                      _buildTotalRow('IGST', currencyFormat.format(totals['igst'])),
                                    ],
                                    const SizedBox(height: 8),
                                    _buildTotalRow('Round Off', currencyFormat.format(totals['roundOff'])),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Grand Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        Text(currencyFormat.format(totals['grandTotal']), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    if (isMobile && cartState.items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Remarks / Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) {
                          ref.read(creditNoteCartProvider.notifier).setRemarks(val);
                          ref.read(unsavedChangesProvider.notifier).state = true;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCartItemTile(BuildContext context, int index, CartItemState itemState) {
    return ExpansionTile(
      title: Text(itemState.item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Qty: ${itemState.quantity} ${itemState.unit} | Rate: ₹${itemState.rate}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          ref.read(creditNoteCartProvider.notifier).removeItemAt(index);
          ref.read(unsavedChangesProvider.notifier).state = true;
        },
      ),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: itemState.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(creditNoteCartProvider.notifier).updateItemAt(index, quantity: double.tryParse(val));
                  ref.read(unsavedChangesProvider.notifier).state = true;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: itemState.rate.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(creditNoteCartProvider.notifier).updateItemAt(index, rate: double.tryParse(val));
                  ref.read(unsavedChangesProvider.notifier).state = true;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'GST Tax %', isDense: true, border: OutlineInputBorder()),
                child: Text('${itemState.gstPercent.toInt()}%'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: itemState.discountPercent.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc %', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(creditNoteCartProvider.notifier).updateItemAt(index, discountPercent: double.tryParse(val));
                  ref.read(unsavedChangesProvider.notifier).state = true;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: itemState.discountAmount.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Disc Amt (₹)', isDense: true, border: OutlineInputBorder()),
                onChanged: (val) {
                  ref.read(creditNoteCartProvider.notifier).updateItemAt(index, discountAmount: double.tryParse(val));
                  ref.read(unsavedChangesProvider.notifier).state = true;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}



