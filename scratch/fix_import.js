const fs = require('fs');

let c = fs.readFileSync('lib/core/widgets/full_screen_item_entry.dart', 'utf8');
if (!c.includes('theme_provider.dart')) {
  c = 'import \'package:business_sahaj_erp/presentation/providers/theme_provider.dart\';\n' + c;
  fs.writeFileSync('lib/core/widgets/full_screen_item_entry.dart', c, 'utf8');
  console.log('Added theme_provider.dart import');
} else {
  console.log('theme_provider.dart already imported');
}
