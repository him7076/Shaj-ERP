const fs = require('fs');
let content = fs.readFileSync('lib/router.dart', 'utf8');

content = content.replace("import 'package:business_sahaj_erp/features/fixed_assets/presentation/screens/fixed_assets_dashboard_screen.dart';\n", "");

const routeText = `            GoRoute(
              path: '/fixed-assets',
              name: 'fixed-assets',
              builder: (context, state) => const FixedAssetsDashboardScreen(),
            ),
`;
content = content.replace(routeText, "");

// Add Purchase FA and Sale FA routes
const newRoutes = `            GoRoute(
              path: '/purchase-fa',
              name: 'purchase-fa',
              builder: (context, state) {
                final create = state.uri.queryParameters['create'] == 'true';
                return const AddEditPurchaseScreen(isFixedAsset: true);
              },
            ),
            GoRoute(
              path: '/sale-fa',
              name: 'sale-fa',
              builder: (context, state) {
                final create = state.uri.queryParameters['create'] == 'true';
                return const AddEditInvoiceScreen(isFixedAsset: true);
              },
            ),
`;

const reportsRoute = `            GoRoute(
              path: '/reports',`;
content = content.replace(reportsRoute, newRoutes + reportsRoute);

fs.writeFileSync('lib/router.dart', content);
console.log('Fixed router');
