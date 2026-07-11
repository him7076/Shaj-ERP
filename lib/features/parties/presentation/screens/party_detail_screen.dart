import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/core/widgets/error_dialog.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
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

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  Party? _party;
  bool _isLoading = true;
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadPartyDetails();
  }

  Future<void> _loadPartyDetails() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(partyRepositoryProvider);
      final item = await repo.getByUuid(widget.partyUuid);
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

      // Get current location coordinates
      final position = await gps.getCurrentLocation();
      
      // Reverse geocode
      final geocodedAddress = await gps.reverseGeocode(position.latitude, position.longitude);
      final mapUrl = gps.getGoogleMapUrl(position.latitude, position.longitude);

      // Save to database
      await repo.updateGPSLocation(
        _party!.uuid!,
        position.latitude,
        position.longitude,
        geocodedAddress,
        mapUrl,
      );

      // Reload
      await _loadPartyDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS coordinates captured and synced successfully.')),
        );
      }
    } catch (e) {
      ErrorDialog.show(context, title: 'GPS Capture Failed', message: e.toString());
    }
    setState(() => _isCapturingLocation = false);
  }

  Future<void> _softDeleteParty() async {
    if (_party == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party?'),
        content: Text('Are you sure you want to delete ${_party!.partyName}? This action can be synced offline.'),
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
                  Navigator.pop(context); // Close details screen
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

  void _shareDetails() {
    if (_party == null) return;
    final card = '''Party Name: ${_party!.partyName}
Code: ${_party!.partyCode}
Type: ${_party!.partyType}
Mobile: ${_party!.mobileNumber ?? 'N/A'}
GST: ${_party!.gstNumber ?? 'N/A'}
Address: ${_party!.addressLine1 ?? ''}, ${_party!.city ?? ''}, ${_party!.state ?? ''} - ${_party!.pincode ?? ''}
GPS Location: ${_party!.latitude != null ? '${_party!.latitude},${_party!.longitude}' : 'Not Captured'}''';

    Clipboard.setData(ClipboardData(text: card));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party business card copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_party == null) {
      return const Scaffold(body: Center(child: Text('Party record not found.')));
    }

    final outstanding = _party!.openingBalance ?? 0.0;
    final creditLimit = _party!.creditLimit ?? 0.0;
    final availableCredit = creditLimit - outstanding;

    return Scaffold(
      appBar: AppBar(
        title: Text(_party!.partyName ?? 'Details'),
        actions: [
          IconButton(
            tooltip: 'Share Card',
            icon: const Icon(Icons.share),
            onPressed: _shareDetails,
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPartyScreen(party: _party),
                ),
              ).then((_) {
                _loadPartyDetails();
              });
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Balance Card
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Outstanding Balance', style: theme.textTheme.titleMedium),
                        Text(
                          '₹${outstanding.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _party!.balanceType == 'Dr' ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Credit Limit: ₹${creditLimit.toStringAsFixed(0)}'),
                        Text(
                          'Available Credit: ₹${availableCredit.toStringAsFixed(0)}',
                          style: TextStyle(color: availableCredit < 0 ? Colors.red : Colors.green[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile info groups
            _buildInfoCard(
              title: 'Basic Details',
              icon: Icons.person_outline,
              children: {
                'Party Code': _party!.partyCode ?? 'N/A',
                'Category': _party!.businessCategory ?? 'N/A',
                'Party Type': _party!.partyType ?? 'N/A',
                'Contact Person': _party!.contactPerson ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Contact Details',
              icon: Icons.phone_outlined,
              children: {
                'Mobile Number': _party!.mobileNumber ?? 'N/A',
                'WhatsApp Number': _party!.whatsappNumber ?? 'N/A',
                'Email Address': _party!.email ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Tax & GST Details',
              icon: Icons.receipt_long_outlined,
              children: {
                'GST Type': _party!.gstType ?? 'N/A',
                'GSTIN': _party!.gstNumber ?? 'N/A',
                'PAN': _party!.panNumber ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Billing Address',
              icon: Icons.location_on_outlined,
              children: {
                'Address Line 1': _party!.addressLine1 ?? 'N/A',
                'Address Line 2': _party!.addressLine2 ?? 'N/A',
                'City/State': '${_party!.city ?? ''}, ${_party!.state ?? ''}',
                'Pincode': _party!.pincode ?? 'N/A',
              },
            ),
            const SizedBox(height: 16),

            // GPS location card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('GPS Location Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    _party!.latitude != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Latitude: ${_party!.latitude}'),
                              const SizedBox(height: 4),
                              Text('Longitude: ${_party!.longitude}'),
                              const SizedBox(height: 8),
                              Text('Captured Geocode: ${_party!.locationAddress ?? "Not Geocoded"}'),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: _party!.googleMapUrl ?? ''));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Maps link copied to clipboard!')),
                                        );
                                      },
                                      icon: const Icon(Icons.map),
                                      label: const Text('Open Map'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isCapturingLocation ? null : _captureGPSLocation,
                                      icon: const Icon(Icons.my_location),
                                      label: const Text('Recapture'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Text('GPS Coordinates have not been captured for this party yet.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _isCapturingLocation ? null : _captureGPSLocation,
                                icon: _isCapturingLocation
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.gps_fixed),
                                label: const Text('Capture Location Coordinates'),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ledger Placeholder Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Activity Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Detailed ledger printing ready.')),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildLedgerRow('2026-06-15', 'Opening Balance', '₹${outstanding.toStringAsFixed(2)}', Colors.red[700]),
                    _buildLedgerRow('2026-06-18', 'Sales Invoice #INV-0012', '₹15,000.00', Colors.red[700]),
                    _buildLedgerRow('2026-06-20', 'Payment Recv #TXN-902', '₹15,000.00', Colors.green[700]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Card
            if (_party!.notes != null && _party!.notes!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 20),
                      Text(_party!.notes!, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Map<String, String> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 24),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(6),
              },
              children: children.entries.map((entry) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(entry.value),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(String date, String details, String amount, Color? amountColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(details, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: amountColor)),
        ],
      ),
    );
  }
}
