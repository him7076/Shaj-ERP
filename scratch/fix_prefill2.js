const fs = require('fs');

function replaceBlock(path, isCredit) {
    let content = fs.readFileSync(path, 'utf8');
    
    // Add missing import for Random if not present (needed for _generateUuid)
    if (!content.includes('import \'dart:math\';')) {
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:math';");
    }

    const regex = /      if \(widget\.initialInvoiceNumber != null\) {[\s\S]*?setState\(\(\) {}\);\s*}/g;
    
    let prefillBlock = '';
    
    if (isCredit) {
        prefillBlock = `      if (widget.initialInvoiceNumber != null) {
        _originalBillNumberController.text = widget.initialInvoiceNumber!;
        _linkedBillUuid = widget.initialInvoiceUuid;
        
        if (widget.initialInvoiceUuid != null) {
           final inv = await isar.invoices.filter().uuidEqualTo(widget.initialInvoiceUuid!).findFirst();
           if (inv != null) {
             try { await inv.party.load(); } catch (_) {}
             Party? p = inv.party.value;
             if (p == null && inv.partyId != null && inv.partyId! > 0) p = await isar.partys.get(inv.partyId!);
             if (p == null && inv.partyName != null) p = await isar.partys.filter().partyNameEqualTo(inv.partyName!).findFirst();
             if (p != null) _selectedParty = p;
             
             List<InvoiceItem> invItems = [];
             try { await inv.invoiceItems.load(); invItems = inv.invoiceItems.toList(); } catch (_) {}
             if (invItems.isEmpty) {
               invItems = await isar.invoiceItems.filter().parentInvoiceIdEqualTo(inv.id).findAll();
             }
             
             String _genU() {
               final random = Random();
               final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
               return '\${DateTime.now().millisecondsSinceEpoch}-\${parts.join("-")}';
             }

             _draftItems = invItems.map((e) => CreditNoteItem()
                ..uuid = _genU()
                ..itemId = e.itemId
                ..itemName = e.itemName
                ..quantity = e.quantity
                ..price = e.price
                ..discountAmount = e.discountAmount
                ..discountPercent = e.discountPercent
                ..discountType = e.discountType
                ..taxRate = e.taxRate
                ..cgstAmount = e.cgstAmount
                ..sgstAmount = e.sgstAmount
                ..igstAmount = e.igstAmount
                ..taxAmount = e.taxAmount
                ..totalAmount = e.totalAmount
             ).toList();
             
             for (var pi in _draftItems) {
                var invItem = invItems.firstWhere((element) => element.itemName == pi.itemName);
                pi.item.value = invItem.item.value;
             }
             _recalculateTotals();
           }
        }
      }
      if (mounted) {
        setState(() {});
      }`;
    } else {
        prefillBlock = `      if (widget.initialInvoiceNumber != null) {
        _originalBillNumberController.text = widget.initialInvoiceNumber!;
        _linkedBillUuid = widget.initialInvoiceUuid;
        
        if (widget.initialInvoiceUuid != null) {
           final pur = await isar.purchases.filter().uuidEqualTo(widget.initialInvoiceUuid!).findFirst();
           if (pur != null) {
             try { await pur.party.load(); } catch (_) {}
             Party? p = pur.party.value;
             if (p == null && pur.partyId != null && pur.partyId! > 0) p = await isar.partys.get(pur.partyId!);
             if (p == null && pur.partyName != null) p = await isar.partys.filter().partyNameEqualTo(pur.partyName!).findFirst();
             if (p != null) _selectedParty = p;
             
             List<PurchaseItem> purItems = [];
             try { await pur.purchaseItems.load(); purItems = pur.purchaseItems.toList(); } catch (_) {}
             if (purItems.isEmpty) {
               purItems = await isar.purchaseItems.filter().parentPurchaseIdEqualTo(pur.id).findAll();
             }
             
             String _genU() {
               final random = Random();
               final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
               return '\${DateTime.now().millisecondsSinceEpoch}-\${parts.join("-")}';
             }

             _draftItems = purItems.map((e) => DebitNoteItem()
                ..uuid = _genU()
                ..itemId = e.itemId
                ..itemName = e.itemName
                ..quantity = e.quantity
                ..price = e.price
                ..discountAmount = e.discountAmount
                ..discountPercent = e.discountPercent
                ..discountType = e.discountType
                ..taxRate = e.taxRate
                ..cgstAmount = e.cgstAmount
                ..sgstAmount = e.sgstAmount
                ..igstAmount = e.igstAmount
                ..taxAmount = e.taxAmount
                ..totalAmount = e.totalAmount
             ).toList();
             
             for (var pi in _draftItems) {
                var pItem = purItems.firstWhere((element) => element.itemName == pi.itemName);
                pi.item.value = pItem.item.value;
             }
             _recalculateTotals();
           }
        }
      }
      if (mounted) {
        setState(() {});
      }`;
    }

    if (regex.test(content)) {
        content = content.replace(regex, prefillBlock);
        fs.writeFileSync(path, content, 'utf8');
        console.log('Fixed prefill logic in ' + path);
    } else {
        console.log('Could not find target block using regex in ' + path);
    }
}

replaceBlock('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
replaceBlock('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
