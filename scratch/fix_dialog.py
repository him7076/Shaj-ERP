import os

path = "lib/features/transactions/presentation/screens/add_edit_transaction_dialog.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix 1: Link Bills Checkbox UI
old_str = """                                child: ResponsiveFormRow(
                                  children: [
                                    Checkbox("""
new_str = """                                child: Row(
                                  children: [
                                    Checkbox("""
content = content.replace(old_str, new_str)

# Fix 2: Transaction Number in Header
old_header = "widget.transaction != null\n                                    ? 'Edit ${_transactionType}'\n                                    : 'New ${_transactionType} Entry',"
new_header = "widget.transaction != null\n                                    ? 'Edit ${_transactionType} ${widget.transaction!.transactionNumber != null ? \\' (#\\' + widget.transaction!.transactionNumber! + \\')\\' : \\'\\'}'\n                                    : 'New ${_transactionType} Entry',"
content = content.replace(old_header, new_header)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("Done")
