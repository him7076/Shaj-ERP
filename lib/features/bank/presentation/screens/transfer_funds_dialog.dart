import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';

class TransferFundsDialog extends ConsumerStatefulWidget {
  final String? defaultFromAccount;
  final Transaction? existingTransaction;

  const TransferFundsDialog({Key? key, this.defaultFromAccount, this.existingTransaction}) : super(key: key);

  @override
  ConsumerState<TransferFundsDialog> createState() => _TransferFundsDialogState();
}

class _TransferFundsDialogState extends ConsumerState<TransferFundsDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  String _transferType = 'Bank to Cash';
  String _adjustmentType = 'Increase Balance'; // 'Bank to Cash', 'Cash to Bank', 'Bank to Bank'
  DateTime _date = DateTime.now();
  String? _fromBank;
  String? _toBank;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _photoPath;
  
  List<String> _bankAccounts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
    
    if (widget.existingTransaction != null) {
      _isEditing = true;
      final t = widget.existingTransaction!;
      _amountController.text = t.amount?.toString() ?? '';
      _date = t.transactionDate ?? DateTime.now();
      _descController.text = t.remarks ?? '';
      _photoPath = t.referenceNumber; // Assuming this might hold URL or path
      
      if (t.paymentMode == 'Cash' && t.partyName != 'Cash') {
         _transferType = 'Cash to Bank';
         _toBank = t.partyName;
      } else if (t.partyName == 'Cash' && t.paymentMode != 'Cash') {
         _transferType = 'Bank to Cash';
         _fromBank = t.paymentMode;
      } else {
         _transferType = 'Bank to Bank';
         _fromBank = t.paymentMode;
         _toBank = t.partyName;
      }
    } else if (widget.defaultFromAccount != null) {
      if (widget.defaultFromAccount == 'Cash') {
        _transferType = 'Cash to Bank';
      } else {
        _fromBank = widget.defaultFromAccount;
      }
    }
    
    _loadBanks();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final accounts = await isar.bankAccounts.filter().isDeletedEqualTo(false).findAll();
      
      setState(() {
        _bankAccounts = accounts.map((a) => a.accountName ?? '').where((s) => s.isNotEmpty).toList();
        
        if (widget.defaultFromAccount != null) {
          if (widget.defaultFromAccount == 'Cash') {
            _transferType = 'Cash to Bank';
          } else {
            _fromBank = widget.defaultFromAccount;
            if (!_bankAccounts.contains(_fromBank)) {
               _bankAccounts.add(_fromBank!);
            }
          }
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<String?> _uploadImageToImgBB(String imagePath) async {
    try {
      final dio = Dio();
      final file = File(imagePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'key': 'e18b14a6021d7b38573fc0d091fc56ff', // Public Free ImgBB Key
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });

      final response = await dio.post('https://api.imgbb.com/1/upload', data: formData);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data']['url'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    String paymentMode = '';
    String partyName = '';

    if (_transferType == 'Adjustment') {
      if (_fromBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Account Name')));
        return;
      }
      if (_adjustmentType == 'Increase Balance') {
        paymentMode = 'System Adjustment';
        partyName = _fromBank!;
      } else {
        paymentMode = _fromBank!;
        partyName = 'System Adjustment';
      }
    } else if (_transferType == 'Bank to Cash') {
      if (_fromBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select From Bank')));
        return;
      }
      paymentMode = _fromBank!;
      partyName = 'Cash';
    } else if (_transferType == 'Cash to Bank') {
      if (_toBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select To Bank')));
        return;
      }
      paymentMode = 'Cash';
      partyName = _toBank!;
    } else {
      if (_fromBank == null || _toBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select both banks')));
        return;
      }
      if (_fromBank == _toBank) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and target banks cannot be the same')));
        return;
      }
      paymentMode = _fromBank!;
      partyName = _toBank!;
    }

    setState(() => _isSaving = true);
    try {
      String? uploadedImageUrl;
      if (_photoPath != null) {
        uploadedImageUrl = await _uploadImageToImgBB(_photoPath!);
        if (uploadedImageUrl == null) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image to ImgBB, saving without image.')));
        }
      }

      final isar = ref.read(databaseServiceProvider).isar;
      
      final txn = widget.existingTransaction ?? Transaction()
        ..uuid = widget.existingTransaction?.uuid ?? const Uuid().v4()
        ..transactionType = 'Transfer'
        ..amount = amt
        ..transactionDate = _date
        ..paymentMode = paymentMode
        ..partyName = partyName
        ..remarks = _descController.text.trim()
        ..referenceNumber = uploadedImageUrl ?? widget.existingTransaction?.referenceNumber // Storing image url here since it's synced and unused in transfer
        ..createdAt = widget.existingTransaction?.createdAt ?? DateTime.now()
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false;

      await isar.writeTxn(() async {
        final id = await isar.transactions.put(txn);
        final q = SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'Transaction'
          ..entityId = id
          ..entityUuid = txn.uuid
          ..operation = _isEditing ? 'Update' : 'Insert'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      });
      
      ref.read(syncServiceProvider).syncPendingChangesQuietly();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
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
                const Icon(Icons.swap_calls_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Transfer Funds', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Field
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Date: ${DateFormat('dd MMM yyyy').format(_date)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Icon(Icons.edit, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Transfer Type Segmented Button
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Bank to Cash', label: Text('Bank \u2192 Cash'), icon: Icon(Icons.account_balance_wallet)),
                          ButtonSegment(value: 'Cash to Bank', label: Text('Cash \u2192 Bank'), icon: Icon(Icons.account_balance)),
                          ButtonSegment(value: 'Bank to Bank', label: Text('Bank \u2192 Bank'), icon: Icon(Icons.sync_alt)),
                        ],
                        selected: {_transferType},
                        onSelectionChanged: (set) {
                          setState(() {
                            _transferType = set.first;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // From / To Fields
                      if (_transferType == 'Adjustment') ...[
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Increase Balance', label: Text('Increase Balance'), icon: Icon(Icons.add_circle)),
                            ButtonSegment(value: 'Decrease Balance', label: Text('Decrease Balance'), icon: Icon(Icons.remove_circle)),
                          ],
                          selected: {_adjustmentType},
                          onSelectionChanged: (set) => setState(() => _adjustmentType = set.first),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _fromBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Account Name', prefixIcon: Icon(Icons.account_balance)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _fromBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ],
                      if (_transferType == 'Bank to Cash')
                        DropdownButtonFormField<String>(
                          value: _fromBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'From Bank Account', prefixIcon: Icon(Icons.account_balance)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _fromBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        
                      if (_transferType == 'Cash to Bank')
                        DropdownButtonFormField<String>(
                          value: _toBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'To Bank Account', prefixIcon: Icon(Icons.account_balance)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _toBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),

                      if (_transferType == 'Bank to Bank') ...[
                        DropdownButtonFormField<String>(
                          value: _fromBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'From Bank', prefixIcon: Icon(Icons.account_balance_outlined)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _fromBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _toBank,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'To Bank', prefixIcon: Icon(Icons.account_balance)),
                          items: _bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _toBank = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ],

                      const SizedBox(height: 16),
                      
                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (\u20b9)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Remarks',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Photo Attachment
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _photoPath == null ? 'Attach Photo (Optional)' : 'Photo Attached',
                                  style: TextStyle(
                                    color: _photoPath == null ? theme.hintColor : theme.colorScheme.primary,
                                    fontWeight: _photoPath == null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_photoPath != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => setState(() => _photoPath = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_photoPath != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb ? Image.network(_photoPath!, height: 100, fit: BoxFit.cover) : Image.file(File(_photoPath!), height: 100, fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          
          // Sticky Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveTransfer,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Processing...' : 'Transfer Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: isNeu ? 0 : 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: dialogContent,
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: dialogContent,
      ),
    );
  }
}
