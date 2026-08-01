import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
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
  bool _isFetchingGst = false;

  List<String> _partyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier'];
  final List<String> _gstTypes = ['Registered', 'Unregistered', 'Composition'];
  final List<String> _balanceTypes = ['Dr', 'Cr'];
  final List<String> _paymentTermsList = ['Cash', 'Net 15', 'Net 30', 'Net 60', 'Due on Receipt'];
  List<String> _categories = ['Retail', 'Wholesale', 'Contractor', 'Manufacturing', 'Services'];
  List<String> _localities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines'];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    _loadCustomPartyTypesAndLocalities();
    if (_isEditMode) {
      _populateFields();
    } else {
      _autoGenerateCode();
    }
  }

  void _loadCustomPartyTypesAndLocalities() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final savedPartyTypes = prefs.getStringList('custom_party_types_list') ?? [];
      final savedLocalities = prefs.getStringList('custom_localities_list') ?? [];
      setState(() {
        _partyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier', ...savedPartyTypes].toSet().toList();
        _localities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines', ...savedLocalities].toSet().toList();
      });
    } catch (_) {}
  }

  Future<void> _showAddPartyTypeDialog() async {
    final typeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Party Type'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Party Type Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Type name is required' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, typeController.text.trim());
                }
              },
              child: const Text('Save Party Type'),
            ),
          ],
        );
      },
    );

    if (newType != null && newType.isNotEmpty) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList('custom_party_types_list') ?? [];
      if (!list.contains(newType)) {
        list.add(newType);
        await prefs.setStringList('custom_party_types_list', list);
      }
      setState(() {
        _partyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier', ...list].toSet().toList();
        _partyType = newType;
      });
    }
  }

  Future<void> _showAddLocalityDialog() async {
    final locController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newLoc = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Locality / Area'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: locController,
              decoration: const InputDecoration(
                labelText: 'Locality Name (e.g. Sector 12, Subhash Nagar)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Locality is required' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, locController.text.trim());
                }
              },
              child: const Text('Add Locality'),
            ),
          ],
        );
      },
    );

    if (newLoc != null && newLoc.isNotEmpty) {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList('custom_localities_list') ?? [];
      if (!list.contains(newLoc)) {
        list.add(newLoc);
        await prefs.setStringList('custom_localities_list', list);
      }
      setState(() {
        _localities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines', ...list].toSet().toList();
        _addressLine2Controller.text = newLoc;
      });
    }
  }

  Future<void> _fetchGstDetails() async {
    final gstin = _gstController.text.trim();
    if (gstin.isEmpty || gstin.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 15-digit GSTIN (e.g. 27AAAAA1111A1Z1)')),
      );
      return;
    }

    setState(() => _isFetchingGst = true);
    try {
      final gstService = ref.read(gstServiceProvider);
      final details = await gstService.fetchPartyDetailsFromGst(gstin);

      if (details != null) {
        setState(() {
          _panController.text = details.panNumber;
          _stateController.text = details.stateName;
          _gstType = details.gstType;

          if (_nameController.text.trim().isEmpty) {
            _nameController.text = details.tradeName;
          }
          if (_addressLine1Controller.text.trim().isEmpty) {
            _addressLine1Controller.text = details.addressLine1;
          }
          if (_cityController.text.trim().isEmpty) {
            _cityController.text = details.city;
          }
          if (_pincodeController.text.trim().isEmpty) {
            _pincodeController.text = details.pincode;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Party details auto-fetched successfully for ${details.stateName}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid GSTIN format. Please check entry.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch GST details: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFetchingGst = false);
    }
  }

  void _loadCustomCategories() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getStringList('party_business_categories');
      if (saved != null && saved.isNotEmpty) {
        final set = Set<String>.from(_categories)..addAll(saved);
        setState(() {
          _categories = set.toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Business Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Distributor, Textile, Pharma',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCat = controller.text.trim();
              if (newCat.isNotEmpty) {
                if (!_categories.contains(newCat)) {
                  _categories.add(newCat);
                  final prefs = ref.read(sharedPreferencesProvider);
                  await prefs.setStringList('party_business_categories', _categories);
                }
                setState(() {
                  _category = newCat;
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _partyTypes.contains(_partyType) ? _partyType : _partyTypes.first,
                                decoration: const InputDecoration(labelText: 'Party Type *', border: OutlineInputBorder()),
                                items: _partyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _partyType = val);
                                    if (!_isEditMode) _autoGenerateCode();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.add),
                              tooltip: 'Create New Party Type',
                              onPressed: _showAddPartyTypeDialog,
                            ),
                          ],
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
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number (10 Digits)',
                            prefixIcon: Icon(Icons.phone),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && value.length != 10) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Number (10 Digits)',
                            prefixIcon: Icon(Icons.chat_bubble_outline),
                            counterText: '',
                          ),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _gstController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN (GST Number)',
                                  prefixIcon: Icon(Icons.receipt),
                                  hintText: 'e.g. 27AAAAA1111A1Z1',
                                ),
                                onChanged: (val) {
                                  if (val.trim().length == 15 && !_isFetchingGst) {
                                    _fetchGstDetails();
                                  }
                                },
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final gstRegExp = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$');
                                    if (!gstRegExp.hasMatch(value.toUpperCase())) {
                                      return 'Enter a valid GSTIN format (e.g. 27AAAAA1111A1Z1)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isFetchingGst ? null : _fetchGstDetails,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              icon: _isFetchingGst
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.bolt, color: Colors.amber),
                              label: const Text('Auto-Fetch'),
                            ),
                          ],
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
                          decoration: const InputDecoration(labelText: 'Address Line 1 (Shop/Building/Street)', prefixIcon: Icon(Icons.location_on)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Autocomplete<String>(
                                initialValue: TextEditingValue(text: _addressLine2Controller.text),
                                optionsBuilder: (textEditingValue) {
                                  if (textEditingValue.text.isEmpty) return _localities;
                                  return _localities.where((loc) => loc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                },
                                onSelected: (val) {
                                  _addressLine2Controller.text = val;
                                },
                                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                  if (_addressLine2Controller.text != controller.text && controller.text.isNotEmpty) {
                                    _addressLine2Controller.text = controller.text;
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onEditingComplete: onEditingComplete,
                                    onChanged: (v) => _addressLine2Controller.text = v,
                                    decoration: const InputDecoration(
                                      labelText: 'Locality / Area / Landmark',
                                      prefixIcon: Icon(Icons.location_city),
                                      border: OutlineInputBorder(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.add_location_alt_outlined),
                              tooltip: 'Add New Locality',
                              onPressed: _showAddLocalityDialog,
                            ),
                          ],
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _categories.contains(_category) ? _category : _categories.first,
                                decoration: const InputDecoration(
                                  labelText: 'Business Category',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _category = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(Icons.add),
                              tooltip: 'Add Custom Category',
                            ),
                          ],
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
