const fs = require('fs');

function manualFetchItems() {
    let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'utf8');
    
    // Find the item fetching block
    const fetchBlock = /if\s*\(itemsList\.isEmpty\s*&&\s*pId\s*!=\s*0\s*&&\s*pId\s*!=\s*Isar\.autoIncrement\)\s*\{\s*itemsList\s*=\s*await\s*isar\.creditNoteItems\s*\.filter\(\)\s*\.parentCreditNoteIdEqualTo\(pId\)\s*\.findAll\(\);\s*\}/;

    const newFetchBlock = `if (itemsList.isEmpty && pId != 0 && pId != Isar.autoIncrement) {
          itemsList = await isar.creditNoteItems
              .filter()
              .parentCreditNoteIdEqualTo(pId)
              .findAll();
              
          if (itemsList.isEmpty) {
             // Fallback for Web Mock Isar just in case parentCreditNoteIdEqualTo fails
             final allItems = await isar.creditNoteItems.where().findAll();
             itemsList = allItems.where((e) => e.parentCreditNoteId == pId).toList();
          }
        }`;

    content = content.replace(fetchBlock, newFetchBlock);
    fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', content, 'utf8');
    console.log('Fixed Credit Note Screen Manual Fetch');
}

function manualFetchDebitItems() {
    let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 'utf8');
    
    // Find the item fetching block
    const fetchBlock = /if\s*\(itemsList\.isEmpty\s*&&\s*pId\s*!=\s*0\s*&&\s*pId\s*!=\s*Isar\.autoIncrement\)\s*\{\s*itemsList\s*=\s*await\s*isar\.debitNoteItems\s*\.filter\(\)\s*\.parentDebitNoteIdEqualTo\(pId\)\s*\.findAll\(\);\s*\}/;

    const newFetchBlock = `if (itemsList.isEmpty && pId != 0 && pId != Isar.autoIncrement) {
          itemsList = await isar.debitNoteItems
              .filter()
              .parentDebitNoteIdEqualTo(pId)
              .findAll();
              
          if (itemsList.isEmpty) {
             // Fallback for Web Mock Isar just in case parentDebitNoteIdEqualTo fails
             final allItems = await isar.debitNoteItems.where().findAll();
             itemsList = allItems.where((e) => e.parentDebitNoteId == pId).toList();
          }
        }`;

    content = content.replace(fetchBlock, newFetchBlock);
    fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', content, 'utf8');
    console.log('Fixed Debit Note Screen Manual Fetch');
}

manualFetchItems();
manualFetchDebitItems();
