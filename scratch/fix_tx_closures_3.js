const fs = require('fs');
let c = fs.readFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', 'utf8');

c = c.replace(
  "                      );\n\n},\n              loading: () => const Center",
  "                      );\n                    },\n                    separatorBuilder: (context, index) => const SizedBox(height: 8),\n                  );\n                },\n              loading: () => const Center"
);

fs.writeFileSync('lib/features/transactions/presentation/screens/transactions_screen.dart', c);
console.log('Fixed closures in transactions_screen.dart');
