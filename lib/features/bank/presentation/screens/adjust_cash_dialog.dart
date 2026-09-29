import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

class AdjustCashDialog extends ConsumerStatefulWidget {
  final String accountName;
  final bool isBank;
  final String? bankUuid;
  const AdjustCashDialog({
    Key? key,
    this.accountName = 'Cash',
    this.isBank = false,
    this.bankUuid,
  }) : super(key: key);

  @override
  ConsumerState<AdjustCashDialog> createState() => _AdjustCashDialogState();
}

class _AdjustCashDialogState extends ConsumerState<AdjustCashDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late String _adjustmentType;
  DateTime _date = DateTime.now();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _photoPath;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _adjustmentType = widget.isBank ? 'Add Bank Balance' : 'Add Cash';
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
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
        'key': 'e18b14a6021d7b38573fc0d091fc56ff',
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });
      final response = await dio.post('https://api.imgbb.com/1/upload', data: formData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? uploadedImageUrl;
      if (_photoPath != null) {
        uploadedImageUrl = await _uploadImageToImgBB(_photoPath!);
        if (uploadedImageUrl == null && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image. Saving without image.')));
        }
      }

      final isar = ref.read(databaseServiceProvider).isar;
      
      String paymentMode = '';
      String partyName = '';
      
      if (_adjustmentType.startsWith('Add')) {
        paymentMode = 'System Adjustment';
        partyName = widget.accountName;
      } else {
        paymentMode = widget.accountName;
        partyName = 'System Adjustment';
      }

      final txn = Transaction()
        ..uuid = const Uuid().v4()
        ..transactionType = 'Transfer'
        ..amount = amt
        ..transactionDate = _date
        ..paymentMode = paymentMode
        ..partyName = partyName
        ..remarks = _descController.text.trim()
        ..referenceNumber = uploadedImageUrl
        ..createdAt = DateTime.now()
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
          ..operation = 'Insert'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      });
      
      ref.read(syncServiceProvider).syncPendingChangesQuietly();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Container(
            padding: EdgeInsets.only(top: isMobile ? MediaQuery.of(context).padding.top + 16 : 16, bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
              borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Adjust Cash', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(child: Text('Date: ${DateFormat('dd MMM yyyy').format(_date)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                            const Icon(Icons.edit, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Add Cash', label: Text('Add Cash'), icon: Icon(Icons.add_circle)),
                        ButtonSegment(value: 'Reduce Cash', label: Text('Reduce Cash'), icon: Icon(Icons.remove_circle)),
                      ],
                      selected: {_adjustmentType},
                      onSelectionChanged: (set) => setState(() => _adjustmentType = set.first),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount (\u20b9)', prefixIcon: Icon(Icons.currency_rupee)),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description / Remarks', prefixIcon: Icon(Icons.notes)),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_photoPath == null ? 'Attach Photo (Optional)' : 'Photo Attached', style: TextStyle(color: _photoPath == null ? theme.hintColor : theme.colorScheme.primary, fontWeight: _photoPath == null ? FontWeight.normal : FontWeight.bold))),
                            if (_photoPath != null) IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setState(() => _photoPath = null)),
                          ],
                        ),
                      ),
                    ),
                    if (_photoPath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: kIsWeb ? Image.network(_photoPath!, height: 100, fit: BoxFit.cover) : Image.file(File(_photoPath!), height: 100, fit: BoxFit.cover)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 16))),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAdjustment,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Processing...' : 'Save', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) return Dialog(insetPadding: EdgeInsets.zero, backgroundColor: Colors.transparent, child: dialogContent);
    return ScaleTransition(scale: _scaleAnimation, child: Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: Colors.transparent, child: dialogContent));
  }
}
