import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../data/local/collections/party_collection.dart';
import '../../../../data/local/collections/transaction_collection.dart';
import '../../../../data/local/collections/invoice_collection.dart';
import '../../../../data/local/collections/purchase_collection.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../presentation/providers/transaction_providers.dart';
import '../../../../presentation/providers/core_providers.dart';
import '../../../../core/widgets/searchable_party_dropdown.dart';
import 'package:isar/isar.dart';

class AddEditPartyTransferScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;
  const AddEditPartyTransferScreen({Key? key, this.existingTransaction}) : super(key: key);

  @override
  ConsumerState<AddEditPartyTransferScreen> createState() => _AddEditPartyTransferScreenState();
}

class _AddEditPartyTransferScreenState extends ConsumerState<AddEditPartyTransferScreen> {
  DateTime _date = DateTime.now();
  Party? _fromParty;
  Party? _toParty;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _imagePath;
  bool _isLoading = false;
  Map<String, double> _linkedAllocations = {};

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '?', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _date = widget.existingTransaction!.transactionDate ?? DateTime.now();
      _amountController.text = (widget.existingTransaction!.amount ?? 0).toString();
      _remarksController.text = widget.existingTransaction!.remarks ?? '';
      
      if (widget.existingTransaction!.tags != null && widget.existingTransaction!.tags!.isNotEmpty) {
        for (var tag in widget.existingTransaction!.tags!) {
          if (tag.startsWith('IMG:')) {
            _imagePath = tag.replaceFirst('IMG:', '');
          }
        }
      }

