const fs = require('fs');
let dashboard = fs.readFileSync('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'utf8');
if (!dashboard.includes('theme_provider.dart')) {
    dashboard = "import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';\n" + dashboard;
    fs.writeFileSync('lib/features/dashboard/presentation/screens/dashboard_screen.dart', dashboard);
    console.log('Added theme_provider to dashboard');
}

let router = fs.readFileSync('lib/router.dart', 'utf8');
router = router.replace(/^.*fixed_assets_dashboard_screen\.dart.*$/gm, '');
fs.writeFileSync('lib/router.dart', router);
console.log('Cleaned router');
