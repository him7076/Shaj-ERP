import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';

class AddEditTransactionDialog extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? initialType;
  final Party? initialParty;
  final String? initialBillUuid;
  final String? initialBillNumber;
  final double? initialAmount;

  const AddEditTransactionDialog({
    Key? key,
    this.transaction,
    this.initialType,
    this.initialParty,
    this.initialBillUuid,
    this.initialBillNumber,
    this.initialAmount,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    Transaction? transaction,
    String? initialType,
    Party? initialParty,
    String? initialBillUuid,
    String? initialBillNumber,
    double? initialAmount,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditTransactionDialog(
        transaction: transaction,
        initialType: initialType,
        initialParty: initialParty,
        initialBillUuid: initialBillUuid,
        initialBillNumber: initialBillNumber,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  ConsumerState<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends ConsumerState<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late String _transactionType;
  late DateTime _transactionDate;
  late String _paymentMode;
  Party? _selectedParty;
  Party? _selectedTargetParty;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  List<dynamic> _pendingBills = [];
  String? _selectedBillUuid;
  String? _selectedBillNumber;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.transaction?.transactionType ?? widget.initialType ?? 'Receipt';
    _transactionDate = widget.transaction?.transactionDate ?? DateTime.now();
    _paymentMode = widget.transaction?.paymentMode ?? 'Cash';
    
    _amountController.text = widget.transaction?.amount?.toString() ?? widget.initialAmount?.toString() ?? '';
    _referenceController.text = widget.transaction?.referenceNumber ?? '';
    _remarksController.text = widget.transaction?.remarks ?? '';

    _selectedBillUuid = widget.transaction?.linkedBillUuid ?? widget.initialBillUuid;
    _selectedBillNumber = widget.transaction?.linkedBillNumber ?? widget.initialBillNumber;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parties = await ref.read(partiesListProvider.future);
      if (widget.transaction != null) {
        await widget.transaction!.party.load();
        _selectedParty = parties.firstWhere(
          (p) => p.uuid == widget.transaction!.partyUuid,
          orElse: () => parties.first,
        );
      } else if (widget.initialParty != null) {
        _selectedParty = parties.firstWhere(
          (p) => p.uuid == widget.initialParty!.uuid,
          orElse: () => widget.initialParty!,
        );
      }
      
      if (widget.transaction?.targetPartyUuid != null) {
        _selectedTargetParty = parties.firstWhere(
          (p) => p.uuid == widget.transaction!.targetPartyUuid,
          orElse: () => parties.first,
        );
      }

      if (_selectedParty != null) {
        await _fetchPendingBills();
      }
      setState(() {});
    });
  }

  Future<void> _fetchPendingBills() async {
    if (_selectedParty == null) return;
    final db = ref.read(databaseServiceProvider).isar;
    
    try {
      if (_transactionType == 'Receipt' || _transactionType == 'Credit Note') {
        // Fetch sales invoices
        final list = await db.invoices
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .partyIdEqualTo(_selectedParty!.id)
            .and()
            .group((q) => q.paymentStatusEqualTo('Unpaid').or().paymentStatusEqualTo('Partially Paid'))
            .findAll();
        setState(() {
          _pendingBills = list;
          // Ensure linked bill exists in options
          if (_selectedBillUuid != null && !list.any((i) => i.uuid == _selectedBillUuid)) {
            _selectedBillUuid = null;
            _selectedBillNumber = null;
          }
        });
      } else if (_transactionType == 'Payment' || _transactionType == 'Debit Note') {
        // Fetch purchases
        final list = await db.purchases
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .partyIdEqualTo(_selectedParty!.id)
            .and()
            .group((q) => q.paymentStatusEqualTo('Unpaid').or().paymentStatusEqualTo('Partially Paid'))
            .findAll();
        setState(() {
          _pendingBills = list;
          if (_selectedBillUuid != null && !list.any((p) => p.uuid == _selectedBillUuid)) {
            _selectedBillUuid = null;
            _selectedBillNumber = null;
          }
        });
      } else {
        setState(() {
          _pendingBills = [];
          _selectedBillUuid = null;
          _selectedBillNumber = null;
        });
      }
    } catch (e) {
      // Quietly ignore or log
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedParty == null && 
        _transactionType != 'Expense' && 
        _transactionType != 'Other Income') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a party')),
      );
      return;
    }

    if (_transactionType == 'Transfer' && _selectedTargetParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select target party')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      final txn = widget.transaction ?? Transaction();
      txn.transactionType = _transactionType;
      txn.transactionDate = _transactionDate;
      txn.amount = double.tryParse(_amountController.text) ?? 0.0;
      txn.paymentMode = _paymentMode;
      txn.referenceNumber = _referenceController.text;
      txn.remarks = _remarksController.text;
      
      txn.partyUuid = _selectedParty?.uuid;
      txn.partyName = _selectedParty?.partyName;

      txn.targetPartyUuid = _selectedTargetParty?.uuid;
      txn.targetPartyName = _selectedTargetParty?.partyName;

      txn.linkedBillUuid = _selectedBillUuid;
      txn.linkedBillNumber = _selectedBillNumber;

      await repo.saveTransaction(txn);
      
      ref.invalidate(filteredTransactionsProvider);
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction recorded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction: $e')),
      );
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaction != null ? 'Edit Transaction' : 'Record Transaction',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Transaction Type Dropdown
                DropdownButtonFormField<String>(
                  value: _transactionType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Receipt', child: Text('Receipt (Payment In)')),
                    DropdownMenuItem(value: 'Payment', child: Text('Payment (Payment Out)')),
                    DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note (Sales Return)')),
                    DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note (Purchase Return)')),
                    DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                    DropdownMenuItem(value: 'Transfer', child: Text('Party to Party Transfer')),
                    DropdownMenuItem(value: 'Other Income', child: Text('Other Income')),
                  ],
                  onChanged: (widget.transaction != null || widget.initialType != null)
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _transactionType = val;
                              _pendingBills = [];
                              _selectedBillUuid = null;
                              _selectedBillNumber = null;
                            });
                            _fetchPendingBills();
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Party selection (except for Expense or Other Income which can be blank)
                if (_transactionType != 'Expense' && _transactionType != 'Other Income') ...[
                  partiesAsync.when(
                    data: (parties) {
                      // Filter parties based on type
                      List<Party> filteredParties = parties;
                      if (_transactionType == 'Receipt' || _transactionType == 'Credit Note') {
                        filteredParties = parties.where((p) => p.partyType != 'Supplier').toList();
                      } else if (_transactionType == 'Payment' || _transactionType == 'Debit Note') {
                        filteredParties = parties.where((p) => p.partyType == 'Supplier').toList();
                      }

                      return DropdownButtonFormField<Party>(
                        value: _selectedParty != null && filteredParties.any((p) => p.uuid == _selectedParty!.uuid)
                            ? filteredParties.firstWhere((p) => p.uuid == _selectedParty!.uuid)
                            : null,
                        decoration: InputDecoration(
                          labelText: _transactionType == 'Receipt' || _transactionType == 'Credit Note'
                              ? 'Customer / Party'
                              : 'Supplier / Party',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        items: filteredParties.map((p) {
                          return DropdownMenuItem<Party>(
                            value: p,
                            child: Text(p.partyName ?? ''),
                          );
                        }).toList(),
                        onChanged: (party) {
                          setState(() {
                            _selectedParty = party;
                          });
                          _fetchPendingBills();
                        },
                        validator: (val) => val == null ? 'Select party' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading parties: $e'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Recipient Party Selection for Transfers
                if (_transactionType == 'Transfer') ...[
                  partiesAsync.when(
                    data: (parties) {
                      // Allow transferring to any party
                      return DropdownButtonFormField<Party>(
                        value: _selectedTargetParty != null && parties.any((p) => p.uuid == _selectedTargetParty!.uuid)
                            ? parties.firstWhere((p) => p.uuid == _selectedTargetParty!.uuid)
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Transfer To (Recipient Party)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                        items: parties
                            .where((p) => p.uuid != _selectedParty?.uuid)
                            .map((p) {
                          return DropdownMenuItem<Party>(
                            value: p,
                            child: Text(p.partyName ?? ''),
                          );
                        }).toList(),
                        onChanged: (party) {
                          setState(() {
                            _selectedTargetParty = party;
                          });
                        },
                        validator: (val) => val == null ? 'Select recipient party' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading parties: $e'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Linked bill selector
                if (_pendingBills.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedBillUuid,
                    decoration: const InputDecoration(
                      labelText: 'Link to Pending Bill (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('-- None / Advance Payment --'),
                      ),
                      ..._pendingBills.map((b) {
                        final billNo = b is Invoice ? b.invoiceNumber : (b as Purchase).purchaseNumber;
                        final total = b is Invoice ? b.grandTotal : (b as Purchase).grandTotal;
                        final pending = b is Invoice ? b.pendingAmount : (b as Purchase).pendingAmount;
                        return DropdownMenuItem<String>(
                          value: b.uuid,
                          child: Text('$billNo (Amt: ₹$total, Bal: ₹$pending)'),
                        );
                      }).toList()
                    ],
                    onChanged: (uuid) {
                      setState(() {
                        _selectedBillUuid = uuid;
                        if (uuid != null) {
                          final matching = _pendingBills.firstWhere((b) => b.uuid == uuid);
                          _selectedBillNumber = matching is Invoice
                              ? matching.invoiceNumber
                              : (matching as Purchase).purchaseNumber;
                          
                          // Pre-fill amount with pending amount if empty
                          final pendingAmt = matching is Invoice
                              ? matching.pendingAmount
                              : (matching as Purchase).pendingAmount;
                          if (_amountController.text.isEmpty) {
                            _amountController.text = pendingAmt?.toString() ?? '';
                          }
                        } else {
                          _selectedBillNumber = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _transactionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _transactionDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Transaction Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMMM yyyy').format(_transactionDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Mode Selector
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI / GooglePay / PhonePe')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'Credit', child: Text('Credit / Ledger Entry')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMode = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Reference Number
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number / Cheque No.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Internal Notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 24),

                // Save buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Transaction'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
