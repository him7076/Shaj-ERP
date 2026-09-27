import os

file_path = "lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix the broken strings caused by PowerShell expansion
content = content.replace("remarks.contains('paid via \\') ||", "remarks.contains('paid via $name') ||")
content = content.replace("remarks.contains('paid via \\') ||", "remarks.contains('paid via $accName') ||")
content = content.replace("transactionType: 'Expense (\\{exp.category ?? \"General\"})',", "transactionType: 'Expense (${exp.category ?? \"General\"})',")

# Fix specific variables that were completely eaten by PS
# In _loadAccounts:
content = content.replace("remarks.contains('paid via \\') || remarks.contains(name))) {", "remarks.contains('paid via $name') || remarks.contains(name))) {")

# In _loadTransactions:
content = content.replace("remarks.contains('paid via \\') || remarks.contains(accName))) {", "remarks.contains('paid via $accName') || remarks.contains(accName))) {")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done fixing dart file.")
