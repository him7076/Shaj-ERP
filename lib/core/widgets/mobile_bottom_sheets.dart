import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileBottomSheets {
  /// Shows a modern, thumb-friendly Quick Create Bottom Sheet featuring ALL Transaction Types.
  static Future<void> showQuickCreate(BuildContext context) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_circle_rounded, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create Transaction / Voucher',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Options Grid (Scrollable 2 Columns for All Shortcuts)
              Flexible(
                child: SingleChildScrollView(
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      _buildQuickActionTile(
                        context,
                        title: 'Sales Invoice',
                        subtitle: 'Direct tax bill',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF0EA5E9),
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
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/purchases?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Payment In',
                        subtitle: 'Receive money',
                        icon: Icons.arrow_circle_down_rounded,
                        color: const Color(0xFF16A34A),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/receipts?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Payment Out',
                        subtitle: 'Pay vendor',
                        icon: Icons.arrow_circle_up_rounded,
                        color: const Color(0xFFDC2626),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/payments?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Sales Order',
                        subtitle: 'Customer order',
                        icon: Icons.shopping_cart_rounded,
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
                        color: const Color(0xFFF43F5E),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/expenses?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Credit Note',
                        subtitle: 'Sales return',
                        icon: Icons.assignment_return_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/credit-notes?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Debit Note',
                        subtitle: 'Purchase return',
                        icon: Icons.assignment_returned_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/debit-notes?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Party Transfer',
                        subtitle: 'Balance shift',
                        icon: Icons.swap_horiz_rounded,
                        color: const Color(0xFF14B8A6),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/party-transfers?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Other Income',
                        subtitle: 'Non-sales revenue',
                        icon: Icons.monetization_on_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/other-incomes?create=true');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Cash & Bank',
                        subtitle: 'Add bank/cash',
                        icon: Icons.account_balance_rounded,
                        color: const Color(0xFF0EA5E9),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/cash-and-bank');
                        },
                      ),
                      _buildQuickActionTile(
                        context,
                        title: 'Add Product',
                        subtitle: 'Item master',
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFFF97316),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/items');
                        },
                      ),
                    ],
                  ),
                ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: color.withOpacity(isDark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
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
