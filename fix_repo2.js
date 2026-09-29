const fs = require('fs');

const path = 'lib/data/repositories/transaction_repository_impl.dart';
let content = fs.readFileSync(path, 'utf8');

const regex = /  @override\r?\n  Future<String> generateNextTransactionNumber\(String type\) async \{\r?\n    try \{\r?\n      final allTxns = await collection\.where\(\)\.findAll\(\);\r?\n      int maxNum = 0;\r?\n      for \(var t in allTxns\) \{\r?\n        if \(t\.transactionType == type && t\.transactionNumber != null\) \{\r?\n          final matches = RegExp\(r'\\d\+'\)\.allMatches\(t\.transactionNumber!\);\r?\n          if \(matches\.isNotEmpty\) \{\r?\n            final parsed = int\.tryParse\(matches\.last\.group\(0\)!\) \?\? 0;\r?\n            if \(parsed > maxNum\) maxNum = parsed;\r?\n          \}\r?\n        \}\r?\n      \}\r?\n      final nextNum = maxNum \+ 1;\r?\n      final suffix = nextNum\.toString\(\)\.padLeft\(2, '0'\);\r?\n      String prefix = 'PAYMENT';\r?\n      if \(type == 'Receipt' \|\| type == 'Payment In'\) prefix = 'RECEIPT';\r?\n      if \(type == 'Expense'\) prefix = 'EXP';\r?\n      if \(type == 'Other Income'\) prefix = 'OTHER Income';\r?\n      if \(type == 'Credit Note'\) prefix = 'CN';\r?\n      if \(type == 'Debit Note'\) prefix = 'DN';\r?\n      if \(\['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'\]\.contains\(type\)\) prefix = 'TRF';\r?\n      return '\\$prefix-\\$suffix';\r?\n    \} catch \(e\) \{\r?\n      throw DatabaseException\('Failed to generate transaction number: \\$e'\);\r?\n    \}\r?\n  \}/;

const newGen = `  @override
  Future<String> generateNextTransactionNumber(String type) async {
    try {
      String prefix = 'PAYMENT';
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
      return '\\$prefix-\\$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate transaction number: \\$e');
    }
  }`;

if (regex.test(content)) {
    content = content.replace(regex, newGen);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Fixed Repo!");
} else {
    console.log("Regex not found!");
}
