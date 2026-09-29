const fs = require('fs');

function fixRepo() {
    let file = 'lib/data/repositories/transaction_repository_impl.dart';
    let code = fs.readFileSync(file, 'utf8');
    
    code = code.replace(/oldType == 'Transfer'/g, "['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(oldType)");
    code = code.replace(/type == 'Transfer'/g, "['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)");
    code = code.replace(/oldTransaction.transactionType == 'Transfer'/g, "['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(oldTransaction.transactionType)");
    code = code.replace(/transaction.transactionType == 'Transfer'/g, "['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(transaction.transactionType)");
    
    fs.writeFileSync(file, code);
    console.log('Fixed transaction_repository_impl.dart');
}

fixRepo();
