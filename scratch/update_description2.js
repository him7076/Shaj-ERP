const fs = require('fs');
const path = 'lib/core/widgets/full_screen_item_entry.dart';
let content = fs.readFileSync(path, 'utf8');

const search = "_buildModernTextField('Batch Number', _batchController),";
const replacement = search + `
                                  const SizedBox(height: 12),
                                  Consumer(
                                    builder: (context, r, child) {
                                      final prefs = r.watch(sharedPreferencesProvider);
                                      final isBundle = _selectedItem?.isBundle == true;
                                      final showDesc = isBundle
                                          ? (prefs.getBool('enable_bundle_description') ?? false)
                                          : (prefs.getBool('enable_item_description') ?? false);
                                      if (!showDesc) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: TextFormField(
                                          controller: _descriptionController,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText: 'Description',
                                            alignLabelWithHint: true,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }
                                  ),`;

content = content.replace(search, replacement);
fs.writeFileSync(path, content, 'utf8');
console.log('Replaced successfully');
