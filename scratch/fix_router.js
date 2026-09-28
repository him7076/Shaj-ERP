const fs = require('fs');

// 1. Fix dashboard_screen.dart
let dsPath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart';
let dsContent = fs.readFileSync(dsPath, 'utf8');
dsContent = dsContent.replace(/settings\.getBool\('maintain_fixed_assets'\)/g, "settings.getBool('enable_fixed_assets')");
fs.writeFileSync(dsPath, dsContent);

// 2. Fix mobile_bottom_sheets.dart
let mbPath = 'lib/core/widgets/mobile_bottom_sheets.dart';
let mbContent = fs.readFileSync(mbPath, 'utf8');
mbContent = mbContent.replace(/settings\.getBool\('maintain_fixed_assets'\)/g, "settings.getBool('enable_fixed_assets')");
fs.writeFileSync(mbPath, mbContent);

// 3. Add to router.dart
let rPath = 'lib/router.dart';
let rContent = fs.readFileSync(rPath, 'utf8');

if (!rContent.includes('AddEditInvoiceScreen')) {
  rContent = rContent.replace(
    /import 'package:business_sahaj_erp\/features\/sales\/presentation\/screens\/sales_screen\.dart';/,
    "import 'package:business_sahaj_erp/features/sales/presentation/screens/sales_screen.dart';\nimport 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';"
  );
}

if (!rContent.includes('AddEditPurchaseScreen')) {
  rContent = rContent.replace(
    /import 'package:business_sahaj_erp\/features\/purchases\/presentation\/screens\/purchases_screen\.dart';/,
    "import 'package:business_sahaj_erp/features/purchases/presentation/screens/purchases_screen.dart';\nimport 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';"
  );
}

if (!rContent.includes('/purchase-fa')) {
  rContent = rContent.replace(
    /GoRoute\(\s*path: '\/reports',/,
    "GoRoute(\n            path: '/purchase-fa',\n            name: 'purchase-fa',\n            builder: (context, state) => const AddEditPurchaseScreen(isFixedAsset: true),\n          ),\n          GoRoute(\n            path: '/sale-fa',\n            name: 'sale-fa',\n            builder: (context, state) => const AddEditInvoiceScreen(isFixedAsset: true),\n          ),\n          GoRoute(\n            path: '/reports',"
  );
}

fs.writeFileSync(rPath, rContent);
console.log('Fixed router and settings files.');
