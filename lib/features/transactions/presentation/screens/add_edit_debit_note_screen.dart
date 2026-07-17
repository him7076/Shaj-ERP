import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';

class AddEditDebitNoteScreen extends ConsumerStatefulWidget {
  const AddEditDebitNoteScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditDebitNoteScreen> createState() => _AddEditDebitNoteScreenState();
}

class _AddEditDebitNoteScreenState extends ConsumerState<AddEditDebitNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Party? _selectedParty;
  DateTime _debitNoteDate = DateTime.now();
  final _originalPurchaseController = TextEditingController();
  final _remarksController = TextEditingController();

  final List<DebitNoteItem> _items = [];
  String _previewNumber = 'Loading...';

  // For adding items
  Item? _selectedItemForAdd;
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadPreviewNumber();
  }

  Future<void> _loadPreviewNumber() async {
    final repo = ref.read(debitNoteRepositoryProvider);
    final num = await repo.generateNextDebitNoteNumber();
    if (mounted) {
      setState(() {
        _previewNumber = num;
      });
    }
  }

  @override
  void dispose() {
    _originalPurchaseController.dispose();
    _remarksController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + ((item.rate ?? 0.0) * (item.quantity ?? 0.0)));
  }

  double get _discountTotal {
    return _items.fold(0.0, (sum, item) => sum + (item.discount ?? 0.0));
  }

  double get _taxableTotal {
    return _items.fold(0.0, (sum, item) => sum + (item.taxableAmount ?? 0.0));
  }

  double get _gstTotal {
    return _items.fold(0.0, (sum, item) => sum + (item.gstAmount ?? 0.0));
  }

  double get _rawGrandTotal {
    return _taxableTotal + _gstTotal;
  }

  double get _grandTotal {
    return _rawGrandTotal.roundToDouble();
  }

  double get _roundOff {
    return _grandTotal - _rawGrandTotal;
  }

  Map<String, double> _calculateGstBreakdown(String? companyGst) {
    final isLocal = GstService().isIntrastate(companyGst, _selectedParty?.gstNumber, partyState: _selectedParty?.state);

    if (isLocal) {
      return {
        'cgst': _gstTotal / 2.0,
        'sgst': _gstTotal / 2.0,
        'igst': 0.0,
      };
    } else {
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': _gstTotal,
      };
    }
  }

  void _addItem() {
    if (_selectedItemForAdd == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    if (qty <= 0) return;

    final taxable = (qty * rate) - discount;
    final gstRate = _selectedItemForAdd!.gstRate ?? 18.0;
    final gst = (taxable * gstRate) / 100.0;
    final total = taxable + gst;

    final noteItem = DebitNoteItem()
      ..itemId = _selectedItemForAdd!.id
      ..itemName = _selectedItemForAdd!.itemName
      ..hsnCode = _selectedItemForAdd!.hsnCode
      ..quantity = qty
      ..rate = rate
      ..discount = discount
      ..taxableAmount = taxable
      ..gstRate = gstRate
      ..gstAmount = gst
      ..totalAmount = total;
    
    if (!kIsWeb) {
      noteItem.item.value = _selectedItemForAdd;
    }

    setState(() {
      _items.add(noteItem);
      _selectedItemForAdd = null;
      _qtyController.text = '1';
      _rateController.clear();
      _discountController.text = '0';
    });
  }

  Future<void> _saveDebitNote() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final companySettings = await isar.settings.where().findFirst();
      final companyGst = companySettings?.companyGST;

      final gstSplit = _calculateGstBreakdown(companyGst);

      final debitNote = DebitNote()
        ..debitNoteNumber = _previewNumber
        ..debitNoteDate = _debitNoteDate
        ..originalPurchaseNumber = _originalPurchaseController.text.trim()
        ..partyId = _selectedParty!.id
        ..partyName = _selectedParty!.partyName
        ..gstNumber = _selectedParty!.gstNumber
        ..address = _selectedParty!.city
        ..subtotal = _subtotal
        ..discountAmount = _discountTotal
        ..taxableAmount = _taxableTotal
        ..cgstAmount = gstSplit['cgst']
        ..sgstAmount = gstSplit['sgst']
        ..igstAmount = gstSplit['igst']
        ..totalGST = _gstTotal
        ..roundOff = _roundOff
        ..grandTotal = _grandTotal
        ..remarks = _remarksController.text.trim()
        ..createdBy = 'Admin';

      if (!kIsWeb) {
        debitNote.party.value = _selectedParty;
      }

      final repo = ref.read(debitNoteRepositoryProvider);
      await repo.saveDebitNote(debitNote, _items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debit Note created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Debit Note: $e'), backgroundColor: Colors.red),
        );
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
    final partiesAsync = ref.watch(partiesListProvider);
    final itemsAsync = ref.watch(itemsListProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Debit Note (Purchase Return)'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDebitNote,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Information',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      if (isMobile) ...[
                        _buildPartyDropdown(partiesAsync),
                        const SizedBox(height: 16),
                        _buildDocNumberField(theme),
                        const SizedBox(height: 16),
                        _buildDateField(context, theme),
                        const SizedBox(height: 16),
                        _buildInvoiceRefField(),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildPartyDropdown(partiesAsync)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDocNumberField(theme)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDateField(context, theme)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInvoiceRefField()),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Item Adder Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Returned Item',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      itemsAsync.when(
                        data: (items) {
                          final activeItems = items.where((i) => !i.isDeleted).toList();
                          return DropdownButtonFormField<Item>(
                            value: _selectedItemForAdd,
                            decoration: const InputDecoration(
                              labelText: 'Select Product',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                            ),
                            items: activeItems.map((item) {
                              return DropdownMenuItem<Item>(
                                value: item,
                                child: Text('${item.itemName} (${item.skuCode ?? "No SKU"})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedItemForAdd = val;
                                  _rateController.text = (val.buyRate ?? 0.0).toString();
                                });
                              }
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading catalog: $e'),
                      ),
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        _buildNumberField(_qtyController, 'Quantity'),
                        const SizedBox(height: 12),
                        _buildNumberField(_rateController, 'Rate (₹)'),
                        const SizedBox(height: 12),
                        _buildNumberField(_discountController, 'Discount Amount (₹)'),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_qtyController, 'Quantity')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildNumberField(_rateController, 'Rate (₹)')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildNumberField(_discountController, 'Discount Amount (₹)')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add Item to Return list'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items Table Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items List (${_items.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No items added. Add products above to calculate returns.'),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final it = _items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(it.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${it.quantity} Qty x ₹${it.rate} | Taxable: ₹${it.taxableAmount?.toStringAsFixed(2)} | GST (${it.gstRate}%): ₹${it.gstAmount?.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${it.totalAmount?.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary totals Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary & Calculations',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}', theme),
                      _buildSummaryRow('Discount', '- ₹${_discountTotal.toStringAsFixed(2)}', theme),
                      _buildSummaryRow('Taxable Amount', '₹${_taxableTotal.toStringAsFixed(2)}', theme),
                      const Divider(),
                      ..._buildTaxBreakdownSummary(theme),
                      const Divider(),
                      _buildSummaryRow('Round Off', '₹${_roundOff.toStringAsFixed(2)}', theme),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _remarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80), // spacer for bottom navigation bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDebitNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Debit Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyDropdown(AsyncValue<List<Party>> partiesAsync) {
    return partiesAsync.when(
      data: (parties) {
        final suppliers = parties.where((p) => p.partyType == 'Supplier' && !p.isDeleted).toList();
        return SearchablePartyDropdown(
          parties: suppliers,
          selectedParty: _selectedParty,
          labelText: 'Supplier *',
          onChanged: (val) {
            setState(() {
              _selectedParty = val;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading suppliers: $e'),
    );
  }

  Widget _buildDocNumberField(ThemeData theme) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Debit Note Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
      child: Text(
        _previewNumber,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _debitNoteDate,
          firstDate: DateTime(2025),
          lastDate: DateTime(2030),
        );
        if (d != null) {
          setState(() {
            _debitNoteDate = d;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat('dd MMMM yyyy').format(_debitNoteDate)),
      ),
    );
  }

  Widget _buildInvoiceRefField() {
    return TextFormField(
      controller: _originalPurchaseController,
      decoration: const InputDecoration(
        labelText: 'Original Purchase Reference No.',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.receipt_long_outlined),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdownSummary(ThemeData theme) {
    final isar = ref.read(databaseServiceProvider).isar;
    final companySettings = isar.settings.where().findFirstSync();
    final companyGst = companySettings?.companyGST;

    final gstSplit = _calculateGstBreakdown(companyGst);

    if (gstSplit['igst']! > 0) {
      return [
        _buildSummaryRow('IGST Total', '₹${gstSplit['igst']!.toStringAsFixed(2)}', theme),
      ];
    } else {
      return [
        _buildSummaryRow('CGST Total', '₹${gstSplit['cgst']!.toStringAsFixed(2)}', theme),
        _buildSummaryRow('SGST Total', '₹${gstSplit['sgst']!.toStringAsFixed(2)}', theme),
      ];
    }
  }
}
