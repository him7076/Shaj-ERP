const fs = require('fs');
const path = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';

let content = fs.readFileSync(path, 'utf8');

// 1. Update routing and entity type
content = content.replace(`  // --- Open Account Transactions Screen ---
  void _openAccountTransactions({required String accountName, String? bankUuid, bool isCash = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AccountTransactionsDetailScreen(
          accountName: accountName,
          bankUuid: bankUuid,
          isCash: isCash,
        ),
      ),
    );
  }
}

// --- Unified Display Item for Account Transactions ---
class AccountTransactionDisplayItem {
  final String transactionNumber;
  final String partyName;
  final String transactionType;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String? remarks;
  final String? entityUuid;

  AccountTransactionDisplayItem({
    required this.transactionNumber,
    required this.partyName,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.remarks,
    this.entityUuid,
  });
}

// --- Account Transactions Detailed View Screen with Filters & Search ---
class AccountTransactionsDetailScreen extends ConsumerStatefulWidget {
  final String accountName;
  final String? bankUuid;
  final bool isCash;

  const AccountTransactionsDetailScreen({
    Key? key,
    required this.accountName,
    this.bankUuid,
    this.isCash = false,
  }) : super(key: key);

  @override
  ConsumerState<AccountTransactionsDetailScreen> createState() => _AccountTransactionsDetailScreenState();
}

class _AccountTransactionsDetailScreenState extends ConsumerState<AccountTransactionsDetailScreen> {
  String _searchQuery = '';
  String _typeFilter = 'All'; // All, Receipt, Payment, Transfer
  String _sortBy = 'Newest First'; // Newest First, Oldest First, Highest Amount

  List<AccountTransactionDisplayItem> _allDisplayItems = [];`, `  // --- Open Account Transactions Screen ---
  void _openAccountTransactions({required String accountName, String? bankUuid, bool isCash = false}) {
    final account = _accounts.where((a) => a.uuid == bankUuid).firstOrNull;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (ctx) => AccountTransactionsDetailScreen(
          accountName: accountName,
          bankUuid: bankUuid,
          isCash: isCash,
          account: account,
          onEdit: () {
            if (account != null) _showAddEditAccountDialog(existingAccount: account);
          },
          onDelete: () {
            if (account != null) {
              _deleteAccount(account).then((_) {
                if (mounted) Navigator.pop(context);
              });
            }
          },
        ),
      ),
    );
  }
}

// --- Unified Display Item for Account Transactions ---
class AccountTransactionDisplayItem {
  final String transactionNumber;
  final String partyName;
  final String transactionType;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String? remarks;
  final String? entityUuid;
  final String entityType;

  AccountTransactionDisplayItem({
    required this.transactionNumber,
    required this.partyName,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.remarks,
    this.entityUuid,
    this.entityType = 'Transaction',
  });
}

// --- Account Transactions Detailed View Screen with Filters & Search ---
class AccountTransactionsDetailScreen extends ConsumerStatefulWidget {
  final String accountName;
  final String? bankUuid;
  final bool isCash;
  final BankAccount? account;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountTransactionsDetailScreen({
    Key? key,
    required this.accountName,
    this.bankUuid,
    this.isCash = false,
    this.account,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  ConsumerState<AccountTransactionsDetailScreen> createState() => _AccountTransactionsDetailScreenState();
}

class _AccountTransactionsDetailScreenState extends ConsumerState<AccountTransactionsDetailScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _typeFilter = 'All'; // All, Receipt, Payment, Transfer
  String _sortBy = 'Newest First'; // Newest First, Oldest First, Highest Amount
  final FocusNode _searchFocusNode = FocusNode();

  List<AccountTransactionDisplayItem> _allDisplayItems = [];`);


// 2. Update Transaction list items types
content = content.replace(`          items.add(AccountTransactionDisplayItem(
            transactionNumber: t.transactionNumber ?? 'TXN',
            partyName: t.partyName ?? 'Party',
            transactionType: t.transactionType ?? 'Payment',
            date: t.transactionDate ?? t.createdAt,
            amount: t.amount ?? 0.0,
            isCredit: isCredit,
            remarks: t.remarks,
            entityUuid: t.uuid,
          ));`, `          String displayType = t.transactionType ?? 'Payment';
          if (t.linkedBillUuid != null && t.transactionType == 'Receipt') {
            displayType = 'Sales';
          } else if (t.linkedBillUuid != null && t.transactionType == 'Payment') {
            displayType = 'Purchase';
          }
          items.add(AccountTransactionDisplayItem(
            transactionNumber: t.transactionNumber ?? 'TXN',
            partyName: t.partyName ?? 'Party',
            transactionType: displayType,
            date: t.transactionDate ?? t.createdAt,
            amount: t.amount ?? 0.0,
            isCredit: isCredit,
            remarks: t.remarks,
            entityUuid: t.uuid,
            entityType: 'Transaction',
          ));`);

