import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/widgets/modern_form_section.dart';
import 'package:business_sahaj_erp/core/widgets/modern_text_field.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';

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
      final List<String> defaultPartyTypes = ['Customer', 'Retailer', 'Wholesaler', 'Distributor', 'Supplier'];
      final List<String> defaultLocalities = ['Main Market', 'Ring Road', 'Industrial Area', 'Civil Lines'];

      final savedPartyTypes = prefs.getStringList('custom_party_types_list');
      final savedLocalities = prefs.getStringList('custom_localities_list');

      setState(() {
        _partyTypes = savedPartyTypes ?? defaultPartyTypes;
        _localities = savedLocalities ?? defaultLocalities;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      final list = prefs.getStringList('custom_party_types_list') ?? List<String>.from(_partyTypes);
      if (!list.contains(newType)) {
        list.add(newType);
        await prefs.setStringList('custom_party_types_list', list);
      }
      setState(() {
        _partyTypes = list;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      final list = prefs.getStringList('custom_localities_list') ?? List<String>.from(_localities);
      if (!list.contains(newLoc)) {
        list.add(newLoc);
        await prefs.setStringList('custom_localities_list', list);
      }
      setState(() {
        _localities = list;
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

      if (details != null && mounted) {
        final confirmFill = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.verified_outlined, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('GST Taxpayer Details Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verified GST taxpayer information retrieved. Review before auto-filling:'),
                  const SizedBox(height: 12),
                  _buildPreviewRow('Trade Name:', details.tradeName),
                  _buildPreviewRow('Legal Name:', details.legalName.isNotEmpty ? details.legalName : details.tradeName),
                  _buildPreviewRow('GSTIN:', details.gstin),
                  _buildPreviewRow('PAN Number:', details.panNumber),
                  _buildPreviewRow('Entity Type:', details.entityType),
                  _buildPreviewRow('State & Code:', '${details.stateName} (${details.stateCode})'),
                  _buildPreviewRow('Address:', details.addressLine1),
                  _buildPreviewRow('City:', details.city),
                  _buildPreviewRow('Pincode:', details.pincode),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.bolt),
                label: const Text('Auto-Fill Form Data'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
              ),
            ],
          ),
        );

        if (confirmFill == true && mounted) {
          setState(() {
            _nameController.text = details.tradeName.isNotEmpty ? details.tradeName : details.legalName;
            _contactPersonController.text = details.legalName;
            _panController.text = details.panNumber;
            _stateController.text = details.stateName;
            _addressLine1Controller.text = details.addressLine1;
            _cityController.text = details.city;
            _pincodeController.text = details.pincode;
            _gstType = 'Registered';
            if (details.entityType.isNotEmpty && !_categories.contains(details.entityType)) {
              _categories.add(details.entityType);
              _category = details.entityType;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Form auto-filled with GST taxpayer details for ${details.tradeName}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not retrieve GST details for this number. Check GSTIN entry.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch GST details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGst = false);
    }
  }

  Widget _buildPreviewRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 95, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(val.isNotEmpty ? val : 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final cat = controller.text.trim();
              if (cat.isNotEmpty) {
                final prefs = ref.read(sharedPreferencesProvider);
                final list = prefs.getStringList('party_business_categories') ?? [];
                if (!list.contains(cat)) list.add(cat);
                await prefs.setStringList('party_business_categories', list);

                setState(() {
                  if (!_categories.contains(cat)) _categories.add(cat);
                  _category = cat;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Category'),
          ),
        ],
      ),
    );
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
    _openingBalanceController.text = (p.openingBalance ?? 0.0).toString();
    _creditLimitController.text = (p.creditLimit ?? 0.0).toString();
    _dueDaysController.text = (p.dueDays ?? 0).toString();
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
      if (gst.isNotEmpty && _gstType == 'Unregistered') {
        _gstType = 'Registered';
      }

      final party = widget.party ?? Party();
      party.partyName = _nameController.text.trim();
      party.partyCode = _codeController.text.trim();
      party.partyType = _partyType;
      party.mobileNumber = _mobileController.text.trim();
      party.whatsappNumber = _whatsappController.text.trim();
      party.email = _emailController.text.trim();
      party.gstType = _gstType;
      party.gstNumber = gst;
      party.panNumber = _panController.text.trim();
      party.addressLine1 = _addressLine1Controller.text.trim();
      party.addressLine2 = _addressLine2Controller.text.trim();
      party.city = _cityController.text.trim();
      party.state = _stateController.text.trim();
      party.pincode = _pincodeController.text.trim();
      party.openingBalance = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
      party.balanceType = _balanceType;
      party.creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;
      party.paymentTerms = _paymentTerms;
      party.dueDays = int.tryParse(_dueDaysController.text.trim()) ?? 0;
      party.contactPerson = _contactPersonController.text.trim();
      party.businessCategory = _category;
      party.notes = _notesController.text.trim();
      party.updatedAt = DateTime.now();

      if (_isEditMode) {
        await repo.update(party);
      } else {
        await repo.create(party);
      }

      ref.invalidate(partiesListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Party profile saved successfully.')),
        );
      }
    } catch (e) {
      ErrorDialog.show(context, title: 'Validation Error', message: e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partyName = _nameController.text.trim();
    final initials = partyName.isNotEmpty ? partyName.substring(0, 1).toUpperCase() : 'P';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Party Profile' : 'New Party Registration', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Next-Gen Hero Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white24,
                                  child: Text(initials, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        partyName.isNotEmpty ? partyName : 'Enter Party Name Below',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                                            child: Text('Code: ${_codeController.text}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                                            child: Text(_partyType, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ⚡ Prominent 1-Click GSTIN Auto-Fetch Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                            ),
                            color: Colors.amber.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.bolt, color: Colors.amber, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        '1-Click Auto-Fetch Details from GSTIN',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Enter 15-digit GSTIN below to instantly auto-fill Party Name, Address, City, State & PAN details.',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _gstController,
                                          textCapitalization: TextCapitalization.characters,
                                          decoration: const InputDecoration(
                                            labelText: 'GSTIN (GST Number)',
                                            prefixIcon: Icon(Icons.receipt_long),
                                            hintText: 'e.g. 27AAAAA1111A1Z1',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            if (val.trim().length == 15 && !_isFetchingGst) {
                                              _fetchGstDetails();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _isFetchingGst ? null : _fetchGstDetails,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                          backgroundColor: Colors.amber.shade800,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: _isFetchingGst
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.bolt),
                                        label: const Text('Auto-Fetch', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section 1: Basic Info
                          _buildFormSection(
                            title: 'Basic Information',
                            icon: Icons.person_outline,
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
                                decoration: const InputDecoration(labelText: 'Party Code (Auto Generated)', border: OutlineInputBorder()),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Party Trade Name *', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                                onChanged: (_) => setState(() {}),
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
                            icon: Icons.phone_outlined,
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
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
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
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Section 3: GST & Tax Details
                          _buildFormSection(
                            title: 'Taxation & PAN Credentials',
                            icon: Icons.shield_outlined,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _gstType,
                                decoration: const InputDecoration(labelText: 'GST Type', border: OutlineInputBorder()),
                                items: _gstTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _gstType = val);
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _panController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(labelText: 'PAN Number (Permanent Account Number)', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Section 4: Address
                          _buildFormSection(
                            title: 'Billing & Office Address',
                            icon: Icons.location_on_outlined,
                            children: [
                              TextFormField(
                                controller: _addressLine1Controller,
                                decoration: const InputDecoration(labelText: 'Address Line 1 (Shop/Building/Street)', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
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
                                      decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _stateController,
                                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pincodeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Section 5: Accounting
                          _buildFormSection(
                            title: 'Accounting & Credit Limits',
                            icon: Icons.account_balance_outlined,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: TextFormField(
                                      controller: _openingBalanceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: '₹ ', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      value: _balanceType,
                                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
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
                                decoration: const InputDecoration(labelText: 'Credit Limit Amount', prefixText: '₹ ', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _paymentTerms,
                                decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
                                items: _paymentTermsList.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _paymentTerms = val);
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _dueDaysController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Payment Due Days', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Section 6: Business Details
                          _buildFormSection(
                            title: 'Business Category & Notes',
                            icon: Icons.notes_outlined,
                            children: [
                              TextFormField(
                                controller: _contactPersonController,
                                decoration: const InputDecoration(labelText: 'Contact Person Name', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _categories.contains(_category) ? _category : _categories.first,
                                      decoration: const InputDecoration(labelText: 'Business Category', border: OutlineInputBorder()),
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
                                decoration: const InputDecoration(labelText: 'Business Notes & Reminders', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Sticky Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isEditMode ? 'Update Party Profile' : 'Save Party Profile',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ModernFormSection(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

