import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_collection.dart';
import 'package:business_sahaj_erp/features/tasks/presentation/providers/machinery_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

class AddEditMachineryScreen extends ConsumerStatefulWidget {
  final int? machineryId;
  const AddEditMachineryScreen({Key? key, this.machineryId}) : super(key: key);

  @override
  ConsumerState<AddEditMachineryScreen> createState() => _AddEditMachineryScreenState();
}

class _AddEditMachineryScreenState extends ConsumerState<AddEditMachineryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _machineNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _googlePhotosLinkController = TextEditingController();
  final _serviceIntervalMonthsController = TextEditingController();
  final _serviceIntervalDaysController = TextEditingController();

  Party? _selectedParty;
  DateTime? _lastServiceDate;
  DateTime? _nextServiceDate;
  Machinery? _existingMachinery;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachinery();
  }

  Future<void> _loadMachinery() async {
    if (widget.machineryId != null) {
      final machinery = await ref.read(machineryProvider).getMachinery(widget.machineryId!);
      if (machinery != null) {
        _existingMachinery = machinery;
        _machineNameController.text = machinery.machineName ?? '';
        _brandNameController.text = machinery.brandName ?? '';
        _modelNumberController.text = machinery.modelNumber ?? '';
        _serialNumberController.text = machinery.serialNumber ?? '';
        _descriptionController.text = machinery.description ?? '';
        _googlePhotosLinkController.text = machinery.googlePhotosLink ?? '';
        _serviceIntervalMonthsController.text = machinery.serviceIntervalMonths?.toString() ?? '';
        _serviceIntervalDaysController.text = machinery.serviceIntervalDays?.toString() ?? '';
        _lastServiceDate = machinery.lastServiceDate;
        _nextServiceDate = machinery.nextServiceDate;

        if (machinery.partyUuid != null) {
          final parties = await ref.read(partyListProvider.future);
          _selectedParty = parties.cast<Party?>().firstWhere(
            (p) => p?.uuid == machinery.partyUuid,
            orElse: () => null,
          );
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _machineNameController.dispose();
    _brandNameController.dispose();
    _modelNumberController.dispose();
    _serialNumberController.dispose();
    _descriptionController.dispose();
    _googlePhotosLinkController.dispose();
    _serviceIntervalMonthsController.dispose();
    _serviceIntervalDaysController.dispose();
    super.dispose();
  }

  void _calculateNextServiceDate() {
    if (_lastServiceDate == null) return;
    
    int months = int.tryParse(_serviceIntervalMonthsController.text) ?? 0;
    int days = int.tryParse(_serviceIntervalDaysController.text) ?? 0;
    
    if (months > 0 || days > 0) {
      setState(() {
        _nextServiceDate = DateTime(_lastServiceDate!.year, _lastServiceDate!.month + months, _lastServiceDate!.day + days);
      });
    }
  }

  Future<void> _saveMachinery() async {
    if (!_formKey.currentState!.validate()) return;
    
    Machinery machinery = _existingMachinery ?? Machinery();
    
    machinery.machineName = _machineNameController.text.trim();
    machinery.partyUuid = _selectedParty?.uuid;
    machinery.brandName = _brandNameController.text.trim();
    machinery.modelNumber = _modelNumberController.text.trim();
    machinery.serialNumber = _serialNumberController.text.trim();
    machinery.description = _descriptionController.text.trim();
    machinery.googlePhotosLink = _googlePhotosLinkController.text.trim();
    machinery.serviceIntervalMonths = int.tryParse(_serviceIntervalMonthsController.text);
    machinery.serviceIntervalDays = int.tryParse(_serviceIntervalDaysController.text);
    machinery.lastServiceDate = _lastServiceDate;
    machinery.nextServiceDate = _nextServiceDate;

    await ref.read(machineryProvider).saveMachinery(machinery);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existingMachinery == null ? 'Machinery Added' : 'Machinery Updated'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  Future<void> _sendReminder() async {
    if (_selectedParty == null || _selectedParty!.phone == null || _selectedParty!.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available.')),
      );
      return;
    }

    String phone = _selectedParty!.phone!;
    if (!phone.startsWith('+')) {
      // Basic assumption for testing, production would need country code selection
      phone = '+91$phone';
    }

    final message = 'Hello ${_selectedParty!.name},\n\nThis is a friendly reminder that the upcoming service for your ${_machineNameController.text} is due on ${DateFormat('dd MMM yyyy').format(_nextServiceDate!)}.\n\nPlease contact us to schedule the service.\n\nThank you!';
    final url = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final partiesAsync = ref.watch(partyListProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: _existingMachinery != null ? 'Edit Machinery' : 'Add Machinery',
        actions: [
          if (_existingMachinery != null && _nextServiceDate != null)
            IconButton(
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Send Reminder',
              onPressed: _sendReminder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              partiesAsync.when(
                data: (parties) {
                  return DropdownButtonFormField<Party>(
                    value: _selectedParty,
                    decoration: const InputDecoration(
                      labelText: 'Customer / Party',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: parties.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.name ?? 'Unknown'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedParty = val),
                    validator: (val) => val == null ? 'Please select a customer' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading parties: $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _machineNameController,
                decoration: const InputDecoration(
                  labelText: 'Machine Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.precision_manufacturing_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandNameController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Model No.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial No.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Service Intervals', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serviceIntervalMonthsController,
                      decoration: const InputDecoration(
                        labelText: 'Months',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateNextServiceDate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _serviceIntervalDaysController,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateNextServiceDate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Last Service Date'),
                subtitle: Text(_lastServiceDate == null ? 'Not set' : DateFormat('EEE, MMM dd, yyyy').format(_lastServiceDate!)),
                trailing: TextButton(
                  child: const Text('Pick Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _lastServiceDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _lastServiceDate = picked;
                      });
                      _calculateNextServiceDate();
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next Service Date'),
                subtitle: Text(_nextServiceDate == null ? 'Not set' : DateFormat('EEE, MMM dd, yyyy').format(_nextServiceDate!)),
                trailing: TextButton(
                  child: const Text('Pick Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _nextServiceDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _nextServiceDate = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveMachinery,
                  child: Text(_existingMachinery == null ? 'Save Machinery' : 'Update Machinery', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
