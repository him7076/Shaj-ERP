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
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/widgets/searchable_party_dropdown.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';

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

    // Synchronously initialize linked party before first render so Party Name NEVER appears blank
    if (widget.transaction != null) {
      try {
        widget.transaction!.party.loadSync();
        if (widget.transaction!.party.value != null) {
          _selectedParty = widget.transaction!.party.value;
        }
      } catch (_) {}
      if (_selectedParty == null) {
        try {
          final isar = ref.read(databaseServiceProvider).isar;
          final pUuid = widget.transaction!.partyUuid;
          if (pUuid != null && pUuid.isNotEmpty) {
            _selectedParty = isar.partys.filter().uuidEqualTo(pUuid).findFirstSync();
          }
          final pName = widget.transaction!.partyName;
          if (_selectedParty == null && pName != null && pName.isNotEmpty) {
            _selectedParty = isar.partys.filter().partyNameEqualTo(pName).findFirstSync();
          }
        } catch (_) {}
      }
      if (_selectedParty == null && (widget.transaction!.partyName != null || widget.transaction!.partyUuid != null)) {
        _selectedParty = Party()
          ..uuid = widget.transaction!.partyUuid ?? ''
          ..partyName = widget.transaction!.partyName ?? 'Party Account';
      }
    } else if (widget.initialParty != null) {
      _selectedParty = widget.initialParty;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parties = await ref.read(partiesListProvider.future);
      if (widget.transaction != null && _selectedParty == null) {
        await widget.transaction!.party.load();
        _selectedParty = parties.firstWhere(
          (p) => p.uuid == widget.transaction!.partyUuid,
          orElse: () => parties.first,
        );
      } else if (_selectedParty == null && widget.initialParty != null) {
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
      final partyUuid = _selectedParty!.uuid;
      final partyId = _selectedParty!.id;

      final pNameLower = _selectedParty!.partyName?.trim().toLowerCase();

      if (_transactionType == 'Receipt' || _transactionType == 'Credit Note') {
        final allInvoices = await db.invoices
            .filter()
            .isDeletedEqualTo(false)
            .findAll();

        _pendingBills = allInvoices.where((inv) {
          final matchParty = (partyUuid != null && partyUuid.isNotEmpty && inv.party.value?.uuid == partyUuid) ||
                             (partyId > 0 && inv.partyId == partyId) ||
                             (pNameLower != null && pNameLower.isNotEmpty && inv.partyName?.trim().toLowerCase() == pNameLower);

          final isUnpaidOrPartial = inv.paymentStatus == 'Unpaid' || inv.paymentStatus == 'Partially Paid' || (inv.pendingAmount != null && inv.pendingAmount! > 0);
          final isLinked = (inv.uuid != null && _linkedAllocations.containsKey(inv.uuid)) ||
                           (inv.invoiceNumber != null && _linkedAllocations.containsKey(inv.invoiceNumber)) ||
                           _linkedAllocations.containsKey(inv.id.toString()) ||
                           (widget.transaction?.linkedBillUuid != null && (
                             (inv.uuid != null && widget.transaction!.linkedBillUuid!.contains(inv.uuid!)) ||
                             (inv.invoiceNumber != null && widget.transaction!.linkedBillUuid!.contains(inv.invoiceNumber!)) ||
                             widget.transaction!.linkedBillUuid!.contains(inv.id.toString())
                           )) ||
                           (widget.transaction?.linkedBillNumber != null && inv.invoiceNumber != null && widget.transaction!.linkedBillNumber!.contains(inv.invoiceNumber!));

          if (isLinked) return true;
          return matchParty && isUnpaidOrPartial;
        }).toList();

      } else if (_transactionType == 'Payment' || _transactionType == 'Debit Note') {
        final allPurchases = await db.purchases
            .filter()
            .isDeletedEqualTo(false)
            .findAll();

        _pendingBills = allPurchases.where((pur) {
          final matchParty = (partyUuid != null && partyUuid.isNotEmpty && pur.party.value?.uuid == partyUuid) ||
                             (partyId > 0 && pur.partyId == partyId) ||
                             (pNameLower != null && pNameLower.isNotEmpty && pur.partyName?.trim().toLowerCase() == pNameLower);

          final isUnpaidOrPartial = pur.paymentStatus == 'Unpaid' || pur.paymentStatus == 'Partially Paid' || (pur.pendingAmount != null && pur.pendingAmount! > 0);
          final isLinked = (pur.uuid != null && _linkedAllocations.containsKey(pur.uuid)) ||
                           (pur.purchaseNumber != null && _linkedAllocations.containsKey(pur.purchaseNumber)) ||
                           _linkedAllocations.containsKey(pur.id.toString()) ||
                           (widget.transaction?.linkedBillUuid != null && (
                             (pur.uuid != null && widget.transaction!.linkedBillUuid!.contains(pur.uuid!)) ||
                             (pur.purchaseNumber != null && widget.transaction!.linkedBillUuid!.contains(pur.purchaseNumber!)) ||
                             widget.transaction!.linkedBillUuid!.contains(pur.id.toString())
                           )) ||
                           (widget.transaction?.linkedBillNumber != null && pur.purchaseNumber != null && widget.transaction!.linkedBillNumber!.contains(pur.purchaseNumber!));

          if (isLinked) return true;
          return matchParty && isUnpaidOrPartial;
        }).toList();
      } else {
        _pendingBills = [];
      }
      _updateControllers();
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
    final pendingAmount = ((bill.pendingAmount ?? grandTotal) as num).toDouble();
    final currentAlloc = _linkedAllocations[bill.uuid] ?? 0.0;
    return max(0.0, pendingAmount + currentAlloc);
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
          final bill = _pendingBills.where((b) => b.uuid == uuid).firstOrNull;
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
      
      // Quiet background sync for newly saved transaction
      Future.microtask(() {
        try {
          ref.read(syncServiceProvider).syncPendingChangesQuietly();
        } catch (_) {}
      });

      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(filteredInvoicesProvider);
      ref.invalidate(partiesListProvider);
      
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

  Widget _buildTypeToggleChip(String type, String label, IconData icon, Color color) {
    final selected = _transactionType == type;
    final isDisabled = widget.transaction != null || widget.initialType != null;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 14, color: selected ? Colors.white : color),
      label: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: selected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      onSelected: isDisabled
          ? null
          : (val) {
              if (val) {
                setState(() {
                  _transactionType = type;
                  _pendingBills = [];
                });
                _fetchPendingBills();
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(partiesListProvider);

    final isMobile = ResponsiveLayout.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: isMobile ? 12 : 24),
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 520,
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Gradient Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _transactionType == 'Receipt' || _transactionType == 'Credit Note' || _transactionType == 'Other Income'
                          ? [const Color(0xFF059669), const Color(0xFF10B981)]
                          : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_transactionType == 'Receipt' ? Colors.green : Colors.red).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _transactionType == 'Receipt' ? Icons.south_west_rounded : Icons.north_east_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.transaction != null
                                    ? 'Edit ${_transactionType}'
                                    : 'New ${_transactionType} Entry',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _transactionType == 'Receipt' ? 'Money Received (Payment In)' : 'Money Paid (Payment Out)',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Fast Type Toggle Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeToggleChip('Receipt', 'Received Payment', Icons.arrow_downward_rounded, Colors.green),
                      const SizedBox(width: 8),
                      _buildTypeToggleChip('Payment', 'Made Payment', Icons.arrow_upward_rounded, Colors.red),
                      const SizedBox(width: 8),
                      _buildTypeToggleChip('Credit Note', 'Sales Return', Icons.assignment_return_rounded, Colors.orange),
                      const SizedBox(width: 8),
                      _buildTypeToggleChip('Debit Note', 'Pur Return', Icons.undo_rounded, Colors.deepOrange),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Party selection (except for Expense or Other Income which can be blank)
                if (_transactionType != 'Expense' && _transactionType != 'Other Income') ...[
                  partiesAsync.when(
                    data: (parties) {
                      List<Party> filteredParties = parties;
                      if (widget.transaction == null && widget.initialParty == null) {
                        if (_transactionType == 'Receipt' || _transactionType == 'Credit Note') {
                          filteredParties = parties.where((p) => p.partyType != 'Supplier').toList();
                        } else if (_transactionType == 'Payment' || _transactionType == 'Debit Note') {
                          filteredParties = parties.where((p) => p.partyType == 'Supplier').toList();
                        }
                      }

                      bool matchesParty(Party p, Party target) {
                        if (target.uuid != null && target.uuid!.isNotEmpty && p.uuid == target.uuid) return true;
                        if (target.id > 0 && p.id == target.id) return true;
                        return false;
                      }

                      // Ensure _selectedParty is ALWAYS included in filteredParties list if non-null
                      if (_selectedParty != null && !filteredParties.any((p) => matchesParty(p, _selectedParty!))) {
                        filteredParties = [ ...filteredParties, _selectedParty! ];
                      }

                      return SearchablePartyDropdown(
                        parties: filteredParties,
                        selectedParty: _selectedParty != null
                            ? (filteredParties.any((p) => matchesParty(p, _selectedParty!))
                                ? filteredParties.firstWhere((p) => matchesParty(p, _selectedParty!))
                                : _selectedParty)
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
                                // Amount & Direct Link Bills Button Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
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
                    ),
                    if (_transactionType == 'Receipt' || _transactionType == 'Payment' || _transactionType == 'Credit Note' || _transactionType == 'Debit Note') ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_selectedParty == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a Party first to link bills.')),
                            );
                            return;
                          }
                          await _fetchPendingBills();
                          if (mounted) {
                            _showLinkBillsDialog(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: Text(
                          _linkedAllocations.isNotEmpty ? 'Linked (${_linkedAllocations.length})' : 'Link Bills',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
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
                    if (!dropdownItems.any((item) => item.value == _paymentMode)) {
                      dropdownItems.add(DropdownMenuItem(value: _paymentMode, child: Text(_paymentMode)));
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

  void _showLinkBillsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalTxn = double.tryParse(_amountController.text) ?? 0.0;
            final totalAllocated = _linkedAllocations.values.fold(0.0, (sum, val) => sum + val);
            final remainingUnallocated = max(0.0, totalTxn - totalAllocated);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: min(580.0, MediaQuery.of(context).size.width - 24.0),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Link / Unlink Invoices & Bills',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_pendingBills.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No pending bills found for this party.'),
                        ),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _autoAllocate();
                              setModalState(() {});
                              setState(() {});
                            },
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Auto Allocate'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _linkedAllocations.clear();
                                _updateControllers();
                              });
                              setModalState(() {});
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.link_off_rounded, size: 16),
                            label: const Text('Unlink All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: SingleChildScrollView(
                          child: Column(
                            children: _pendingBills.map((bill) {
                              final uuid = bill.uuid as String;
                              final controller = _allocControllers[uuid];
                              if (controller == null) return const SizedBox();

                              final grandTotal = ((bill.grandTotal ?? 0.0) as num).toDouble();
                              final pendingToPay = getPendingToPay(bill);
                              final currentAlloc = _linkedAllocations[uuid] ?? 0.0;
                              final isLinked = currentAlloc > 0;
                              final remainingOnInvoice = max(0.0, pendingToPay - currentAlloc);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isLinked ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isLinked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isLinked,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            final allocVal = min(remainingUnallocated, pendingToPay);
                                            _linkedAllocations[uuid] = double.parse(allocVal.toStringAsFixed(2));
                                          } else {
                                            _linkedAllocations.remove(uuid);
                                          }
                                          _updateControllers();
                                        });
                                        setState(() {});
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
                                            'Total: ₹${grandTotal.toStringAsFixed(2)} | Pending: ₹${remainingOnInvoice.toStringAsFixed(2)}',
                                            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 100,
                                      height: 38,
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          prefixText: '₹',
                                          hintText: '0.00',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val) ?? 0.0;
                                          setModalState(() {
                                            if (parsed > 0) {
                                              _linkedAllocations[uuid] = parsed;
                                            } else {
                                              _linkedAllocations.remove(uuid);
                                            }
                                          });
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    if (isLinked) ...[
                                      IconButton(
                                        tooltip: 'Unlink Transaction',
                                        icon: const Icon(Icons.link_off_rounded, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setModalState(() {
                                            _linkedAllocations.remove(uuid);
                                            _updateControllers();
                                          });
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Txn: ₹${totalTxn.toStringAsFixed(2)} | Allocated: ₹${totalAllocated.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            setState(() {});
                          },
                          child: const Text('Done'),
                        ),
                      ],
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
}
