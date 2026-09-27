const fs = require('fs');

// Fix mobile_bottom_sheets.dart
let sheets = fs.readFileSync('lib/core/widgets/mobile_bottom_sheets.dart', 'utf8');
sheets = sheets.replace("import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';", "import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';");
fs.writeFileSync('lib/core/widgets/mobile_bottom_sheets.dart', sheets);

// Fix manage_cash_and_bank_screen.dart
let bank = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');
bank = "import 'package:business_sahaj_erp/features/bank/presentation/screens/add_edit_bank_account_dialog.dart';\n" + bank;
fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', bank);

// Fix dashboard_screen.dart
let dashboard = fs.readFileSync('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'utf8');
dashboard = dashboard.replace('Widget _buildQuickActionsGrid(BuildContext context) {', 'Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {');
dashboard = dashboard.replace('_buildQuickActionsGrid(context),', '_buildQuickActionsGrid(context, ref),');
fs.writeFileSync('lib/features/dashboard/presentation/screens/dashboard_screen.dart', dashboard);
console.log('Fixed compile errors');
