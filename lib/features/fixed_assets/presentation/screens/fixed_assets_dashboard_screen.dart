import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/providers/fixed_asset_providers.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/screens/add_fixed_asset_screen.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/screens/depreciation_form_screen.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/screens/sell_fixed_asset_screen.dart';

class FixedAssetsDashboardScreen extends ConsumerWidget {
  const FixedAssetsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assetsAsync = ref.watch(fixedAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Assets Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFixedAssetScreen()),
              ).then((_) => ref.refresh(fixedAssetsProvider));
            },
          ),
        ],
      ),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const Center(child: Text('No fixed assets found. Add a new one to begin tracking.'));
          }
          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.domain),
                  title: Text(asset.assetName ?? 'Unknown Asset', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Type: ${asset.assetType ?? 'N/A'} | Cost: ₹${asset.purchaseCost.toStringAsFixed(2)} | Book Value: ₹${asset.bookValue.toStringAsFixed(2)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: asset.status == 'Sold' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asset.status ?? 'Active',
                      style: TextStyle(
                        color: asset.status == 'Sold' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (asset.status == 'Sold') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset is already disposed/sold.')));
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.trending_down),
                              title: const Text('Book Depreciation'),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DepreciationFormScreen(asset: asset)),
                                ).then((_) => ref.refresh(fixedAssetsProvider));
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.sell, color: Colors.orange),
                              title: const Text('Sell / Dispose Asset'),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SellFixedAssetScreen(asset: asset)),
                                ).then((_) => ref.refresh(fixedAssetsProvider));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFixedAssetScreen()),
          ).then((_) => ref.refresh(fixedAssetsProvider));
        },
        icon: const Icon(Icons.add),
        label: const Text('Purchase Asset'),
      ),
    );
  }
}
