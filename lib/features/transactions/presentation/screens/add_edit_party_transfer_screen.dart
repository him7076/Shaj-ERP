import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../data/local/collections/party_collection.dart';
import '../../../../data/local/collections/transaction_collection.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../presentation/providers/transaction_providers.dart';
import '../../../../core/widgets/searchable_party_dropdown.dart';

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

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
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
        // Voucher number is generated in repository for 'Transfer'
      }

      txn.transactionType = 'Transfer';
      txn.transactionDate = _date;
      txn.amount = amount;
      txn.remarks = _remarksController.text;

      txn.partyUuid = _fromParty!.uuid;
      txn.partyName = _fromParty!.partyName;
      txn.targetPartyUuid = _toParty!.uuid;
      txn.targetPartyName = _toParty!.partyName;
      
      // Update tags for image
      List<String> currentTags = txn.tags?.where((t) => !t.startsWith('IMG:')).toList() ?? [];
      if (_imagePath != null) {
        currentTags.add('IMG:$_imagePath');
      }
      txn.tags = currentTags.isEmpty ? null : currentTags;

      if (!isEdit) {
        await ref.read(transactionRepositoryProvider).saveTransaction(txn);
      } else {
        await ref.read(transactionRepositoryProvider).saveTransaction(txn);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final partiesAsync = ref.watch(partiesListProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.existingTransaction != null ? 'Edit Party Transfer' : 'New Party Transfer'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: partiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (parties) {
            
            if (_fromParty == null && widget.existingTransaction != null && widget.existingTransaction!.partyUuid != null) {
              try {
                _fromParty = parties.firstWhere((p) => p.uuid == widget.existingTransaction!.partyUuid);
              } catch (_) {}
            }
            if (_toParty == null && widget.existingTransaction != null && widget.existingTransaction!.targetPartyUuid != null) {
              try {
                _toParty = parties.firstWhere((p) => p.uuid == widget.existingTransaction!.targetPartyUuid);
              } catch (_) {}
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD 1: Voucher Details
                  NeuCard(
margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_date),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Voucher Number',
                              hintText: widget.existingTransaction?.transactionNumber ?? 'Auto-Generated',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CARD 2: Transfer Details
                  NeuCard(
margin: const EdgeInsets.symmetric(vertical: 4),
child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Transfer Between Parties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        
                        // FROM PARTY
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.red.withOpacity(0.05),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FROM (Giver)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              SearchablePartyDropdown(
                                parties: parties,
                                selectedParty: _fromParty,
                                labelText: 'Select From Party',
                                onChanged: (p) => setState(() => _fromParty = p),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Amount Deducted',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                ),
                                onChanged: (val) {
                                  _amountController.text = val;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Icon(Icons.arrow_downward_rounded, color: Colors.grey),
                          ),
                        ),

                        // TO PARTY
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green.withOpacity(0.05),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TO (Receiver)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              SearchablePartyDropdown(
                                parties: parties,
                                selectedParty: _toParty,
                                labelText: 'Select To Party',
                                onChanged: (p) => setState(() => _toParty = p),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Amount Received',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                ),
                                onChanged: (val) {
                                  _amountController.text = val;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        // AMOUNT
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'Transfer Amount',
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.blue[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CARD 3: Additional Details & Photo
                  NeuCard(
margin: const EdgeInsets.symmetric(vertical: 4),
child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Additional Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _remarksController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Remarks / Description',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        if (_imagePath != null)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb ? Image.network(_imagePath!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ) : Image.file(File(_imagePath!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              IconButton(
                                onPressed: _removeImage,
                                icon: const Icon(Icons.cancel),
                                color: Colors.red,
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            )
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SAVE TRANSFER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
