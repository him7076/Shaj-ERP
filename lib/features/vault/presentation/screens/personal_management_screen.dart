import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalManagementScreen extends ConsumerWidget {
  const PersonalManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Vault Hub'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.business_rounded, size: 18),
              label: const Text('Switch to Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
                context.go('/dashboard');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Management & Planning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Personal Tasks',
              subtitle: 'Manage your daily personal to-dos',
              icon: Icons.checklist_rounded,
              color: Colors.blue,
              onTap: () => context.push('/tasks'),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Accounts Management',
              subtitle: 'Manage personal accounts and balances',
              icon: Icons.account_balance_rounded,
              color: Colors.teal,
              onTap: () => context.push('/personal-accounts'),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Personal Categories',
              subtitle: 'Tag incomes and expenses',
              icon: Icons.category_rounded,
              color: Colors.purple,
              // Note: There is no standalone category screen currently wired in the router,
              // but it's typically managed in settings or items. We can route to settings or item categories.
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Categories management coming soon!')),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Transaction History',
              subtitle: 'View all personal income and expenses',
              icon: Icons.history_rounded,
              color: Colors.orange,
              onTap: () => context.push('/transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeuCard(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
