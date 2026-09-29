const fs = require('fs');
let content = fs.readFileSync('lib/core/services/sync_service.dart', 'utf-8');

// 1. Revert processEnqueuing signature
let newSig = `    Future<void> processEnqueuing<T>(
        Future<List<T>> Function(int offset, int limit) queryFn,
        String entityType,
        String? Function(T) getUuid,
        int Function(T) getId) async {`;
content = content.replace(/Future<void> processEnqueuing<T extends IsarModel>\([\s\S]*?String entityType\) async {/, newSig);

// 2. Revert inside processEnqueuing
content = content.replace(/\.\.entityId = item\.id/g, '..entityId = getId(item)');
content = content.replace(/\.\.entityUuid = item\.uuid/g, '..entityUuid = getUuid(item)');

// 3. Update all call sites to explicitly type lambdas
const entities = [
  'Party', 'Item', 'Invoice', 'Order', 'Purchase', 'Expense', 'ExpenseItem',
  'StockAdjustment', 'CreditNote', 'WhatsAppMapping', 'DebitNote', 'Transaction',
  'Category', 'Unit', 'Brand', 'Settings', 'User', 'BankAccount', 'Task', 'Machinery'
];

for (let ent of entities) {
  let regex = new RegExp(`await processEnqueuing<${ent}>\\(\\(o, l\\) => ([^,]+), '${ent}'\\);`);
  let match = content.match(regex);
  if (match) {
    let queryFn = match[1];
    
    // Add explicit typing to the where clause if it exists
    queryFn = queryFn.replace(/\.where\(\((\w+)\) =>/g, `.where((${ent} $1) =>`);

    let newLine = `await processEnqueuing<${ent}>((o, l) => ${queryFn}, '${ent}', (${ent} e) => e.uuid, (${ent} e) => e.id);`;
    content = content.replace(match[0], newLine);
  }
}

fs.writeFileSync('lib/core/services/sync_service.dart', content);
console.log('Reverted and explicitly typed');
