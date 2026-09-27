const fs = require('fs');
let content = fs.readFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', 'utf8');

const replacement = `      final firmInfo = await ref.read(databaseServiceProvider).getFirmInfo();
      final isar = ref.read(databaseServiceProvider).isar;
      final banks = await isar.bankAccounts.filter().printOnInvoiceEqualTo(true).findAll();
      
      final pdfData = thermalSize != null
          ? await pdfService.generateThermalInvoicePdf(
                _invoice!,
                items: _invoiceItems,
                firmInfo: firmInfo,
                paperSize: thermalSize,
              )
          : await pdfService.generateInvoicePdf(
                _invoice!,
                items: _invoiceItems,
                firmInfo: firmInfo,
                invoiceBanks: banks,
              );`;

const target1 = `      final firmInfo = await ref.read(databaseServiceProvider).getFirmInfo();
      final pdfData = thermalSize != null
          ? await pdfService.generateThermalInvoicePdf(
                _invoice!,
                items: _invoiceItems,
                firmInfo: firmInfo,
                paperSize: thermalSize,
              )
          : await pdfService.generateInvoicePdf(
                _invoice!,
                items: _invoiceItems,
                firmInfo: firmInfo,
              );`;

let lines = target1.split('\n');
let rx = lines.map(l => l.trim().replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')).join('\\s*');
let re = new RegExp(rx, 'g');
content = content.replace(re, replacement);

fs.writeFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', content);
console.log('Fixed invoice_detail_screen');
