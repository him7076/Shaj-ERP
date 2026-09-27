import os
import re

file_path = "lib/features/settings/presentation/screens/settings_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add FSSAI controller and Logo state
content = content.replace(
    "final categoryController = TextEditingController(text: prefs.getString('firm_category_$id') ?? 'Trading & Retail');",
    """final categoryController = TextEditingController(text: prefs.getString('firm_category_$id') ?? 'Trading & Retail');
    final fssaiController = TextEditingController(text: prefs.getString('firm_fssai_$id') ?? '');
    String? _logoPath = prefs.getString('firm_logo_$id');"""
)

# Add Logo Picker UI after Basic Firm Info header
logo_ui = """
                    // Logo Picker
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                            color: theme.colorScheme.surfaceVariant,
                          ),
                          child: _logoPath != null && _logoPath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(_logoPath!), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                                )
                              : Icon(Icons.add_photo_alternate, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Firm Logo', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Choose Logo'),
                                onPressed: () async {
                                  try {
                                    final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                    if (result != null && result.files.single.path != null) {
                                      setDialogState(() {
                                        _logoPath = result.files.single.path;
                                      });
                                    }
                                  } catch (_) {}
                                },
                              ),
                              if (_logoPath != null && _logoPath!.isNotEmpty)
                                TextButton(
                                  onPressed: () => setDialogState(() => _logoPath = null),
                                  child: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Business Information',"""

content = content.replace("Text('Business Information',", logo_ui)

# Add FSSAI field near GST/PAN
fssai_ui = """
                        Expanded(
                          child: TextFormField(
                            controller: panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'PAN Number',
                              
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFormRow(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: fssaiController,
                            decoration: const InputDecoration(
                              labelText: 'FSSAI Number',
                              prefixIcon: Icon(Icons.verified_user),
                            ),
                          ),
                        ),
                      ],
                    ),
"""

content = content.replace("""
                        Expanded(
                          child: TextFormField(
                            controller: panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'PAN Number',
                              
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                        ),
                      ],
                    ),
""", fssai_ui)


# Save FSSAI and Logo in SharedPreferences
save_block = """
                            await prefs.setString('firm_category_$id', categoryController.text.trim());
                            await prefs.setString('firm_fssai_$id', fssaiController.text.trim());
                            if (_logoPath != null) {
                              await prefs.setString('firm_logo_$id', _logoPath!);
                            } else {
                              await prefs.remove('firm_logo_$id');
                            }
"""

content = content.replace("await prefs.setString('firm_category_$id', categoryController.text.trim());", save_block)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Done updating settings_screen.dart")
