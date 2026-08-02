import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'add_edit_party_screen.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  final String partyUuid;

  const PartyDetailScreen({
    Key? key,
    required this.partyUuid,
  }) : super(key: key);

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> with SingleTickerProviderStateMixin {
  Party? _party;
  bool _isLoading = true;
  bool _isCapturingLocation = false;
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPartyDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPartyDetails() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final idVal = int.tryParse(widget.partyUuid);
      Party? item;
      if (idVal != null) {
        item = await isar.partys.get(idVal);
      }
      item ??= await isar.partys.filter().uuidEqualTo(widget.partyUuid).findFirst();

      setState(() {
        _party = item;
      });
    } catch (e) {
      logger.error('Failed to load party details', e);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _captureGPSLocation() async {
    if (_party == null) return;
    setState(() => _isCapturingLocation = true);
    try {
      final gps = ref.read(gpsServiceProvider);
      final repo = ref.read(partyRepositoryProvider);

      final position = await gps.getCurrentLocation();
      final geocodedAddress = await gps.reverseGeocode(position.latitude, position.longitude);
      final mapUrl = gps.getGoogleMapUrl(position.latitude, position.longitude);

      await repo.updateGPSLocation(
        _party!.uuid!,
        position.latitude,
        position.longitude,
        geocodedAddress,
        mapUrl,
      );

      await _loadPartyDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS coordinates captured & updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ErrorDialog.show(context, title: 'GPS Capture Failed', message: e.toString());
    }
    setState(() => _isCapturingLocation = false);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp link copied: $phone')),
        );
      }
    }
  }

  Future<void> _softDeleteParty() async {
    if (_party == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Party Profile?'),
        content: Text('Are you sure you want to delete "${_party!.partyName}"? This action will mark party as inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repo = ref.read(partyRepositoryProvider);
                await repo.softDelete(_party!.uuid!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Party deleted successfully.')),
                  );
                }
              } catch (e) {
                ErrorDialog.show(context, title: 'Delete Failed', message: e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareCard() {
    if (_party == null) return;
    final card = '''Party Name: ${_party!.partyName}
Code: ${_party!.partyCode}
Type: ${_party!.partyType}
Mobile: ${_party!.mobileNumber ?? 'N/A'}
GSTIN: ${_party!.gstNumber ?? 'N/A'}
Address: ${_party!.addressLine1 ?? ''}, ${_party!.city ?? ''}, ${_party!.state ?? ''} - ${_party!.pincode ?? ''}
Current Outstanding: ₹${(_party!.outstandingBalance ?? 0.0).toStringAsFixed(2)}''';

    Clipboard.setData(ClipboardData(text: card));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party business card copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_party == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Party Not Found')),
        body: const Center(child: Text('Requested party record does not exist or was deleted.')),
      );
    }

    final outstanding = _party!.outstandingBalance ?? 0.0;
    final creditLimit = _party!.creditLimit ?? 0.0;
    final availableCredit = creditLimit - outstanding;
    final isDr = _party!.balanceType == 'Dr' || outstanding > 0;
    final initial = (_party!.partyName?.isNotEmpty == true) ? _party!.partyName![0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(_party!.partyName ?? 'Party Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share Business Card',
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareCard,
          ),
          IconButton(
            tooltip: 'Edit Party Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPartyScreen(party: _party),
                ),
              ).then((_) => _loadPartyDetails());
            },
          ),
          IconButton(
            tooltip: 'Delete Party',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _softDeleteParty,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Next-Gen Hero Profile Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          initial,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _party!.partyName ?? 'Unnamed Party',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Code: ${_party!.partyCode ?? "N/A"}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_party!.partyType ?? 'Customer', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                if (_party!.city != null && _party!.city!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('📍 ${_party!.city}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            if (_party!.gstNumber != null && _party!.gstNumber!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('GSTIN: ${_party!.gstNumber}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Direct Shortcuts Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_party!.mobileNumber != null && _party!.mobileNumber!.isNotEmpty)
                        _buildHeroActionButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _party!.mobileNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied phone: ${_party!.mobileNumber}')));
                          },
                        ),
                      if (_party!.mobileNumber != null && _party!.mobileNumber!.isNotEmpty)
                        _buildHeroActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          onTap: () => _launchWhatsApp(_party!.mobileNumber!),
                        ),
                      _buildHeroActionButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'New Invoice',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddEditInvoiceScreen()),
                          );
                        },
                      ),
                      _buildHeroActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Record Payment',
                        onTap: () {
                          AddEditTransactionDialog.show(context, initialParty: _party);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Financial Metrics Summary Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return Flex(
                    direction: isNarrow ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isNarrow ? 0 : 1,
                        child: _buildMetricCard(
                          theme: theme,
                          title: 'Net Outstanding Balance',
                          value: currencyFormat.format(outstanding),
                          subtitle: isDr ? 'Customer Ledger Due (Receivable)' : 'Advance Paid (Credit)',
                          color: isDr ? Colors.red : Colors.green,
                          icon: isDr ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                        ),
                      ),
                      const SizedBox(width: 12, height: 12),
                      Expanded(
                        flex: isNarrow ? 0 : 1,
                        child: _buildMetricCard(
                          theme: theme,
                          title: 'Credit Limit & Available',
                          value: currencyFormat.format(creditLimit),
                          subtitle: 'Available Limit: ${currencyFormat.format(availableCredit)}',
                          color: availableCredit < 0 ? Colors.red : Colors.blue,
                          icon: Icons.credit_card_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Tab Bar Header
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(icon: Icon(Icons.history_rounded), text: 'Transactions Ledger'),
                  Tab(icon: Icon(Icons.badge_outlined), text: 'Party Credentials'),
                  Tab(icon: Icon(Icons.gps_fixed_rounded), text: 'GPS & Location'),
                ],
              ),
            ),

            // Tab Bar View Container
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveTransactionsTab(theme),
                  _buildPartyCredentialsTab(theme),
                  _buildGPSLocationTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTransactionsTab(ThemeData theme) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final partyTransactions = allTransactions.where((t) {
          final matchesUuid = t.partyUuid == _party!.uuid;
          final matchesName = t.partyName?.toLowerCase() == _party!.partyName?.toLowerCase();
          return matchesUuid || matchesName;
        }).toList();

        if (partyTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                const Text('No transactions recorded for this party yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => AddEditTransactionDialog.show(context, initialParty: _party),
                  icon: const Icon(Icons.add),
                  label: const Text('Record First Transaction'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: partyTransactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final txn = partyTransactions[index];
            final isIncoming = txn.transactionType == 'Receipt' || txn.transactionType == 'Sales' || txn.transactionType == 'Other Income';
            final color = isIncoming ? Colors.green : Colors.red;
            final statusStr = txn.paymentStatus ?? (txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty ? 'LINKED' : 'CLEARED');

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                ),
                title: Row(
                  children: [
                    Text(txn.transactionNumber ?? 'TXN', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(txn.transactionType ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusStr == 'PAID' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusStr.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusStr == 'PAID' ? Colors.green.shade800 : Colors.orange.shade900)),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Date: ${txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : "N/A"} | Mode: ${txn.paymentMode ?? "Cash"}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  currencyFormat.format(txn.amount ?? 0.0),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load party transactions: $e')),
    );
  }

  Widget _buildPartyCredentialsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCredentialsCard(
            theme: theme,
            title: 'Basic Info & Category',
            icon: Icons.business,
            data: {
              'Party Code': _party!.partyCode ?? 'N/A',
              'Party Role/Type': _party!.partyType ?? 'Customer',
              'Industry Category': _party!.businessCategory ?? 'General',
              'Contact Representative': _party!.contactPerson ?? 'N/A',
            },
          ),
          const SizedBox(height: 12),
          _buildCredentialsCard(
            theme: theme,
            title: 'Taxation & PAN Credentials',
            icon: Icons.receipt_long,
            data: {
              'GST Type': _party!.gstType ?? 'Unregistered',
              'GSTIN': _party!.gstNumber ?? 'Unregistered',
              'PAN Number': _party!.panNumber ?? 'N/A',
              'State & Code': '${_party!.state ?? "N/A"} (${_party!.gstNumber != null && _party!.gstNumber!.length >= 2 ? _party!.gstNumber!.substring(0, 2) : "N/A"})',
            },
          ),
          const SizedBox(height: 12),
          _buildCredentialsCard(
            theme: theme,
            title: 'Registered Address Details',
            icon: Icons.location_on,
            data: {
              'Street Address': _party!.addressLine1 ?? 'N/A',
              'Locality / Zone': _party!.addressLine2 ?? 'N/A',
              'City / District': _party!.city ?? 'N/A',
              'State / Pincode': '${_party!.state ?? "N/A"} - ${_party!.pincode ?? ""}',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Map<String, String> data,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            ...data.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSLocationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('GPS Location Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Divider(height: 24),
              if (_party!.latitude != null) ...[
                Text('Latitude: ${_party!.latitude}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Longitude: ${_party!.longitude}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Geocoded Address: ${_party!.locationAddress ?? "Captured"}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final url = _party!.googleMapUrl ?? 'https://maps.google.com/?q=${_party!.latitude},${_party!.longitude}';
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maps URL copied!')));
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Open Map Link'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCapturingLocation ? null : _captureGPSLocation,
                        icon: _isCapturingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                        label: const Text('Recapture GPS'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text('GPS location coordinates have not been recorded for this party yet.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureGPSLocation,
                  icon: _isCapturingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.gps_fixed),
                  label: const Text('Capture Current GPS Location'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
