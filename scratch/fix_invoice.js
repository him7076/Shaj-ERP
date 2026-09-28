const fs = require('fs');
let invPath = 'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart';
let inv = fs.readFileSync(invPath, 'utf8');

inv = inv.replace(
  /FullScreenItemEntry\.show\(\s*context,\s*excludeBundles:\s*true,\s*onAdd:/g,
  'FullScreenItemEntry.show(context, excludeBundles: true, isFixedAsset: widget.isFixedAsset, onAdd:'
);

inv = inv.replace(
  /FullScreenItemEntry\.show\(\s*context,\s*onlyBundles:\s*true,\s*onAdd:/g,
  'FullScreenItemEntry.show(context, onlyBundles: true, isFixedAsset: widget.isFixedAsset, onAdd:'
);

fs.writeFileSync(invPath, inv);
console.log('Fixed Invoice Screen Item Entry Calls');
