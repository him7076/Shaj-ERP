  void _showAddEditFirmDialog(dynamic prefs, List<String> firmsList, String? firmId, String? currentName) {
    final isEditing = firmId != null;
    final id = firmId ?? 'firm_${DateTime.now().millisecondsSinceEpoch}';

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

    bool isFetchingGst = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          Future<void> autoFetchGst() async {
            final gstin = gstController.text.trim();
            if (gstin.length < 15) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid 15-digit GSTIN number.')),
              );
              return;
            }

            setDialogState(() => isFetchingGst = true);
            try {
              final gstService = ref.read(gstServiceProvider);
              final details = await gstService.fetchPartyDetailsFromGst(gstin);

              if (details != null) {
                setDialogState(() {
                  nameController.text = details.tradeName.isNotEmpty ? details.tradeName : details.legalName;
                  panController.text = details.panNumber;
                  stateController.text = details.stateName;
                  addressController.text = details.addressLine1;
                  cityController.text = details.city;
                  pincodeController.text = details.pincode;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Auto-fetched firm details for ${details.tradeName}!'),
                      backgroundColor: Colors.amber.shade900,
                    ),
                  );
                }
              }
            } catch (_) {
            } finally {
              setDialogState(() => isFetchingGst = false);
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(width: MediaQuery.of(context).size.width, constraints: const BoxConstraints(maxWidth: 650),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Row(
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
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // 1-Click GST Auto-Fetch Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.amber.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: gstController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Enter GSTIN (e.g. 27AAAAA1111A1Z1)',
                                labelText: 'GSTIN Number',
                                isDense: true,
                                
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade900,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: isFetchingGst ? null : autoFetchGst,
                            icon: isFetchingGst
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome, size: 16),
                            label: Text(isFetchingGst ? 'Fetching...' : '1-Click Auto-Fetch'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Basic Firm Info
                    Text('Business Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company / Firm Name *',
                        
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFormRow(children: [ Expanded(child: TextFormField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp Number',
                              
                              prefixIcon: Icon(Icons.chat),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFormRow(children: [ Expanded(child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),

                    // Location & Address
                    Text('Address & Location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address / Street',
                        
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFormRow(children: [ Expanded(child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City / District',
                              
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              
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
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Banking Details
                    Text('Banking & Payment Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    ResponsiveFormRow(children: [ Expanded(child: TextFormField(
                            controller: bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Bank Name',
                              
                              prefixIcon: Icon(Icons.account_balance),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: bankAccController,
                            decoration: const InputDecoration(
                              labelText: 'Account Number',
                              
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFormRow(children: [ Expanded(child: TextFormField(
                            controller: ifscController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'IFSC Code',
                              
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: upiController,
                            decoration: const InputDecoration(
                              labelText: 'UPI ID (e.g. business@upi)',
                              
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(isEditing ? 'Save Firm Details' : 'Create & Switch Firm'),
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

                            if (mounted) {
                              setState(() {});
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
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }