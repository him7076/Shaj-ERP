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
  bool _enableSubItems = false;

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
      _enableSubItems = prefs.getBool('enable_sub_items') ?? false;
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

  Future<void> _toggleSubItems(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('enable_sub_items', value);
    setState(() {
      _enableSubItems = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? 'Sub-Items Management Enabled' 
              : 'Sub-Items Management Disabled'
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
          // 1. Transaction Settings
          Text(
            'Transaction Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-fill Paid Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Automatically check the "Paid Amount" box and fill the grand total in all new Sales/Purchase transactions.', style: TextStyle(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
                  ),
                  value: _isAutoFillPaidAmount,
                  onChanged: (val) async {
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('auto_fill_paid_amount', val);
                    setState(() { _isAutoFillPaidAmount = val; });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(val ? 'Auto-fill Paid Amount ENABLED' : 'Auto-fill Paid Amount DISABLED'),
                        backgroundColor: val ? Colors.green : Colors.redAccent,
                      ));
                    }
                  },
                  activeColor: Colors.orange,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Restaurant Mode (POS)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable Point of Sale (POS) layout for fast billing. Shows product cards and categories instead of standard search form.', style: TextStyle(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.restaurant_menu_rounded, color: Colors.pink),
                  ),
                  value: _enableRestaurantMode,
                  onChanged: _toggleRestaurantMode,
                  activeColor: Colors.pink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Warnings
          Text(
            'Warnings & Alerts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setCardState) {
              final prefs = ref.watch(sharedPreferencesProvider);
              final bool negStock = prefs.getBool('enable_negative_stock_warning') ?? true;
              final bool creditLimit = prefs.getBool('enable_credit_limit_warning') ?? true;
              final bool lowStock = prefs.getBool('enable_low_stock_alert') ?? true;
              final bool dupCheck = prefs.getBool('enable_duplicate_bill_no_check') ?? true;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Negative Stock Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Show warning prompt when selling items with zero or insufficient inventory stock.', style: TextStyle(fontSize: 12)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      ),
                      value: negStock,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        await prefs.setBool('enable_negative_stock_warning', val);
                        setCardState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Credit Limit Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Warn when customer outstanding balance exceeds allowed credit limit.', style: TextStyle(fontSize: 12)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.deepPurple),
                      ),
                      value: creditLimit,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        await prefs.setBool('enable_credit_limit_warning', val);
                        setCardState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Low Stock Badge Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Highlight items reaching reorder stock levels in catalog lists.', style: TextStyle(fontSize: 12)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.blue),
                      ),
                      value: lowStock,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        await prefs.setBool('enable_low_stock_alert', val);
                        setCardState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Duplicate Invoice / Bill Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Alert when entering a reference bill number that already exists.', style: TextStyle(fontSize: 12)),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_rounded, color: Colors.teal),
                      ),
                      value: dupCheck,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        await prefs.setBool('enable_duplicate_bill_no_check', val);
                        setCardState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Item Settings
          Text(
            'Item Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Bundle Item Management', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable this to create combo items or recipes. When a bundle is sold, its constituent items will be automatically deducted from inventory.', style: TextStyle(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.extension_rounded, color: Colors.amber),
                  ),
                  value: _enableBundleManagement,
                  onChanged: _toggleBundleManagement,
                  activeColor: Colors.amber,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Manage Sub-Items (Flavors/Variants)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable creating sub-items within an item (e.g., Tandoori Burger inside Burger) with separate prices and photos.', style: TextStyle(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fastfood_rounded, color: Colors.purple),
                  ),
                  value: _enableSubItems,
                  onChanged: _toggleSubItems,
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