      final initialLink = widget.existingTransaction!.linkedBillUuid;
      if (initialLink != null && initialLink.isNotEmpty) {
        try {
          if (initialLink.startsWith('{')) {
            final decoded = json.decode(initialLink) as Map<String, dynamic>;
            _linkedAllocations = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
          } else {
            final initialAmt = widget.existingTransaction!.amount ?? 0.0;
            _linkedAllocations = {initialLink: initialAmt};
          }
        } catch (e) {
          debugPrint('Error parsing linkedBillUuid: $e');
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _save() async {
    if (_fromParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select From Party')));
      return;
    }
    if (_toParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select To Party')));
      return;
    }
    if (_fromParty!.uuid == _toParty!.uuid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From and To parties cannot be the same')));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.existingTransaction != null;
      final txn = isEdit ? widget.existingTransaction! : Transaction();

      if (!isEdit) {
        txn.uuid = const Uuid().v4();
      }

      txn.transactionType = 'Transfer';
      txn.transactionDate = _date;
      txn.amount = amount;
      txn.remarks = _remarksController.text;

      txn.partyUuid = _fromParty!.uuid;
      txn.partyName = _fromParty!.partyName;
      txn.targetPartyUuid = _toParty!.uuid;
      txn.targetPartyName = _toParty!.partyName;
      
      List<String> currentTags = txn.tags?.where((t) => !t.startsWith('IMG:')).toList() ?? [];
      if (_imagePath != null) {
        currentTags.add('IMG:$_imagePath');
      }
      txn.tags = currentTags.isEmpty ? null : currentTags;

      // Handle allocations
      final validAllocations = Map<String, double>.from(_linkedAllocations)
        ..removeWhere((k, v) => v <= 0);
        
      if (validAllocations.isNotEmpty) {
        txn.linkedBillUuid = json.encode(validAllocations);
        
        final isar = ref.read(databaseServiceProvider).isar;
        final invs = await isar.invoices.filter().anyOf(validAllocations.keys.toList(), (q, String id) => q.uuidEqualTo(id)).findAll();
        final purs = await isar.purchases.filter().anyOf(validAllocations.keys.toList(), (q, String id) => q.uuidEqualTo(id)).findAll();
        final Set<String> numbers = {};
        for (var i in invs) if (i.invoiceNumber != null) numbers.add(i.invoiceNumber!);
        for (var p in purs) if (p.purchaseNumber != null) numbers.add(p.purchaseNumber!);
        txn.linkedBillNumber = numbers.isNotEmpty ? numbers.join(', ') : null;
      } else {
        txn.linkedBillUuid = null;
        txn.linkedBillNumber = null;
      }

      await ref.read(transactionRepositoryProvider).saveTransaction(txn);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<List<dynamic>> _getPendingBillsForParty(String partyUuid) async {
    final isar = ref.read(databaseServiceProvider).isar;
    final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
    if (party == null) return [];
    
    final allInvs = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
    final allPurs = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
    
    final pNameLower = party.partyName?.trim().toLowerCase();
    
    final invs = allInvs.where((inv) => (inv.party.value?.uuid == partyUuid) || (inv.partyId == party.id) || (pNameLower != null && inv.partyName?.trim().toLowerCase() == pNameLower)).toList();
    final purs = allPurs.where((pur) => (pur.party.value?.uuid == partyUuid) || (pur.partyId == party.id) || (pNameLower != null && pur.partyName?.trim().toLowerCase() == pNameLower)).toList();
    
    final allBills = [...invs, ...purs];
    allBills.sort((a, b) {
      final aDate = a is Invoice ? a.invoiceDate : (a as Purchase).purchaseDate;
      final bDate = b is Invoice ? b.invoiceDate : (b as Purchase).purchaseDate;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // newest first
    });
    return allBills;
  }

  void _showLinkBillsDialog(BuildContext context, Party party) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _LinkBillsDialog(
          party: party,
          initialAllocations: _linkedAllocations,
          maxAmount: double.tryParse(_amountController.text) ?? 0.0,
          onSave: (newAllocations) {
            setState(() {
              // Remove old allocations for this party's bills, keep others, then merge
              // We don't have the party bills list easily here, so we just trust the dialog to return the full merged map
              _linkedAllocations = newAllocations;
            });
          },
          getPendingBills: () => _getPendingBillsForParty(party.uuid!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.existingTransaction != null ? 'Edit Party Transfer' : 'New Party Transfer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
      ),
      body: partiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (parties) {
          if (_fromParty == null && widget.existingTransaction != null) {
            _fromParty = parties.where((p) => p.uuid == widget.existingTransaction!.partyUuid).firstOrNull;
          }
          if (_toParty == null && widget.existingTransaction != null) {
            _toParty = parties.where((p) => p.uuid == widget.existingTransaction!.targetPartyUuid).firstOrNull;
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Amount & Date in one sleek card
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context, initialDate: _date,
                                            firstDate: DateTime(2000), lastDate: DateTime(2100),
                                          );
                                          if (picked != null) setState(() => _date = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Date', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                                              Text(DateFormat('dd MMM yy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('No.', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                                            Text(widget.existingTransaction?.transactionNumber ?? 'Auto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: 'Transfer Amount',
                                    alignLabelWithHint: true,
                                    prefixIcon: Icon(Icons.currency_rupee, color: theme.colorScheme.primary),
                                    filled: true,
                                    fillColor: theme.colorScheme.primary.withOpacity(0.05),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (v) => setState((){}),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // FROM PARTY
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withOpacity(0.3))),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('FROM PARTY (Giver)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                    if (_fromParty != null)
                                      InkWell(
                                        onTap: () => _showLinkBillsDialog(context, _fromParty!),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.link, size: 14, color: Colors.red),
                                              SizedBox(width: 4),
                                              Text('Link Bills', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SearchablePartyDropdown(
                                  parties: parties,
                                  selectedParty: _fromParty,
                                  labelText: 'Select From Party',
                                  onChanged: (p) => setState(() => _fromParty = p),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Center(child: Icon(Icons.swap_vert, color: Colors.grey, size: 24)),
                        ),

                        // TO PARTY
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.3))),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TO PARTY (Receiver)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    if (_toParty != null)
                                      InkWell(
                                        onTap: () => _showLinkBillsDialog(context, _toParty!),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.link, size: 14, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text('Link Bills', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SearchablePartyDropdown(
                                  parties: parties,
                                  selectedParty: _toParty,
                                  labelText: 'Select To Party',
                                  onChanged: (p) => setState(() => _toParty = p),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        
                        // Remarks
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Remarks & Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _remarksController,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Enter remarks...',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.all(10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_imagePath != null)
                                  Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb ? Image.network(_imagePath!, height: 80, width: double.infinity, fit: BoxFit.cover) 
                                                      : Image.file(File(_imagePath!), height: 80, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() => _imagePath = null),
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 14), label: const Text('Camera', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact))),
                                      const SizedBox(width: 8),
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 14), label: const Text('Gallery', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Sticky Area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                          child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text('Save Transfer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LinkBillsDialog extends StatefulWidget {
  final Party party;
  final Map<String, double> initialAllocations;
  final double maxAmount;
  final Function(Map<String, double>) onSave;
  final Future<List<dynamic>> Function() getPendingBills;

  const _LinkBillsDialog({
    required this.party,
    required this.initialAllocations,
    required this.maxAmount,
    required this.onSave,
    required this.getPendingBills,
  });

  @override
  State<_LinkBillsDialog> createState() => _LinkBillsDialogState();
}

class _LinkBillsDialogState extends State<_LinkBillsDialog> {
  late Map<String, double> _allocations;
  List<dynamic> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _allocations = Map.from(widget.initialAllocations);
    _loadBills();
  }

  Future<void> _loadBills() async {
    final bills = await widget.getPendingBills();
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
  }

  double get _totalAllocated => _allocations.values.fold(0.0, (sum, amt) => sum + amt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '?', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Link Bills: ${widget.party.partyName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_bills.isEmpty)
              const Expanded(child: Center(child: Text('No pending bills found.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    final isInvoice = bill is Invoice;
                    final uuid = isInvoice ? bill.uuid! : (bill as Purchase).uuid!;
                    final number = isInvoice ? bill.invoiceNumber : (bill as Purchase).purchaseNumber;
                    final date = isInvoice ? bill.invoiceDate : (bill as Purchase).purchaseDate;
                    final grandTotal = isInvoice ? bill.grandTotal ?? 0.0 : (bill as Purchase).grandTotal ?? 0.0;
                    final paid = isInvoice ? bill.paidAmount ?? 0.0 : (bill as Purchase).paidAmount ?? 0.0;
                    
                    final currentAlloc = _allocations[uuid] ?? 0.0;
                    final pending = grandTotal - paid + currentAlloc; // Add back current alloc to show full available
                    
                    if (pending <= 0 && currentAlloc <= 0) return const SizedBox.shrink();

                    final isLinked = currentAlloc > 0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: isLinked ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                        color: isLinked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${isInvoice ? 'INV' : 'PUR'} - $number', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(date != null ? DateFormat('dd MMM').format(date) : '', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pending: ${currencyFormat.format(pending)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                              Checkbox(
                                value: isLinked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      final maxCanAllocate = widget.maxAmount - _totalAllocated;
                                      final toAllocate = pending < maxCanAllocate ? pending : maxCanAllocate;
                                      if (toAllocate > 0) _allocations[uuid] = toAllocate;
                                    } else {
                                      _allocations.remove(uuid);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (isLinked) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Allocated: ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: currentAlloc.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    onChanged: (val) {
                                      final v = double.tryParse(val) ?? 0.0;
                                      if (v > pending) {
                                        _allocations[uuid] = pending;
                                      } else {
                                        _allocations[uuid] = v;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${currencyFormat.format(_totalAllocated)} / ${currencyFormat.format(widget.maxAmount)}', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: _totalAllocated > widget.maxAmount ? Colors.red : null)),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(_allocations);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
