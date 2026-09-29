const fs = require('fs');

const files = [
  'lib/features/orders/presentation/screens/order_detail_screen.dart',
  'lib/features/sales/presentation/screens/invoice_detail_screen.dart'
];

files.forEach(file => {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Add import if missing
    if (!content.includes('bank_account_collection.dart')) {
      content = "import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';\n" + content;
    }
    
    // In _generatePdf and _sharePdf, add the query for bank accounts
    content = content.replace(/final firmInfo = await FirmInfo\.getActiveFirmInfo\(prefs, isar\);/g, `final firmInfo = await FirmInfo.getActiveFirmInfo(prefs, isar);\n      final invoiceBanks = await isar.bankAccounts.filter().printOnInvoiceEqualTo(true).isDeletedEqualTo(false).findAll();`);
    
    // Pass to generateInvoicePdf
    content = content.replace(/firmInfo: firmInfo,\s*\);/g, `firmInfo: firmInfo,\n              invoiceBanks: invoiceBanks,\n            );`);
    
    // Pass to generateThermalInvoicePdf
    content = content.replace(/firmInfo: firmInfo,\s*paperSize:/g, `firmInfo: firmInfo,\n              invoiceBanks: invoiceBanks,\n              paperSize:`);

    fs.writeFileSync(file, content, 'utf8');
    console.log('Fixed bank printing in ' + file);
  }
});
