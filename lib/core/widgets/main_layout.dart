import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';
import 'package:business_sahaj_erp/core/widgets/custom_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);

    if (isDesktop) {
      // Desktop Layout: Permanent side drawer + Appbar + Main content body
      return Scaffold(
        appBar: const CustomAppBar(),
        backgroundColor: theme.colorScheme.background,
        body: Row(
          children: [
            // Permanent side drawer on desktop
            const SizedBox(
              width: 280,
              child: CustomDrawer(isPermanent: true),
            ),
            // Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.surfaceVariant,
            ),
            // Main content body
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    } else {
      // Mobile / Tablet Layout: Slider Drawer triggered by hamburger icon in CustomAppBar
      return Scaffold(
        appBar: const CustomAppBar(),
        drawer: const CustomDrawer(isPermanent: false),
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: child,
        ),
      );
    }
  }
}