content = content.replace(`          items.add(AccountTransactionDisplayItem(
            transactionNumber: inv.invoiceNumber ?? 'INV',
            partyName: inv.partyName ?? 'Customer',
            transactionType: 'Sales',
            date: inv.invoiceDate ?? inv.createdAt,
            amount: paid,
            isCredit: true,
            remarks: inv.remarks,
            entityUuid: inv.uuid,
          ));`, `          items.add(AccountTransactionDisplayItem(
            transactionNumber: inv.invoiceNumber ?? 'INV',
            partyName: inv.partyName ?? 'Customer',
            transactionType: 'Sales',
            date: inv.invoiceDate ?? inv.createdAt,
            amount: paid,
            isCredit: true,
            remarks: inv.remarks,
            entityUuid: inv.uuid,
            entityType: 'Invoice',
          ));`);

content = content.replace(`          items.add(AccountTransactionDisplayItem(
            transactionNumber: pur.purchaseNumber ?? 'PUR',
            partyName: pur.partyName ?? 'Supplier',
            transactionType: 'Purchase',
            date: pur.purchaseDate ?? pur.createdAt,
            amount: paid,
            isCredit: false,
            remarks: pur.remarks,
            entityUuid: pur.uuid,
          ));`, `          items.add(AccountTransactionDisplayItem(
            transactionNumber: pur.purchaseNumber ?? 'PUR',
            partyName: pur.partyName ?? 'Supplier',
            transactionType: 'Purchase',
            date: pur.purchaseDate ?? pur.createdAt,
            amount: paid,
            isCredit: false,
            remarks: pur.remarks,
            entityUuid: pur.uuid,
            entityType: 'Purchase',
          ));`);

content = content.replace(`          items.add(AccountTransactionDisplayItem(
            transactionNumber: exp.voucherNo ?? 'EXP',
            partyName: exp.partyName ?? exp.category ?? 'Expense',
            transactionType: 'Expense (\${exp.category ?? "General"})',
            date: exp.expenseDate ?? exp.createdAt,
            amount: exp.amount ?? 0.0,
            isCredit: false,
            remarks: exp.remarks,
            entityUuid: exp.uuid,
          ));`, `          items.add(AccountTransactionDisplayItem(
            transactionNumber: exp.voucherNo ?? 'EXP',
            partyName: exp.partyName ?? exp.category ?? 'Expense',
            transactionType: 'Expense (\${exp.category ?? "General"})',
            date: exp.expenseDate ?? exp.createdAt,
            amount: exp.amount ?? 0.0,
            isCredit: false,
            remarks: exp.remarks,
            entityUuid: exp.uuid,
            entityType: 'Expense',
          ));`);


// 3. Update the UI body
const ui_start_index = content.indexOf(`  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;`);

const ui_end_index = content.indexOf(`// --- Cheque Management & Deposit Screen ---`);

const new_ui = `  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;

    final double totalInflow = txns.where((t) => t.isCredit).fold(0.0, (s, t) => s + t.amount);
    final double totalOutflow = txns.where((t) => !t.isCredit).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
        leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null,
        title: _isSearching
            ? TextField(
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(widget.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                  _searchFocusNode.requestFocus();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Type',
            onSelected: (val) => setState(() => _typeFilter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              const PopupMenuItem(value: 'Receipt', child: Text('Receipts / Inflows (+)')),
              const PopupMenuItem(value: 'Payment', child: Text('Payments / Outflows (-)')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort By',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Newest First', child: Text('Newest First')),
              const PopupMenuItem(value: 'Oldest First', child: Text('Oldest First')),
              const PopupMenuItem(value: 'Highest Amount', child: Text('Highest Amount')),
            ],
          ),
          if (!widget.isCash)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'edit') {
                  widget.onEdit?.call();
                } else if (val == 'delete') {
                  widget.onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Account')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showDialog(
            context: context,
            builder: (_) => TransferFundsDialog(defaultFromAccount: widget.isCash ? 'Cash' : widget.accountName),
          );
          if (res == true) {
            _loadTransactions();
          }
        },
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Transfer Funds'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Beautiful Header Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Total Inflows (+)', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(currencyFormat.format(totalInflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Total Outflows (-)', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(currencyFormat.format(totalOutflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : txns.isEmpty
                        ? const Center(child: Text('No matching transactions found for this account.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 80),
                            itemCount: txns.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final t = txns[index];
                              final isCredit = t.isCredit;

                              return NeuCard(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    if (t.entityUuid == null) return;
                                    if (t.entityType == 'Transaction') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddEditTransactionDialog(
                                          transactionUuid: t.entityUuid,
                                          lockedType: null,
                                        ),
                                      ).then((_) => _loadTransactions());
                                    } else if (t.entityType == 'Invoice') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceUuid: t.entityUuid!))
                                      ).then((_) => _loadTransactions());
                                    } else if (t.entityType == 'Purchase') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => AddEditPurchaseScreen(purchaseUuid: t.entityUuid))
                                      ).then((_) => _loadTransactions());
                                    } else if (t.entityType == 'Expense') {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expenseUuid: t.entityUuid))
                                      ).then((_) => _loadTransactions());
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCredit ? Colors.green : Colors.red),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(t.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text('#\${t.transactionNumber} • \${t.transactionType}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              if (t.remarks != null && t.remarks!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Text(t.remarks!, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\${isCredit ? "+" : "-"}\${currencyFormat.format(t.amount)}',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? Colors.green : Colors.red),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(DateFormat('dd-MM-yy').format(t.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

`;

content = content.substring(0, ui_start_index) + new_ui + content.substring(ui_end_index);

fs.writeFileSync(path, content);
console.log('Done');
