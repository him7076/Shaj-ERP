import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';

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
  Map<String, double> _linkedAllocations = {};
  final Map<String, TextEditingController> _allocControllers = {};
  final Map<String, FocusNode> _allocFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _transactionType = widget.transaction?.transactionType ?? widget.initialType ?? 'Receipt';
    _transactionDate = widget.transaction?.transactionDate ?? DateTime.now();
    _paymentMode = widget.transaction?.paymentMode ?? 'Cash';
    
    _amountController.text = widget.transaction?.amount?.toString() ?? widget.initialAmount?.toString() ?? '';
    _referenceController.text = widget.transaction?.referenceNumber ?? '';
    _remarksController.text = widget.transaction?.remarks ?? '';

    // Load initial allocations
    final initialLink = widget.transaction?.linkedBillUuid ?? widget.initialBillUuid;
    final initialAmt = widget.transaction?.amount ?? widget.initialAmount ?? 0.0;
    if (initialLink != null && initialLink.isNotEmpty) {
      if (initialLink.startsWith('{')) {
        try {
          final decoded = json.decode(initialLink) as Map<String, dynamic>;
          _linkedAllocations = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
        } catch (_) {
          _linkedAllocations = {initialLink: initialAmt};
        }
      } else {
        _linkedAllocations = {initialLink: initialAmt};
      }
    }

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
        final allInvoices = await db.invoices
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .partyIdEqualTo(_selectedParty!.id)
            .findAll();
        
        final list = allInvoices.where((inv) {
          final isUnpaidOrPartial = inv.paymentStatus == 'Unpaid' || inv.paymentStatus == 'Partially Paid';
          final isLinked = _linkedAllocations.containsKey(inv.uuid);
          return isUnpaidOrPartial || isLinked;
        }).toList();
        
        setState(() {
          _pendingBills = list;
          _updateControllers();
        });
      } else if (_transactionType == 'Payment' || _transactionType == 'Debit Note') {
        final allPurchases = await db.purchases
            .filter()
            .isDeletedEqualTo(false)
            .and()
            .partyIdEqualTo(_selectedParty!.id)
            .findAll();
        
        final list = allPurchases.where((p) {
          final isUnpaidOrPartial = p.paymentStatus == 'Unpaid' || p.paymentStatus == 'Partially Paid';
          final isLinked = _linkedAllocations.containsKey(p.uuid);
          return isUnpaidOrPartial || isLinked;
        }).toList();
        
        setState(() {
          _pendingBills = list;
          _updateControllers();
        });
      } else {
        setState(() {
          _pendingBills = [];
          _updateControllers();
        });
      }
    } catch (e) {
      // Quietly ignore
    }
  }

  void _updateControllers() {
    final currentUuids = _pendingBills.map((b) => b.uuid as String).toSet();
    _allocControllers.removeWhere((uuid, controller) {
      if (!currentUuids.contains(uuid)) {
        controller.dispose();
        _allocFocusNodes[uuid]?.dispose();
        _allocFocusNodes.remove(uuid);
        return true;
      }
      return false;
    });

    for (var bill in _pendingBills) {
      final uuid = bill.uuid as String;
      final alloc = _linkedAllocations[uuid] ?? 0.0;
      if (!_allocControllers.containsKey(uuid)) {
        _allocControllers[uuid] = TextEditingController(
          text: alloc > 0 ? alloc.toStringAsFixed(2) : '',
        );
        _allocFocusNodes[uuid] = FocusNode();
      } else {
        final textValue = alloc > 0 ? alloc.toStringAsFixed(2) : '';
        if (_allocControllers[uuid]!.text != textValue && !(_allocFocusNodes[uuid]?.hasFocus ?? false)) {
          _allocControllers[uuid]!.text = textValue;
        }
      }
    }
  }

  double getPendingToPay(dynamic bill) {
    final grandTotal = ((bill.grandTotal ?? 0.0) as num).toDouble();
    final paidAmount = ((bill.paidAmount ?? 0.0) as num).toDouble();
    final currentAlloc = _linkedAllocations[bill.uuid] ?? 0.0;
    final otherPaid = paidAmount - currentAlloc;
    return max(0.0, grandTotal - otherPaid);
  }

  void _autoAllocate() {
    final txnAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (txnAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transaction amount first')),
      );
      return;
    }

    final sortedBills = List<dynamic>.from(_pendingBills);
    sortedBills.sort((a, b) {
      final dateA = a.createdAt as DateTime?;
      final dateB = b.createdAt as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });

    double remaining = txnAmount;
    final Map<String, double> newAllocations = {};

    for (var bill in sortedBills) {
      if (remaining <= 0) break;
      final uuid = bill.uuid as String;
      final pendingToPay = getPendingToPay(bill);
      if (pendingToPay > 0) {
        final alloc = min(remaining, pendingToPay);
        newAllocations[uuid] = double.parse(alloc.toStringAsFixed(2));
        remaining -= alloc;
      }
    }

    setState(() {
      _linkedAllocations = newAllocations;
      _updateControllers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    for (var controller in _allocControllers.values) {
      controller.dispose();
    }
    for (var node in _allocFocusNodes.values) {
      node.dispose();
    }
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

    final totalTxn = double.tryParse(_amountController.text) ?? 0.0;
    
    // Filter out zero allocations
    final validAllocations = Map<String, double>.from(_linkedAllocations)
      ..removeWhere((k, v) => v <= 0.0);

    final totalAllocated = validAllocations.values.fold(0.0, (sum, val) => sum + val);
    if (totalAllocated > totalTxn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total allocated amount (₹${totalAllocated.toStringAsFixed(2)}) exceeds transaction amount (₹${totalTxn.toStringAsFixed(2)})')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      final txn = widget.transaction ?? Transaction();
      txn.transactionType = _transactionType;
      txn.transactionDate = _transactionDate;
      txn.amount = totalTxn;
      txn.paymentMode = _paymentMode;
      txn.referenceNumber = _referenceController.text;
      txn.remarks = _remarksController.text;
      
      txn.partyUuid = _selectedParty?.uuid;
      txn.partyName = _selectedParty?.partyName;

      txn.targetPartyUuid = _selectedTargetParty?.uuid;
      txn.targetPartyName = _selectedTargetParty?.partyName;

      txn.linkedBillUuid = validAllocations.isNotEmpty ? json.encode(validAllocations) : null;

      if (validAllocations.isNotEmpty) {
        final numbers = <String>[];
        for (final uuid in validAllocations.keys) {
          final bill = _pendingBills.firstWhere((b) => b.uuid == uuid, orElse: () => null);
          if (bill != null) {
            final numStr = _transactionType == 'Receipt' || _transactionType == 'Credit Note'
                ? (bill.invoiceNumber ?? '')
                : (bill.purchaseNumber ?? '');
            if (numStr.isNotEmpty) numbers.add(numStr);
          }
        }
        txn.linkedBillNumber = numbers.isNotEmpty ? numbers.join(', ') : null;
      } else {
        txn.linkedBillNumber = null;
      }

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

                      return SearchablePartyDropdown(
                        parties: filteredParties,
                        selectedParty: _selectedParty != null && filteredParties.any((p) => p.uuid == _selectedParty!.uuid)
                            ? filteredParties.firstWhere((p) => p.uuid == _selectedParty!.uuid)
                            : null,
                        labelText: _transactionType == 'Receipt' || _transactionType == 'Credit Note'
                            ? 'Customer / Party'
                            : 'Supplier / Party',
                        onChanged: (party) {
                          setState(() {
                            _selectedParty = party;
                          });
                          _fetchPendingBills();
                        },
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
                      final targetParties = parties.where((p) => p.uuid != _selectedParty?.uuid).toList();
                      return SearchablePartyDropdown(
                        parties: targetParties,
                        selectedParty: _selectedTargetParty != null && targetParties.any((p) => p.uuid == _selectedTargetParty!.uuid)
                            ? targetParties.firstWhere((p) => p.uuid == _selectedTargetParty!.uuid)
                            : null,
                        labelText: 'Transfer To (Recipient Party)',
                        onChanged: (party) {
                          setState(() {
                            _selectedTargetParty = party;
                          });
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading parties: $e'),
                  ),
                  const SizedBox(height: 16),
                ],
                                // Linked bills section
                if (_pendingBills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Link to Pending Bills',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _autoAllocate,
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Auto Allocate'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._pendingBills.map((bill) {
                          final uuid = bill.uuid as String;
                          final controller = _allocControllers[uuid];
                          if (controller == null) return const SizedBox();

                          final pendingToPay = getPendingToPay(bill);
                          final currentAlloc = _linkedAllocations[uuid] ?? 0.0;
                          final isLinked = currentAlloc > 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isLinked,
                                  onChanged: (val) {
                                    final totalTxn = double.tryParse(_amountController.text) ?? 0.0;
                                    final allocatedSoFar = _linkedAllocations.entries
                                        .where((e) => e.key != uuid)
                                        .fold(0.0, (sum, e) => sum + e.value);
                                    final remaining = max(0.0, totalTxn - allocatedSoFar);

                                    setState(() {
                                      if (val == true) {
                                        final allocVal = min(remaining, pendingToPay);
                                        _linkedAllocations[uuid] = double.parse(allocVal.toStringAsFixed(2));
                                      } else {
                                        _linkedAllocations.remove(uuid);
                                      }
                                      _updateControllers();
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _transactionType == 'Receipt' || _transactionType == 'Credit Note'
                                            ? 'Invoice #${bill.invoiceNumber ?? bill.uuid.substring(0, 8)}'
                                            : 'Bill #${bill.purchaseNumber ?? bill.uuid.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Date: ${bill.createdAt != null ? DateFormat('dd-MM-yyyy').format(bill.createdAt) : "N/A"} | Bal: ₹${pendingToPay.toStringAsFixed(2)}',
                                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  height: 38,
                                  child: TextFormField(
                                    controller: controller,
                                    focusNode: _allocFocusNodes[uuid],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      prefixText: '₹',
                                      hintText: '0.00',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val) ?? 0.0;
                                      setState(() {
                                        if (parsed > 0) {
                                          _linkedAllocations[uuid] = parsed;
                                        } else {
                                          _linkedAllocations.remove(uuid);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        // Summary status row
                        Builder(
                          builder: (context) {
                            final totalTxn = double.tryParse(_amountController.text) ?? 0.0;
                            final totalAllocated = _linkedAllocations.values.fold(0.0, (sum, val) => sum + val);
                            final remaining = totalTxn - totalAllocated;

                            Color statusColor = Colors.grey;
                            String statusText = 'No allocation';

                            if (totalTxn > 0) {
                              if (totalAllocated.toStringAsFixed(2) == totalTxn.toStringAsFixed(2)) {
                                statusColor = Colors.green;
                                statusText = 'Fully Allocated';
                              } else if (totalAllocated > totalTxn) {
                                statusColor = Colors.red;
                                statusText = 'Over-allocated by ₹${(totalAllocated - totalTxn).toStringAsFixed(2)}';
                              } else {
                                statusColor = Colors.orange;
                                statusText = 'Unallocated: ₹${remaining.toStringAsFixed(2)}';
                              }
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Allocated: ₹${totalAllocated.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
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
                ref.watch(bankAccountsListProvider).when(
                  data: (accounts) {
                    final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                    final dropdownItems = <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      const DropdownMenuItem(value: 'UPI', child: Text('UPI / GooglePay / PhonePe')),
                      const DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      const DropdownMenuItem(value: 'Credit', child: Text('Credit / Ledger Entry')),
                      ...activeAccounts.map((acc) => DropdownMenuItem(
                        value: acc.accountName,
                        child: Text(acc.accountName ?? ''),
                      )),
                    ];

                    // Safety fallback check to prevent dropdown value crash
                    if (_paymentMode != null && !dropdownItems.any((item) => item.value == _paymentMode)) {
                      dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode!)));
                    }

                    return DropdownButtonFormField<String>(
                      value: _paymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      items: dropdownItems,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _paymentMode = val;
                          });
                        }
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      const DropdownMenuItem(value: 'UPI', child: Text('UPI / GooglePay / PhonePe')),
                      const DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      const DropdownMenuItem(value: 'Credit', child: Text('Credit / Ledger Entry')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentMode = val;
                        });
                      }
                    },
                  ),
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
