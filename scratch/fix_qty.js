const fs = require('fs');

function fixFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf-8');
    
    // Find the block we previously inserted:
    /*
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        await _handleItemAdded(tempSelected);
      },
    */
    
    // We will replace `await ..._handleItemAdded(tempSelected);` with the proper logic depending on the file.
    
    if (filepath.includes('invoice_screen')) {
        content = content.replace(/await\s+(_handleItemAdded|_addItemLine)\(tempSelected\);/g, `
        await $1(tempSelected);
        // Post-update qty and discount
        ref.read(invoiceCartProvider.notifier).updateItem(
          data.item.uuid ?? '',
          quantity: data.quantity,
          discountAmount: data.discountAmount,
        );
        `);
    } else if (filepath.includes('purchase_screen') || filepath.includes('debit_note') || filepath.includes('credit_note')) {
        content = content.replace(/await\s+(_handleItemAdded|_addItemLine)\(tempSelected\);/g, `
        $1(tempSelected);
        setState(() {
           if (_draftItems.isNotEmpty) {
             _draftItems.last.quantity = data.quantity;
             _draftItems.last.discount = data.discountAmount;
           }
        });
        _recalculateTotals();
        `);
    }

    fs.writeFileSync(filepath, content, 'utf-8');
    console.log("Fixed " + filepath);
}

const files = [
    "C:/Users/lenovo/Desktop/Shaj ERP/lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart",
    "C:/Users/lenovo/Desktop/Shaj ERP/lib/features/sales/presentation/screens/add_edit_invoice_screen.dart",
    "C:/Users/lenovo/Desktop/Shaj ERP/lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart",
    "C:/Users/lenovo/Desktop/Shaj ERP/lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart"
];

for (let file of files) {
    if (fs.existsSync(file)) {
        fixFile(file);
    }
}
