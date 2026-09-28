const fs = require('fs');
const file = 'lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart';
let c = fs.readFileSync(file, 'utf8');

c = c.replace(
  "import '../../../sales/presentation/widgets/searchable_party_dropdown.dart';",
  "import '../../../../core/widgets/searchable_party_dropdown.dart';"
);

fs.writeFileSync(file, c);
