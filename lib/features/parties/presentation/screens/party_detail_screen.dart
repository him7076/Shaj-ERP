import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
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
  int _displayLimit = 50;
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

      if (item != null) {
        final partyUuid = item.uuid;
        final partyNameLower = item.partyName?.trim().toLowerCase();
        final partyId = item.id;

        double totalPending = 0.0;
        if (item.partyType == 'Supplier') {
          final purchases = await isar.purchases.filter()
              .isDeletedEqualTo(false)
              .and()
              .group((q) => q
                  .partyIdEqualTo(partyId)
                  .or()
                  .partyNameEqualTo(item!.partyName ?? '', caseSensitive: false)
                  .or()
                  .party((p) => p.uuidEqualTo(partyUuid ?? ''))
              )
              .findAll();
          for (var pur in purchases) {
            if (pur.paymentStatus != 'Cancelled') {
              totalPending += (pur.pendingAmount ?? ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0)));
            }
          }
        } else {
          final invoices = await isar.invoices.filter()
              .isDeletedEqualTo(false)
              .and()
              .group((q) => q
                  .partyIdEqualTo(partyId)
                  .or()
                  .partyNameEqualTo(item!.partyName ?? '', caseSensitive: false)
                  .or()
                  .party((p) => p.uuidEqualTo(partyUuid ?? ''))
              )
              .findAll();
          for (var inv in invoices) {
            if (inv.paymentStatus != 'Cancelled') {
              totalPending += (inv.pendingAmount ?? ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0)));
            }
          }
        }

        final opening = item.openingBalance ?? 0.0;
        item.outstandingBalance = totalPending > 0 ? totalPending : opening;
      }

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location services have been disabled.')),
    );
  }

  void _launchWhatsApp(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final urlStr = 'https://wa.me/91$cleanPhone';
    Clipboard.setData(ClipboardData(text: urlStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp link copied: $urlStr')),
      );
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
        appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, title: const Text('Party Not Found')),
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
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        toolbarHeight: isMobile ? 44 : 56,
        title: Text(
          isMobile ? 'Party Details' : (_party!.partyName ?? 'Party Dashboard'),
          style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share Business Card',
            icon: Icon(Icons.share_outlined, size: isMobile ? 20 : 24),
            onPressed: _shareCard,
          ),
          IconButton(
            tooltip: 'Edit Party Profile',
            icon: Icon(Icons.edit_outlined, size: isMobile ? 20 : 24),
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
            icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: isMobile ? 20 : 24),
            onPressed: _softDeleteParty,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Next-Gen Hero Profile Banner (Mobile Optimized)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 22 : 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          initial,
                          style: TextStyle(fontSize: isMobile ? 20 : 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _party!.partyName ?? 'Unnamed Party',
                              style: TextStyle(fontSize: isMobile ? 16 : 22, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Code: ${_party!.partyCode ?? "N/A"}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_party!.partyType ?? 'Customer', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Direct Shortcuts Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_party!.mobileNumber != null && _party!.mobileNumber!.isNotEmpty)
                        _buildHeroActionButton(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          isMobile: isMobile,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _party!.mobileNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied phone: ${_party!.mobileNumber}')));
                          },
                        ),
                      if (_party!.mobileNumber != null && _party!.mobileNumber!.isNotEmpty)
                        _buildHeroActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          isMobile: isMobile,
                          onTap: () => _launchWhatsApp(_party!.mobileNumber!),
                        ),
                      _buildHeroActionButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Invoice',
                        isMobile: isMobile,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddEditInvoiceScreen()),
                          );
                        },
                      ),
                      _buildHeroActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Payment',
                        isMobile: isMobile,
                        onTap: () {
                          AddEditTransactionDialog.show(context, initialParty: _party);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Financial Metrics Summary Cards (1 Single Row on Mobile)
            Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      theme: theme,
                      title: 'Outstanding',
                      value: currencyFormat.format(outstanding),
                      subtitle: isDr ? 'Due (Dr)' : 'Advance (Cr)',
                      color: isDr ? Colors.red : Colors.green,
                      icon: isDr ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: _buildMetricCard(
                      theme: theme,
                      title: 'Credit Limit',
                      value: currencyFormat.format(creditLimit),
                      subtitle: 'Avail: ${currencyFormat.format(availableCredit)}',
                      color: availableCredit < 0 ? Colors.red : Colors.blue,
                      icon: Icons.credit_card_rounded,
                      isMobile: isMobile,
                    ),
                  ),
                ],
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
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14, vertical: isMobile ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isMobile ? 14 : 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 12)),
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
    bool isMobile = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 24),
            ),
            SizedBox(width: isMobile ? 8 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: isMobile ? 14 : 18, fontWeight: FontWeight.bold, color: color))),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontSize: isMobile ? 9 : 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_PartyActivityItem>> _loadAllPartyActivities() async {
    if (_party == null) return [];
    final isar = ref.read(databaseServiceProvider).isar;
    final partyUuid = _party!.uuid;
    final partyNameLower = _party!.partyName?.trim().toLowerCase();
    final partyId = _party!.id;

    final List<_PartyActivityItem> list = [];

    // 1. Invoices
    final invoices = await isar.invoices.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .partyIdEqualTo(partyId)
            .or()
            .partyNameEqualTo(_party!.partyName ?? '', caseSensitive: false)
            .or()
            .party((p) => p.uuidEqualTo(partyUuid ?? ''))
        )
        .findAll();
    for (var inv in invoices) {
      if (inv.paymentStatus != 'Cancelled') {
        list.add(_PartyActivityItem(
          id: inv.id,
          uuid: inv.uuid,
          number: inv.invoiceNumber ?? 'INV-${inv.id}',
          type: 'Sales Invoice',
          amount: inv.grandTotal ?? 0.0,
          pendingAmount: inv.pendingAmount ?? (inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0),
          status: inv.paymentStatus ?? 'UNPAID',
          mode: inv.invoiceType ?? 'Credit',
          date: inv.invoiceDate ?? inv.createdAt,
        ));
      }
    }

    // 2. Purchases
    final purchases = await isar.purchases.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .partyIdEqualTo(partyId)
            .or()
            .partyNameEqualTo(_party!.partyName ?? '', caseSensitive: false)
            .or()
            .party((p) => p.uuidEqualTo(partyUuid ?? ''))
        )
        .findAll();
    for (var pur in purchases) {
      if (pur.paymentStatus != 'Cancelled') {
        list.add(_PartyActivityItem(
          id: pur.id,
          uuid: pur.uuid,
          number: pur.purchaseNumber ?? 'PUR-${pur.id}',
          type: 'Purchase Bill',
          amount: pur.grandTotal ?? 0.0,
          pendingAmount: pur.pendingAmount ?? (pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0),
          status: pur.paymentStatus ?? 'UNPAID',
          mode: 'Credit',
          date: pur.purchaseDate ?? pur.createdAt,
        ));
      }
    }

    // 3. Transactions (Receipts, Payments, etc.)
    final txns = await isar.transactions.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .partyUuidEqualTo(partyUuid ?? '')
            .or()
            .partyNameEqualTo(_party!.partyName ?? '', caseSensitive: false)
            .or()
            .party((p) => p.uuidEqualTo(partyUuid ?? ''))
        )
        .findAll();
    for (var t in txns) {
      list.add(_PartyActivityItem(
        id: t.id,
        uuid: t.uuid,
        number: t.transactionNumber ?? 'TXN-${t.id}',
        type: t.transactionType ?? 'Transaction',
        amount: t.amount ?? 0.0,
        pendingAmount: 0.0,
        status: t.paymentStatus ?? (t.linkedBillUuid != null && t.linkedBillUuid!.isNotEmpty ? 'LINKED' : 'CLEARED'),
        mode: t.paymentMode ?? 'Cash',
        date: t.transactionDate ?? t.createdAt,
        rawTxn: t,
      ));
    }

    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Widget _buildLiveTransactionsTab(ThemeData theme) {
    return FutureBuilder<List<_PartyActivityItem>>(
      future: _loadAllPartyActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final partyTransactions = snapshot.data ?? [];
        if (partyTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                const Text('No transactions or invoices recorded for this party yet.', style: TextStyle(fontWeight: FontWeight.bold)),
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

        final visibleList = partyTransactions.take(_displayLimit).toList();
        final hasMore = partyTransactions.length > _displayLimit;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visibleList.length + (hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == visibleList.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _displayLimit += 50;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: Text(
                      'Load More Ledger (Showing ${_displayLimit} of ${partyTransactions.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }

            final txn = visibleList[index];
            final isIncoming = txn.type == 'Sales Invoice' || txn.type == 'Receipt';
            final color = isIncoming ? Colors.green : Colors.red;
            final statusStr = txn.status;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ListTile(
                onTap: () {
                  final targetUuid = (txn.uuid != null && txn.uuid!.isNotEmpty) ? txn.uuid! : txn.id.toString();
                  if (txn.type == 'Sales Invoice') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoiceUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.type == 'Purchase Bill') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditPurchaseScreen(purchaseUuid: targetUuid)),
                    ).then((_) => _loadPartyDetails());
                  } else if (txn.rawTxn != null) {
                    AddEditTransactionDialog.show(context, transaction: txn.rawTxn);
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                ),
                title: Row(
                  children: [
                    Text(txn.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(txn.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusStr == 'PAID' || statusStr == 'CLEARED' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusStr.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusStr == 'PAID' || statusStr == 'CLEARED' ? Colors.green.shade800 : Colors.orange.shade900)),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(txn.date)} | Mode: ${txn.mode}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  currencyFormat.format(txn.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
              ),
            );
          },
        );
      },
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

class _PartyActivityItem {
  final int id;
  final String? uuid;
  final String number;
  final String type;
  final double amount;
  final double pendingAmount;
  final String status;
  final String mode;
  final DateTime date;
  final Transaction? rawTxn;

  _PartyActivityItem({
    required this.id,
    this.uuid,
    required this.number,
    required this.type,
    required this.amount,
    required this.pendingAmount,
    required this.status,
    required this.mode,
    required this.date,
    this.rawTxn,
  });
}
