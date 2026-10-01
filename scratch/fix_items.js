const fs = require('fs');

function fixFullScreenEntry() {
    let content = fs.readFileSync('lib/core/widgets/full_screen_item_entry.dart', 'utf8');
    
    // Add shared preferences check for purchase rate
    const buildRegex = /Widget build\(BuildContext context\)\s*\{\s*final theme = Theme\.of\(context\);\s*final itemsAsync = ref\.watch\(itemsListProvider\);/;
    content = content.replace(buildRegex, `Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsListProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final showPurchaseRate = prefs.getBool('manage_buy_price_while_entry') ?? true;`);

    // Wrap Purchase Rate with if (showPurchaseRate)
    const purchaseRowRegex = /(\/\/ PURCHASE RATE\s*\n\s*Row\([\s\S]*?\]\,\s*\)\,\s*\n\s*const SizedBox\(height: 12\)\,)/;
    content = content.replace(purchaseRowRegex, `if (showPurchaseRate) ...[
                                    $1
                                  ],`);

    fs.writeFileSync('lib/core/widgets/full_screen_item_entry.dart', content, 'utf8');
    console.log('Fixed FullScreenItemEntry');
}

function fixCreditNoteScreen() {
    let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'utf8');
    
    // Fix isPurchase and onAdd
    // Replace: isPurchase: true, \n onAdd: (data) async { ... } with _addFullScreenItemLine(data)
    
    content = content.replace(/isPurchase:\s*true/g, 'isPurchase: false');

    const onAddRegex = /onAdd:\s*\(\w+\)\s*async\s*\{[\s\S]*?_recalculateTotals\(\);\s*\}/g;
    content = content.replace(onAddRegex, `onAdd: (data) async {
        _addFullScreenItemLine(data);
      }`);

    // Let's also check if web mock isar has parentCreditNoteIdEqualTo
    // Actually, maybe parentCreditNoteUuid is better. But note.uuid is string, so we can use parentCreditNoteId.

    fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', content, 'utf8');
    console.log('Fixed Credit Note Screen');
}

function fixDebitNoteScreen() {
    let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 'utf8');
    
    // Debit note is a purchase return, so isPurchase should be TRUE. It probably already is.
    // We just need to fix the onAdd logic.

    const onAddRegex = /onAdd:\s*\(\w+\)\s*async\s*\{[\s\S]*?_recalculateTotals\(\);\s*\}/g;
    content = content.replace(onAddRegex, `onAdd: (data) async {
        _addFullScreenItemLine(data);
      }`);

    fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', content, 'utf8');
    console.log('Fixed Debit Note Screen');
}

function checkWebMockIsar() {
    let content = fs.readFileSync('lib/core/services/web_mock_isar.dart', 'utf8');
    
    // Check if parentCreditNoteIdEqualTo exists
    if (!content.includes('parentCreditNoteIdEqualTo')) {
        console.log('Warning: web_mock_isar does NOT have parentCreditNoteIdEqualTo!');
        // We can add it manually to the query class if needed
        // Or we can just use parentCreditNoteId filter using a custom extension or in web_mock_isar itself
    } else {
        console.log('web_mock_isar HAS parentCreditNoteIdEqualTo');
    }
}

fixFullScreenEntry();
fixCreditNoteScreen();
fixDebitNoteScreen();
checkWebMockIsar();
