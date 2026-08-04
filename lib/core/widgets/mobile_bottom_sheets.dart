import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileBottomSheets {
  /// Shows a modern, thumb-friendly Quick Create Bottom Sheet for Mobile & Tablet.
  static Future<void> showQuickCreate(BuildContext context) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Create',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Options Grid (2 Columns, 48px+ Touch Height Cards)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildQuickActionTile(
                    context,
                    title: 'Sales Invoice',
                    subtitle: 'Create bill',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/sales?create=true');
                    },
                  ),
                  _buildQuickActionTile(
                    context,
                    title: 'Purchase Bill',
                    subtitle: 'Inward entry',
                    icon: Icons.shopping_bag_rounded,
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/purchases?create=true');
                    },
                  ),
                  _buildQuickActionTile(
                    context,
                    title: 'Payment In (Receipt)',
                    subtitle: 'Receive cash/upi',
                    icon: Icons.south_west_rounded,
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/receipts?create=true');
                    },
                  ),
                  _buildQuickActionTile(
                    context,
                    title: 'Payment Out',
                    subtitle: 'Pay supplier',
                    icon: Icons.north_east_rounded,
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/payments?create=true');
                    },
                  ),
                  _buildQuickActionTile(
                    context,
                    title: 'Sales Order',
                    subtitle: 'Advance order',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/orders?create=true');
                    },
                  ),
                  _buildQuickActionTile(
                    context,
                    title: 'Direct Expense',
                    subtitle: 'Tea, fuel, etc.',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/expenses?create=true');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildQuickActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
