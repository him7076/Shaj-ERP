const fs = require('fs');

const path = 'lib/core/widgets/full_screen_item_entry.dart';
let content = fs.readFileSync(path, 'utf8');

// 1. Add description to FullScreenItemEntryData
content = content.replace(
  'final double purchaseRate;',
  'final double purchaseRate;\n  final String? description;'
);

content = content.replace(
  'this.purchaseRate = 0.0,',
  'this.purchaseRate = 0.0,\n    this.description,'
);

// 2. Add description controller
content = content.replace(
  'final TextEditingController _batchController = TextEditingController();',
  'final TextEditingController _batchController = TextEditingController();\n  final TextEditingController _descriptionController = TextEditingController();'
);

// 3. Initialize description controller
content = content.replace(
  "_batchController.text = d.batchNumber ?? '';",
  "_batchController.text = d.batchNumber ?? '';\n      _descriptionController.text = d.description ?? '';"
);

// 4. Update _save method to pass description
content = content.replace(
  'purchaseRate: double.tryParse(_purchaseRateController.text) ?? 0.0,',
  "purchaseRate: double.tryParse(_purchaseRateController.text) ?? 0.0,\n      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),"
);

// 5. Add description TextField conditionally
const batchFieldSearch = `TextFormField(
                              controller: _batchController,
                              decoration: const InputDecoration(
                                labelText: 'Batch Number (Optional)',
                                prefixIcon: Icon(Icons.qr_code),
                              ),
                            ),`;

const descriptionFieldInsert = `
                            Consumer(
                              builder: (context, ref, child) {
                                final prefs = ref.watch(sharedPreferencesProvider);
                                final isBundle = _selectedItem?.isBundle == true;
                                final showDesc = isBundle 
                                  ? (prefs.getBool('enable_bundle_description') ?? false)
                                  : (prefs.getBool('enable_item_description') ?? false);
                                  
                                if (!showDesc) return const SizedBox.shrink();
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                      prefixIcon: Icon(Icons.description_outlined),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                );
                              },
                            ),`;

if (content.includes(batchFieldSearch)) {
  content = content.replace(batchFieldSearch, batchFieldSearch + descriptionFieldInsert);
} else {
  console.log("Could not find batchFieldSearch");
}

fs.writeFileSync(path, content, 'utf8');
console.log('Updated FullScreenItemEntry with Description logic');
