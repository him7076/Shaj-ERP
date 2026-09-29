const fs = require('fs');
let c = fs.readFileSync('lib/features/bank/presentation/screens/adjust_cash_dialog.dart', 'utf8');

c = c.replace(
  'class AdjustCashDialog extends ConsumerStatefulWidget {',
  `class AdjustCashDialog extends ConsumerStatefulWidget {
  final String accountName;
  final bool isBank;
  final String? bankUuid;`
);

c = c.replace(
  'const AdjustCashDialog({Key? key}) : super(key: key);',
  `const AdjustCashDialog({
    Key? key,
    this.accountName = 'Cash',
    this.isBank = false,
    this.bankUuid,
  }) : super(key: key);`
);

c = c.replace(
  `String _adjustmentType = 'Add Cash'; // 'Add Cash', 'Reduce Cash'`,
  `late String _adjustmentType;`
);

c = c.replace(
  `super.initState();`,
  `super.initState();
    _adjustmentType = widget.isBank ? 'Add Bank Balance' : 'Add Cash';`
);

c = c.replace(
  `if (_adjustmentType == 'Add Cash') {
        paymentMode = 'System Adjustment'; // Source
        partyName = 'Cash'; // Target
      } else {
        paymentMode = 'Cash'; // Source
        partyName = 'System Adjustment'; // Target
      }`,
  `if (_adjustmentType.startsWith('Add')) {
        paymentMode = 'System Adjustment';
        partyName = widget.accountName;
      } else {
        paymentMode = widget.accountName;
        partyName = 'System Adjustment';
      }`
);

c = c.replace(
  `..bankUuid = null`,
  `..bankUuid = widget.bankUuid`
);

c = c.replace(
  `['Add Cash', 'Reduce Cash']`,
  `[widget.isBank ? 'Add Bank Balance' : 'Add Cash', widget.isBank ? 'Reduce Bank Balance' : 'Reduce Cash']`
);

c = c.replace(
  `title: const Text('Adjust Cash',`,
  `title: Text(widget.isBank ? 'Adjust Bank Balance' : 'Adjust Cash',`
);

fs.writeFileSync('lib/features/bank/presentation/screens/adjust_cash_dialog.dart', c, 'utf8');
console.log('Updated AdjustCashDialog successfully');
