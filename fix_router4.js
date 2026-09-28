const fs = require('fs');
let content = fs.readFileSync('lib/router.dart', 'utf8');

content = content.replace(/builder: \(context, state\) => const PersonalStatsScreen\(\),\r?\n\s*GoRoute\(/g, "builder: (context, state) => const PersonalStatsScreen(),\n          ),\n          GoRoute(");

content = content.replace(/builder: \(context, state\) => const PersonalManagementScreen\(\),\r?\n\s*GoRoute\(/g, "builder: (context, state) => const PersonalManagementScreen(),\n          ),\n          GoRoute(");

content = content.replace(/builder: \(context, state\) => const PersonalAccountsScreen\(\),\r?\n\s*GoRoute\(/g, "builder: (context, state) => const PersonalAccountsScreen(),\n          ),\n          GoRoute(");

fs.writeFileSync('lib/router.dart', content);
console.log('Fixed missing parenthesis for routes');
