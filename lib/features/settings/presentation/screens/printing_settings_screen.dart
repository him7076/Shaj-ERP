import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';

class PrintingSettingsScreen extends ConsumerStatefulWidget {
  const PrintingSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrintingSettingsScreen> createState() => _PrintingSettingsScreenState();
}

class _PrintingSettingsScreenState extends ConsumerState<PrintingSettingsScreen> {
  bool _isThermalPrinter = false;
  String _paperSize = '58mm';
  late SharedPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _isThermalPrinter = _prefs.getBool('use_thermal_printer') ?? false;
      _paperSize = _prefs.getString('thermal_paper_size') ?? '58mm';
      _isLoading = false;
    });
  }

  Future<void> _saveThermalToggle(bool val) async {
    setState(() => _isThermalPrinter = val);
    await _prefs.setBool('use_thermal_printer', val);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? 'Thermal Printer mode enabled.' : 'Normal Printer mode enabled.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _savePaperSize(String val) async {
    setState(() => _paperSize = val);
    await _prefs.setString('thermal_paper_size', val);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paper size set to $val'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printing Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeuCard(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.print, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Printer Type',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select the type of printer you are using to print invoices. Thermal printers use continuous rolls, while normal printers use A4/A5 sheets.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        
                        SwitchListTile(
                          title: const Text('Use Thermal Printer', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Toggle to enable thermal receipt printing format (like Nukkad Cafe).'),
                          value: _isThermalPrinter,
                          onChanged: _saveThermalToggle,
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        if (_isThermalPrinter) ...[
                          const Divider(height: 32),
                          Text(
                            'Thermal Paper Size',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('58mm (2 inch)'),
                                  value: '58mm',
                                  groupValue: _paperSize,
                                  onChanged: (val) => _savePaperSize(val!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('80mm (3 inch)'),
                                  value: '80mm',
                                  groupValue: _paperSize,
                                  onChanged: (val) => _savePaperSize(val!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
