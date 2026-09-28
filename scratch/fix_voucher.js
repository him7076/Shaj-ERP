const fs = require('fs');

function fixOrderNumber() {
  let f = 'lib/core/services/order_number_service.dart';
  let c = fs.readFileSync(f, 'utf8');
  let rep = `final allOrders = await isar.orders.where().findAll();
      int maxNum = 0;
      for (var order in allOrders) {
        if (order.orderNumber != null && order.orderNumber!.startsWith('SO-')) {
          final match = RegExp(r'\\d+').firstMatch(order.orderNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final numStr = (maxNum + 1).toString().padLeft(2, '0');`;
  
  c = c.replace(/final count = await isar\.orders\.filter\(\)\.isDeletedEqualTo\(false\)\.count\(\);\s*final numStr = \(count \+ 1\)\.toString\(\)\.padLeft\(2, '0'\);/, rep);
  fs.writeFileSync(f, c);
}

function fixCreditNote() {
  let f = 'lib/data/repositories/credit_note_repository_impl.dart';
  let c = fs.readFileSync(f, 'utf8');
  let rep = `final allItems = await collection.where().findAll();
      int maxNum = 0;
      for (var item in allItems) {
        if (item.creditNoteNumber != null && item.creditNoteNumber!.startsWith('CN-')) {
          final match = RegExp(r'\\d+').firstMatch(item.creditNoteNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final suffix = (maxNum + 1).toString().padLeft(2, '0');`;
      
  c = c.replace(/final count = await collection\.filter\(\)\.isDeletedEqualTo\(false\)\.count\(\);\s*final suffix = \(count \+ 1\)\.toString\(\)\.padLeft\(2, '0'\);/, rep);
  fs.writeFileSync(f, c);
}

function fixDebitNote() {
  let f = 'lib/data/repositories/debit_note_repository_impl.dart';
  let c = fs.readFileSync(f, 'utf8');
  let rep = `final allItems = await collection.where().findAll();
      int maxNum = 0;
      for (var item in allItems) {
        if (item.debitNoteNumber != null && item.debitNoteNumber!.startsWith('DN-')) {
          final match = RegExp(r'\\d+').firstMatch(item.debitNoteNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final suffix = (maxNum + 1).toString().padLeft(2, '0');`;
      
  c = c.replace(/final count = await collection\.filter\(\)\.isDeletedEqualTo\(false\)\.count\(\);\s*final suffix = \(count \+ 1\)\.toString\(\)\.padLeft\(2, '0'\);/, rep);
  fs.writeFileSync(f, c);
}

fixOrderNumber();
fixCreditNote();
fixDebitNote();
