const fs = require('fs');

const path = 'lib/data/repositories/transaction_repository_impl.dart';
let content = fs.readFileSync(path, 'utf8');

const regex = /final allTxns = await collection\.where\(\)\.findAll\(\);[\s\S]*?return '\$prefix-\$suffix';/m;

const newGen = `String prefix = 'PAYMENT';
      if (type == 'Receipt' || type == 'Payment In') prefix = 'RECEIPT';
      else if (type == 'Expense') prefix = 'EXP';
      else if (type == 'Other Income') prefix = 'OTHER Income';
      else if (type == 'Credit Note') prefix = 'CN';
      else if (type == 'Debit Note') prefix = 'DN';
      else if (['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)) prefix = 'TRF';

      final allTxns = await collection.where().findAll();
      int maxNum = 0;
      for (var t in allTxns) {
        if (t.transactionNumber != null && t.transactionNumber!.startsWith(prefix)) {
          final matches = RegExp(r'\\d+').allMatches(t.transactionNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final suffix = nextNum.toString().padLeft(2, '0');
      return '$prefix-$suffix';`;

if (regex.test(content)) {
    content = content.replace(regex, newGen);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Fixed Repo 3!");
} else {
    console.log("Regex not found in Repo!");
}
