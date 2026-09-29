const fs = require('fs');

function fixTransactionsScreen() {
    let file = 'lib/features/transactions/presentation/screens/transactions_screen.dart';
    let code = fs.readFileSync(file, 'utf8');
    
    code = code.replace(/txn.transactionType == 'Transfer' \|\| txn.transactionType == 'Party Transfer'/g, 
        "['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(txn.transactionType)");
        
    fs.writeFileSync(file, code);
    console.log('Fixed transactions_screen.dart');
}

function fixManageBankScreen() {
    let file = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
    let code = fs.readFileSync(file, 'utf8');
    
    // Fix 561
    code = code.replace(/if \(t.transactionType == 'Transfer' && \(target == 'cash' \|\| target.contains\('cash'\)\)\) \{/g, 
        "if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == 'cash' || target.contains('cash'))) {");
        
    // Fix 567
    code = code.replace(/if \(t.transactionType == 'Transfer' && \(target == accName \|\| target.contains\(accName\)\)\) \{/g, 
        "if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == accName || target.contains(accName))) {");
        
    // Fix 576
    code = code.replace(/} else if \(t.transactionType == 'Transfer'\) \{/g, 
        "} else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {");
        
    // Fix 992
    code = code.replace(/if \(txn.transactionType == 'Transfer'\) \{/g, 
        "if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(txn.transactionType)) {");
        
    fs.writeFileSync(file, code);
    console.log('Fixed manage_cash_and_bank_screen.dart');
}

function fixTransactionProviders() {
    let file = 'lib/features/transactions/presentation/providers/transaction_providers.dart';
    let code = fs.readFileSync(file, 'utf8');
    
    code = code.replace(/\['Receipt', 'Payment', 'Expense', 'Transfer', 'Other Income'\].contains\(filter.transactionType\)/g, 
        "['Receipt', 'Payment', 'Expense', 'Transfer', 'Bank Transfer', 'Cash Adjustment', 'Other Income'].contains(filter.transactionType)");
        
    fs.writeFileSync(file, code);
    console.log('Fixed transaction_providers.dart');
}

fixTransactionsScreen();
fixManageBankScreen();
fixTransactionProviders();
