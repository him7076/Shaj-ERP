const fs = require('fs');

let f = 'lib/features/transactions/presentation/screens/transactions_screen.dart';
let t = fs.readFileSync(f, 'utf8');

// Remove auth_providers.dart
t = t.replace(`import 'package:business_sahaj_erp/presentation/providers/auth_providers.dart';\n`, '');
t = t.replace(`import 'package:business_sahaj_erp/presentation/providers/auth_providers.dart';\r\n`, '');
t = t.replace(`import 'package:business_sahaj_erp/presentation/providers/auth_providers.dart';`, '');

// Replace user lookup
t = t.replace(`final user = ref.read(currentUserProvider)?.name ?? 'System';`, `final user = 'System';`);

fs.writeFileSync(f, t);
console.log('Removed auth_providers.dart and currentUserProvider!');
