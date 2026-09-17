import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class OtherFeaturesScreen extends ConsumerStatefulWidget {
  const OtherFeaturesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OtherFeaturesScreen> createState() => _OtherFeaturesScreenState();
}

class _OtherFeaturesScreenState extends ConsumerState<OtherFeaturesScreen> {
  bool _enableBundleManagement = false;
  bool _enableRestaurantMode = false;
  bool _isAutoFillPaidAmount = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _enableBundleManagement = prefs.getBool('enable_bundle_management') ?? false;
      _enableRestaurantMode = prefs.getBool('enable_restaurant_mode') ?? false;
      _isAutoFillPaidAmount = prefs.getBool('auto_fill_paid_amount') ?? false;
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

  Future<void> _toggleRestaurantMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('enable_restaurant_mode', value);
    setState(() {
      _enableRestaurantMode = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? 'Restaurant Mode Enabled' 
              : 'Restaurant Mode Disabled'
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
      appBar: AppBar(
        title: const Text('Other Features'),
        centerTitle: true,
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
          const SizedBox(height: 16),
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
                'Restaurant Mode (POS)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Enable Point of Sale (POS) layout for fast billing. Shows product cards and categories instead of standard search form.',
                style: TextStyle(fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Colors.pink),
              ),
              value: _enableRestaurantMode,
              onChanged: _toggleRestaurantMode,
              activeColor: Colors.pink,
            ),
          ),
          const SizedBox(height: 16),
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
                'Transaction Settings (Auto-fill Paid Amount)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Automatically check the "Paid Amount" box and fill the grand total in all new Sales/Purchase transactions.',
                style: TextStyle(fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
              ),
              value: _isAutoFillPaidAmount,
              onChanged: (val) async {
                final prefs = ref.read(sharedPreferencesProvider);
                await prefs.setBool('auto_fill_paid_amount', val);
                setState(() {
                  _isAutoFillPaidAmount = val;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Auto-fill Paid Amount ENABLED' : 'Auto-fill Paid Amount DISABLED'),
                      backgroundColor: val ? Colors.green : Colors.redAccent,
                    ),
                  );
                }
              },
              activeColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
