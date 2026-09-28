const fs = require('fs');
const path = require('path');

const files = [
  'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
  'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
  'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
  'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
];

for (const file of files) {
  const filePath = path.resolve(process.cwd(), file);
  if (!fs.existsSync(filePath)) continue;
  
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Find the block: void _addFullScreenItemLine(FullScreenItemEntryData data) { ... }
  // Since it can be async, we use a regex that matches the start
  const regex = /void _addFullScreenItemLine\(FullScreenItemEntryData data\)( async)? \{([\s\S]*?)(\n  \})/m;
  const match = content.match(regex);
  
  if (match) {
    let replacement = '';
    
    if (file.includes('purchase_screen.dart')) {
      replacement = `void _addFullScreenItemLine(FullScreenItemEntryData data) async {
    final item = data.item;
    try {
      await item.unit.load();
    } catch (_) {}

    final newItem = PurchaseItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = data.quantity
      ..unit = data.unit
      ..rate = data.rate
      ..discount = data.discountAmount
      ..gstRate = data.gstRate
      ..batchNumber = data.batchNumber
      ..mfgDate = data.mfgDate?.toIso8601String()
      ..expiryDate = data.expDate?.toIso8601String()
      ..taxableAmount = data.taxableAmount
      ..gstAmount = data.gstAmount
      ..totalAmount = data.totalAmount;
      
    newItem.item.value = item;

    setState(() {
      _draftItems.add(newItem);
    });
    
    if (data.saleRate != (item.sellRate ?? 0.0) || data.purchaseRate != (item.buyRate ?? 0.0)) {
        item.sellRate = data.saleRate;
        item.buyRate = data.purchaseRate;
        item.updatedAt = DateTime.now();
        item.isSynced = false;
        try {
          ref.read(itemsListProvider.notifier).updateItem(item);
        } catch (_) {}
    }
    
    _recalculateTotals();
  }`;
    } else {
      // The other screens use the CartNotifier approach
      const isInvoice = file.includes('invoice_screen.dart');
      const isOrder = file.includes('order_screen.dart');
      const isCredit = file.includes('credit_note_screen.dart');
      const isDebit = file.includes('debit_note_screen.dart');
      
      let cartProviderName = 'invoiceCartProvider';
      if (isOrder) cartProviderName = 'cartProvider';
      else if (isCredit) cartProviderName = 'creditNoteCartProvider';
      else if (isDebit) cartProviderName = 'debitNoteCartProvider';
      
      let itemClassName = 'InvoiceItem';
      if (isOrder) itemClassName = 'OrderItem';
      else if (isCredit) itemClassName = 'CreditNoteItem';
      else if (isDebit) itemClassName = 'DebitNoteItem';
      
      replacement = `void _addFullScreenItemLine(FullScreenItemEntryData data) {
    final item = data.item;

    final newItem = ${itemClassName}()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = data.quantity
      ..unit = data.unit
      ..rate = data.rate
      ..discount = data.discountAmount // some models use discountAmount, some use discount
      ..batchNumber = data.batchNumber
      ..mfgDate = data.mfgDate?.toIso8601String()
      ..expiryDate = data.expDate?.toIso8601String();
      
    if (newItem is InvoiceItem) {
      (newItem as InvoiceItem).gstRate = data.gstRate;
      (newItem as InvoiceItem).discount = data.discountAmount;
    } else if (newItem is CreditNoteItem) {
      (newItem as CreditNoteItem).gstRate = data.gstRate;
      (newItem as CreditNoteItem).discount = data.discountAmount;
    } else if (newItem is DebitNoteItem) {
      (newItem as DebitNoteItem).gstRate = data.gstRate;
      (newItem as DebitNoteItem).discount = data.discountAmount;
    } else if (newItem is OrderItem) {
      (newItem as OrderItem).gstPercent = data.gstRate;
      (newItem as OrderItem).discountAmount = data.discountAmount;
      (newItem as OrderItem).discountPercent = data.discountPercent;
    }
      
    newItem.item.value = item;

    final notifier = ref.read(${cartProviderName}.notifier);
    notifier.addItem(newItem.item.value!);
    final cart = ref.read(${cartProviderName});
    
    // Different providers have slightly different updateItemAt arguments
    try {
      notifier.updateItemAt(
        cart.items.length - 1,
        quantity: data.quantity,
        rate: data.rate,
        discountAmount: data.discountAmount,
        discountPercent: data.discountPercent,
        unit: data.unit,
        batchNumber: data.batchNumber ?? '',
        mfgDate: data.mfgDate?.toIso8601String() ?? '',
        expiryDate: data.expDate?.toIso8601String() ?? '',
      );
    } catch(e) {
      // Fallback if some arguments like discountPercent are not supported
      notifier.updateItemAt(
        cart.items.length - 1,
        quantity: data.quantity,
        rate: data.rate,
        discountAmount: data.discountAmount,
        unit: data.unit,
        batchNumber: data.batchNumber ?? '',
        mfgDate: data.mfgDate?.toIso8601String() ?? '',
        expiryDate: data.expDate?.toIso8601String() ?? '',
      );
    }
    
    if (data.saleRate != (item.sellRate ?? 0.0) || data.purchaseRate != (item.buyRate ?? 0.0)) {
        item.sellRate = data.saleRate;
        item.buyRate = data.purchaseRate;
        item.updatedAt = DateTime.now();
        item.isSynced = false;
        try {
          ref.read(itemsListProvider.notifier).updateItem(item);
        } catch (_) {}
    }
  }`;
    }
    
    content = content.replace(regex, replacement);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Updated ' + file);
  } else {
    console.log('Could not find _addFullScreenItemLine in ' + file);
  }
}
