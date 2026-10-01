const fs = require('fs');

function fixCompilationErrors(path, isCredit) {
    let content = fs.readFileSync(path, 'utf8');

    // Fix imports
    if (isCredit) {
        if (!content.includes("import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';")) {
            content = content.replace(
                "import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';",
                "import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';\nimport 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';"
            );
        }
    } else {
        if (!content.includes("import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';")) {
            content = content.replace(
                "import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';",
                "import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';\nimport 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';"
            );
        }
    }

    // Insert _linkedBillUuid
    if (!content.includes('String? _linkedBillUuid;')) {
        content = content.replace(
            'final _originalBillNumberController = TextEditingController();',
            'final _originalBillNumberController = TextEditingController();\n  String? _linkedBillUuid;'
        );
    }

    // Fix prefill logic properties mapping
    if (isCredit) {
        content = content.replace('isar.invoiceItems', 'isar.collection<InvoiceItem>()');
        content = content.replace(/\.\.price = e\.price[\s\S]*?\.\.totalAmount = e\.totalAmount/, `..rate = e.price
                ..discount = e.discountAmount
                ..gstRate = e.taxRate
                ..gstAmount = e.taxAmount
                ..totalAmount = e.totalAmount`);
        content = content.replace('invItems.firstWhere((element) => element.itemName == pi.itemName);', 'invItems.firstWhere((element) => element.itemName == pi.itemName, orElse: () => invItems.first);');
    } else {
        content = content.replace('isar.purchaseItems', 'isar.collection<PurchaseItem>()');
        content = content.replace(/\.\.price = e\.price[\s\S]*?\.\.totalAmount = e\.totalAmount/, `..rate = e.price
                ..discount = e.discountAmount
                ..gstRate = e.taxRate
                ..gstAmount = e.taxAmount
                ..totalAmount = e.totalAmount`);
        content = content.replace('purItems.firstWhere((element) => element.itemName == pi.itemName);', 'purItems.firstWhere((element) => element.itemName == pi.itemName, orElse: () => purItems.first);');
    }

    // Fix `isLinked` checks that used _originalBillNumberController in build method 
    // They are correctly replaced by fix_link_logic.js if they existed, but earlier they might not have been
    const oldConditionCredit = `final isLinked = _originalBillNumberController.text == (true ? bill.invoiceNumber : bill.purchaseNumber);`;
    const oldConditionDebit = `final isLinked = _originalBillNumberController.text == (false ? bill.invoiceNumber : bill.purchaseNumber);`;
    content = content.replace(oldConditionCredit, `final isLinked = _linkedBillUuid == bill.uuid;`);
    content = content.replace(oldConditionDebit, `final isLinked = _linkedBillUuid == bill.uuid;`);
    
    // Fix pending amount conditions in build method
    const oldPendingCondCredit1 = `return pendingAmount > 0 || _originalBillNumberController.text == inv.invoiceNumber;`;
    const oldPendingCondCredit2 = `return pendingAmount > 0 || _originalBillNumberController.text == pur.purchaseNumber;`;
    content = content.replace(oldPendingCondCredit1, `return pendingAmount > 0 || _linkedBillUuid == inv.uuid;`);
    content = content.replace(oldPendingCondCredit2, `return pendingAmount > 0 || _linkedBillUuid == pur.uuid;`);

    // Fix onChange inside showModal
    if (isCredit) {
        const oldOnChange = `                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  }`;
        const newOnChange = `                                  if (val == true) {
                                    _linkedBillUuid = bill.uuid;
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = bill.uuid;
                                    }
                                  } else {
                                    _linkedBillUuid = null;
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  }`;
        content = content.replace(oldOnChange, newOnChange);
    } else {
        const oldOnChange = `                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  }`;
        const newOnChange = `                                  if (val == true) {
                                    _linkedBillUuid = bill.uuid;
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = bill.uuid;
                                    }
                                  } else {
                                    _linkedBillUuid = null;
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  }`;
        content = content.replace(oldOnChange, newOnChange);
    }

    fs.writeFileSync(path, content, 'utf8');
    console.log('Fixed compilation errors in ' + path);
}

fixCompilationErrors('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
fixCompilationErrors('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
