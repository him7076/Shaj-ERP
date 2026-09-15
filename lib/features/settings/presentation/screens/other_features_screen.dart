import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';

class OtherFeaturesScreen extends ConsumerStatefulWidget {
  const OtherFeaturesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OtherFeaturesScreen> createState() => _OtherFeaturesScreenState();
}

class _OtherFeaturesScreenState extends ConsumerState<OtherFeaturesScreen> {
  bool _enableBundleManagement = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _enableBundleManagement = prefs.getBool('enable_bundle_management') ?? false;
    });
  }

  Future<void> _toggleBundleManagement(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('enable_bundle_management', value);
    setState(() {
      _enableBundleManagement = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? 'Bundle Item Management Enabled' 
              : 'Bundle Item Management Disabled'
          ),
          backgroundColor: value ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Other Features',
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              title: const Text(
                'Bundle Item Management',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Enable this to create combo items or recipes. When a bundle is sold, its constituent items will be automatically deducted from inventory.',
                style: TextStyle(fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.extension_rounded, color: Colors.orange),
              ),
              value: _enableBundleManagement,
              onChanged: _toggleBundleManagement,
              activeColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
