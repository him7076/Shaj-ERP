import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';

class AddEditBankAccountDialog extends ConsumerStatefulWidget {
  final BankAccount? existingAccount;

  const AddEditBankAccountDialog({Key? key, this.existingAccount}) : super(key: key);

  @override
  ConsumerState<AddEditBankAccountDialog> createState() => _AddEditBankAccountDialogState();
}

class _AddEditBankAccountDialogState extends ConsumerState<AddEditBankAccountDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _numCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _balCtrl;
  bool _printOnInvoice = false;

  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();

    final acc = widget.existingAccount;
    _nameCtrl = TextEditingController(text: acc?.accountName);
    _bankCtrl = TextEditingController(text: acc?.bankName);
    _numCtrl = TextEditingController(text: acc?.accountNumber);
    _ifscCtrl = TextEditingController(text: acc?.ifscCode);
    _branchCtrl = TextEditingController(text: acc?.branchName);
    _balCtrl = TextEditingController(text: (acc?.openingBalance ?? 0.0).toString());
    _printOnInvoice = acc?.printOnInvoice ?? false;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _numCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _balCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final openBal = double.tryParse(_balCtrl.text.trim()) ?? 0.0;
      final isEdit = widget.existingAccount != null;

      final acc = widget.existingAccount ?? BankAccount();
      acc.accountName = _nameCtrl.text.trim();
      acc.bankName = _bankCtrl.text.trim();
      acc.accountNumber = _numCtrl.text.trim();
      acc.ifscCode = _ifscCtrl.text.trim().toUpperCase();
      acc.branchName = _branchCtrl.text.trim();
      acc.openingBalance = openBal;
      acc.printOnInvoice = _printOnInvoice;
      
      acc.uuid ??= const Uuid().v4();
      if (!isEdit) {
        acc.currentBalance = openBal;
      }
      acc.updatedAt = DateTime.now();
      acc.isSynced = false;

      await isar.writeTxn(() async {
        final id = await isar.bankAccounts.put(acc);
        await isar.syncQueues.put(SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'BankAccount'
          ..entityId = id
          ..entityUuid = acc.uuid
          ..operation = isEdit ? 'Update' : 'Insert'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now());
      });

      try {
        ref.read(syncServiceProvider).syncPendingChangesQuietly();
      } catch (_) {}

      ref.invalidate(bankAccountsListProvider);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeu = ref.watch(themeProvider).themeType == ThemeType.neumorphism;
    final isMobile = ResponsiveLayout.isMobile(context);

    final dialogContent = Container(
      width: isMobile ? MediaQuery.of(context).size.width : 500,
      height: isMobile ? MediaQuery.of(context).size.height : null,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(20),
        boxShadow: isMobile ? [] : [const BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: isMobile ? MediaQuery.of(context).padding.top + 16 : 16, bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
              borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.existingAccount != null ? 'Edit Bank Account' : 'Add Bank Account', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Account Display Name *', hintText: 'e.g. HDFC Primary A/C'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankCtrl,
                      decoration: const InputDecoration(labelText: 'Bank Name', hintText: 'e.g. HDFC Bank, State Bank of India'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'IFSC Code', hintText: 'e.g. HDFC0001234'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _branchCtrl,
                      decoration: const InputDecoration(labelText: 'Branch Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _balCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Opening Balance (₹)'),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Print bank details on invoices', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Check this if you want these details printed on PDF invoices.', style: TextStyle(fontSize: 12)),
                      value: _printOnInvoice,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _printOnInvoice = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: isMobile ? MediaQuery.of(context).padding.bottom + 12 : 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
              borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isNeu ? 8 : 2,
                    ),
                    onPressed: _isSaving ? null : _saveAccount,
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.existingAccount != null ? 'Update Account' : 'Save Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: dialogContent,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: dialogContent,
      ),
    );
  }
}
