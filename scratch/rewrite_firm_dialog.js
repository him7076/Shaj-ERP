const fs = require('fs');

let c = fs.readFileSync('lib/features/settings/presentation/screens/settings_screen.dart', 'utf8');
const startStr = '  void _showAddEditFirmDialog(dynamic prefs, List<String> firmsList, String? firmId, String? currentName) {';
const startIndex = c.indexOf(startStr);
let bracketCount = 0;
let endIndex = -1;
for (let i = startIndex; i < c.length; i++) {
  if (c[i] === '{') bracketCount++;
  else if (c[i] === '}') {
    bracketCount--;
    if (bracketCount === 0) {
      endIndex = i + 1;
      break;
    }
  }
}

let newDialogStr = `  void _showAddEditFirmDialog(dynamic prefs, List<String> firmsList, String? firmId, String? currentName) {
    final isEditing = firmId != null;
    final id = firmId ?? 'firm_\${DateTime.now().millisecondsSinceEpoch}';

    final nameController = TextEditingController(text: currentName ?? '');
    final gstController = TextEditingController(text: prefs.getString('firm_gst_$id') ?? '');
    final mobileController = TextEditingController(text: prefs.getString('firm_mobile_$id') ?? '');
    final whatsappController = TextEditingController(text: prefs.getString('firm_whatsapp_$id') ?? '');
    final emailController = TextEditingController(text: prefs.getString('firm_email_$id') ?? '');
    final panController = TextEditingController(text: prefs.getString('firm_pan_$id') ?? '');
    final addressController = TextEditingController(text: prefs.getString('firm_address_$id') ?? '');
    final cityController = TextEditingController(text: prefs.getString('firm_city_$id') ?? '');
    final stateController = TextEditingController(text: prefs.getString('firm_state_$id') ?? '');
    final pincodeController = TextEditingController(text: prefs.getString('firm_pincode_$id') ?? '');
    final bankNameController = TextEditingController(text: prefs.getString('firm_bank_name_$id') ?? '');
    final bankAccController = TextEditingController(text: prefs.getString('firm_bank_acc_$id') ?? '');
    final ifscController = TextEditingController(text: prefs.getString('firm_ifsc_$id') ?? '');
    final upiController = TextEditingController(text: prefs.getString('firm_upi_$id') ?? '');
    final categoryController = TextEditingController(text: prefs.getString('firm_category_$id') ?? 'Trading & Retail');
    final fssaiController = TextEditingController(text: prefs.getString('firm_fssai_$id') ?? '');
    String? _logoPath = prefs.getString('firm_logo_$id');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return Scaffold(
              appBar: AppBar(
                title: Text(isEditing ? 'Edit Firm Profile' : 'Create New Company / Firm'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Firm Profile' : 'Create New Company / Firm',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isEditing ? 'Update business registration, tax details & banking' : 'Set up multi-firm business account in Shaj ERP',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Basic Firm Info
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Basic Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company / Firm Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Business Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.chat),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Tax & Registration Info
                    Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Tax & Registration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: gstController,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.receipt_long),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: panController,
                            decoration: const InputDecoration(
                              labelText: 'PAN Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fssaiController,
                      decoration: const InputDecoration(
                        labelText: 'FSSAI Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                    ),

                    const Divider(height: 32),

                    // Address Details
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Address & Location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Bank Details
                    Row(
                      children: [
                        Icon(Icons.account_balance, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Bank & UPI Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Bank Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.food_bank),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: bankAccController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Account Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ifscController,
                            decoration: const InputDecoration(
                              labelText: 'IFSC Code',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.code),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: upiController,
                            decoration: const InputDecoration(
                              labelText: 'UPI ID',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Save Firm Details' : 'Create & Switch Firm', style: const TextStyle(fontSize: 16)),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Firm Name is required.')),
                          );
                          return;
                        }

                        // Save into SharedPreferences for this firm ID
                        if (!isEditing) {
                          final updatedFirms = List<String>.from(firmsList)..add(id);
                          await prefs.setStringList('firms_list', updatedFirms);
                          await prefs.setBool('demo_seeded_$id', true);
                        }

                        await prefs.setString('firm_name_$id', name);
                        await prefs.setString('firm_updated_at_$id', DateTime.now().toUtc().toIso8601String());
                        await prefs.setString('firm_gst_$id', gstController.text.trim());
                        await prefs.setString('firm_mobile_$id', mobileController.text.trim());
                        await prefs.setString('firm_whatsapp_$id', whatsappController.text.trim());
                        await prefs.setString('firm_email_$id', emailController.text.trim());
                        await prefs.setString('firm_pan_$id', panController.text.trim());
                        await prefs.setString('firm_address_$id', addressController.text.trim());
                        await prefs.setString('firm_city_$id', cityController.text.trim());
                        await prefs.setString('firm_state_$id', stateController.text.trim());
                        await prefs.setString('firm_pincode_$id', pincodeController.text.trim());
                        await prefs.setString('firm_bank_name_$id', bankNameController.text.trim());
                        await prefs.setString('firm_bank_acc_$id', bankAccController.text.trim());
                        await prefs.setString('firm_ifsc_$id', ifscController.text.trim());
                        await prefs.setString('firm_upi_$id', upiController.text.trim());
                        await prefs.setString('firm_category_$id', categoryController.text.trim());
                        await prefs.setString('firm_fssai_$id', fssaiController.text.trim());
                        if (_logoPath != null) {
                          await prefs.setString('firm_logo_$id', _logoPath!);
                        } else {
                          await prefs.remove('firm_logo_$id');
                        }

                        // Update active Isar Settings object
                        try {
                          final isar = ref.read(databaseServiceProvider).isar;
                          final settings = await isar.settings.filter().idGreaterThan(-1).findFirst() ?? Settings();
                          settings.companyName = name;
                          settings.companyGST = gstController.text.trim();
                          settings.companyPhone = mobileController.text.trim();
                          settings.companyAddress = addressController.text.trim();
                          await isar.writeTxn(() async => await isar.settings.put(settings));
                        } catch (_) {}

                        try {
                          await ref.read(syncServiceProvider).syncFirms();
                        } catch (_) {}

                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        if (!isEditing) {
                          final db = ref.read(databaseServiceProvider);
                          await db.switchFirm(id, prefs);
                          ref.read(activeFirmIdProvider.notifier).state = id;
                          
                          // Run handleFirmSwitch in background without awaiting
                          ref.read(syncManagerProvider).handleFirmSwitch(id).catchError((_) {});

                          // Invalidate all local data providers to guarantee clean multi-firm isolation
                          ref.invalidate(sharedPreferencesProvider);
                          ref.invalidate(dashboardAnalyticsProvider);
                          ref.invalidate(filteredPartiesProvider);
                          ref.invalidate(filteredItemsProvider);
                          ref.invalidate(categoriesListProvider);
                          ref.invalidate(brandsListProvider);
                          ref.invalidate(unitsListProvider);
                          ref.invalidate(purchaseListProvider);
                          ref.invalidate(filteredInvoicesProvider);
                          ref.invalidate(filteredOrdersProvider);
                          ref.invalidate(expenseListProvider);
                          ref.invalidate(bankAccountsListProvider);
                          ref.invalidate(filteredTransactionsProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Created and switched to company: $name'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.go('/dashboard');
                          }
                        } else {
                          // Force UI to rebuild on edit too!
                          ref.invalidate(sharedPreferencesProvider);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated company profile for $name'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                        
                        ref.invalidate(settingsProvider);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }`;

c = c.substring(0, startIndex) + newDialogStr + c.substring(endIndex);
fs.writeFileSync('lib/features/settings/presentation/screens/settings_screen.dart', c, 'utf8');
console.log('Successfully updated _showAddEditFirmDialog with Isar updates!');
