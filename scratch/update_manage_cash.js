const fs = require('fs');

let c = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

const regex = /:\s*FloatingActionButton\.extended\([\s\S]*?heroTag:\s*'add_bank_txn'[\s\S]*?\),/;

const replacement = `: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'adjust_bank',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => AdjustCashDialog(
                      accountName: widget.accountName,
                      isBank: true,
                      bankUuid: widget.bankUuid,
                    ),
                  );
                  if (res == true) _loadTransactions();
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Adjust Bank'),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'add_bank_txn',
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (_) => TransferFundsDialog(defaultFromAccount: widget.accountName),
                  );
                  if (res == true) {
                    _loadTransactions();
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Bank Transaction'),
              ),
            ],
          ),`;

c = c.replace(regex, replacement);
fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', c, 'utf8');
console.log('Fixed FAB in bank screen');
