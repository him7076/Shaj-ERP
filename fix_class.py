import sys

with open('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_class = '''class AccountTransactionDisplayItem {
  final String transactionNumber;
  final String partyName;
  final String transactionType;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String? remarks;

  AccountTransactionDisplayItem({
    required this.transactionNumber,
    required this.partyName,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.remarks,
  });
}'''

new_class = '''class AccountTransactionDisplayItem {
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
}'''

# Replace normal string or with \r\n
old_class_crlf = old_class.replace('\n', '\r\n')

if old_class in content:
    content = content.replace(old_class, new_class)
    print('Replaced LF')
elif old_class_crlf in content:
    content = content.replace(old_class_crlf, new_class)
    print('Replaced CRLF')
else:
    print('NOT FOUND!')

with open('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)