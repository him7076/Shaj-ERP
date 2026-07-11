import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class AddEditPartyScreen extends ConsumerStatefulWidget {
  final Party? party;

  const AddEditPartyScreen({
    Key? key,
    this.party,
  }) : super(key: key);

  @override
  ConsumerState<AddEditPartyScreen> createState() => _AddEditPartyScreenState();
}

class _AddEditPartyScreenState extends ConsumerState<AddEditPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditMode => widget.party != null;

  // Form Fields Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _dueDaysController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _notesController = TextEditingController();

  String _partyType = 'Customer';
  String _gstType = 'Unregistered';
  String _balanceType = 'Dr';
  String _paymentTerms = 'Cash';
  String _category = 'Retail';

  bool _isSaving = false;

  final List<String> _partyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier'];
  final List<String> _gstTypes = ['Registered', 'Unregistered', 'Composition'];
  final List<String> _balanceTypes = ['Dr', 'Cr'];
  final List<String> _paymentTermsList = ['Cash', 'Net 15', 'Net 30', 'Net 60', 'Due on Receipt'];
  final List<String> _categories = ['Retail', 'Wholesale', 'Contractor', 'Manufacturing', 'Services'];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields();
    } else {
      _autoGenerateCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    _dueDaysController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final p = widget.party!;
    _nameController.text = p.partyName ?? '';
    _codeController.text = p.partyCode ?? '';
    _mobileController.text = p.mobileNumber ?? '';
    _whatsappController.text = p.whatsappNumber ?? '';
    _emailController.text = p.email ?? '';
    _gstController.text = p.gstNumber ?? '';
    _panController.text = p.panNumber ?? '';
    _addressLine1Controller.text = p.addressLine1 ?? '';
    _addressLine2Controller.text = p.addressLine2 ?? '';
    _cityController.text = p.city ?? '';
    _stateController.text = p.state ?? '';
    _pincodeController.text = p.pincode ?? '';
    _openingBalanceController.text = p.openingBalance?.toString() ?? '0';
    _creditLimitController.text = p.creditLimit?.toString() ?? '0';
    _dueDaysController.text = p.dueDays?.toString() ?? '30';
    _contactPersonController.text = p.contactPerson ?? '';
    _notesController.text = p.notes ?? '';

    _partyType = p.partyType ?? 'Customer';
    _gstType = p.gstType ?? 'Unregistered';
    _balanceType = p.balanceType ?? 'Dr';
    _paymentTerms = p.paymentTerms ?? 'Cash';
    _category = p.businessCategory ?? 'Retail';
  }

  Future<void> _autoGenerateCode() async {
    try {
      final repo = ref.read(partyRepositoryProvider);
      final code = await repo.generateNextPartyCode(_partyType);
      setState(() {
        _codeController.text = code;
      });
    } catch (e) {
      logger.error('Failed to auto generate party code', e);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(partyRepositoryProvider);
      
      final gst = _gstController.text.trim();
      final mobile = _mobileController.text.trim();
      final excludeId = widget.party?.id;

      // 1. Validate GST Unique Check (Skip if empty)
      if (gst.isNotEmpty) {
        final uniqueGst = await repo.isGstNumberUnique(gst, excludeId: excludeId);
        if (!uniqueGst) {
          throw DuplicatePartyException('GSTIN "$gst" is already registered to another active party.');
        }
      }

      // 2. Validate Mobile Unique Check (Skip if empty)
      if (mobile.isNotEmpty) {
        final uniqueMobile = await repo.isMobileNumberUnique(mobile, excludeId: excludeId);
        if (!uniqueMobile) {
          throw DuplicatePartyException('Mobile Number "$mobile" is already registered to another active party.');
        }
      }

      // Create or populate entity details
      final Party party = widget.party ?? Party();
      party.partyName = _nameController.text.trim();
      party.partyCode = _codeController.text.trim();
      party.partyType = _partyType;
      party.mobileNumber = mobile;
      party.whatsappNumber = _whatsappController.text.trim();
      party.email = _emailController.text.trim();
      party.gstNumber = gst;
      party.panNumber = _panController.text.trim();
      party.gstType = _gstType;
      party.addressLine1 = _addressLine1Controller.text.trim();
      party.addressLine2 = _addressLine2Controller.text.trim();
      party.city = _cityController.text.trim();
      party.state = _stateController.text.trim();
      party.pincode = _pincodeController.text.trim();
      party.openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
      party.balanceType = _balanceType;
      party.creditLimit = double.tryParse(_creditLimitController.text) ?? 0.0;
      party.paymentTerms = _paymentTerms;
      party.dueDays = int.tryParse(_dueDaysController.text) ?? 30;
      party.contactPerson = _contactPersonController.text.trim();
      party.businessCategory = _category;
      party.notes = _notesController.text.trim();

      if (_isEditMode) {
        await repo.update(party);
        logger.info('Party profile updated.');
      } else {
        await repo.create(party);
        logger.info('New party created.');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Party profile saved successfully.')),
        );
      }
    } catch (e) {
      ErrorDialog.show(context, title: 'Validation/Database Error', message: e.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Party Profile' : 'New Party Profile'),
        actions: [
          IconButton(
            tooltip: 'Save Profile',
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _submitForm,
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Section 1: Basic Info
                    _buildFormSection(
                      title: 'Basic Information',
                      children: [
                        DropdownButtonFormField<String>(
                          value: _partyType,
                          decoration: const InputDecoration(labelText: 'Party Type *'),
                          items: _partyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _partyType = val;
                              });
                              if (!_isEditMode) {
                                _autoGenerateCode();
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(labelText: 'Party Code (Auto Generated)'),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Party Name *', prefixIcon: Icon(Icons.person)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter party name';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Contact
                    _buildFormSection(
                      title: 'Contact Information',
                      children: [
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && value.length < 10) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'WhatsApp Number', prefixIcon: Icon(Icons.chat_bubble_outline)),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !value.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: GST Details
                    _buildFormSection(
                      title: 'GST & TAX Details',
                      children: [
                        DropdownButtonFormField<String>(
                          value: _gstType,
                          decoration: const InputDecoration(labelText: 'GST Type'),
                          items: _gstTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _gstType = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _gstController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'GSTIN (GST Number)', prefixIcon: Icon(Icons.receipt)),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              // Regex for standard Indian GST number validation
                              final gstRegExp = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$');
                              if (!gstRegExp.hasMatch(value.toUpperCase())) {
                                return 'Enter a valid GSTIN format (e.g. 27AAAAA1111A1Z1)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _panController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'PAN Number'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Address
                    _buildFormSection(
                      title: 'Billing Address',
                      children: [
                        TextFormField(
                          controller: _addressLine1Controller,
                          decoration: const InputDecoration(labelText: 'Address Line 1', prefixIcon: Icon(Icons.location_on)),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressLine2Controller,
                          decoration: const InputDecoration(labelText: 'Address Line 2'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(labelText: 'City'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(labelText: 'State'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Pincode'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 5: Accounting
                    _buildFormSection(
                      title: 'Accounting & Credit Settings',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextFormField(
                                controller: _openingBalanceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: '₹'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _balanceType,
                                decoration: const InputDecoration(labelText: 'Type'),
                                items: _balanceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _balanceType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _creditLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Credit Limit Amount', prefixText: '₹'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _paymentTerms,
                          decoration: const InputDecoration(labelText: 'Payment Terms'),
                          items: _paymentTermsList.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentTerms = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dueDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Payment Due Days'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 6: Business Details
                    _buildFormSection(
                      title: 'Business Information',
                      children: [
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(labelText: 'Contact Person Name'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(labelText: 'Business Category'),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _category = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Business Notes & Reminders'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(
                        _isEditMode ? 'Update Party Profile' : 'Create Party Profile',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
