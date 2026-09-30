const fs = require('fs');
const path = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
let code = fs.readFileSync(path, 'utf8');

// Replace Trailing Row
code = code.replace(/trailing:\s*Row\([\s\S]*?mainAxisSize:\s*MainAxisSize\.min,[\s\S]*?children:\s*\[[\s\S]*?IconButton\([\s\S]*?edit_outlined[\s\S]*?\),[\s\S]*?IconButton\([\s\S]*?delete_outline[\s\S]*?\),[\s\S]*?\],[\s\S]*?\),/, 'trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),');

// Replace Subtitle
code = code.replace(/subtitle:\s*Padding\([\s\S]*?child:\s*Text\([\s\S]*?'\$\{acc.bankName \?\? "Bank"\} • A\/C: \$\{acc.accountNumber \?\? "N\/A"\} • IFSC: \$\{acc.ifscCode \?\? "N\/A"\}',[\s\S]*?style:\s*TextStyle\(color:\s*Colors.grey\[600\],\s*fontSize:\s*12\),[\s\S]*?\),[\s\S]*?\),/, `subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '\${acc.bankName ?? "Bank"} • A/C: \${acc.accountNumber ?? "N/A"}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),`);

// Replace Inflow Outflow block
const inflowBlockStartIdx = code.indexOf('Expanded(');
if (inflowBlockStartIdx !== -1) {
  // We can just regex replace it
  const match = code.match(/Expanded\([\s\S]*?child:\s*Column\([\s\S]*?children:\s*\[[\s\S]*?Row\([\s\S]*?Total Inflows\s*\(\+\)[\s\S]*?Text\(currencyFormat\.format\(totalInflow\)[\s\S]*?Container\(height:\s*40[\s\S]*?Expanded\([\s\S]*?Total Outflows\s*\(\-\)[\s\S]*?Text\(currencyFormat\.format\(totalOutflow\)[\s\S]*?\]\)[\s\S]*?\),/);
  
  if (match) {
    const replacement = `Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Inflows (+)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(totalInflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Outflows (-)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(totalOutflow), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, color: Colors.blueAccent, size: 14),
                              const SizedBox(width: 4),
                              const Text('Balance', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currencyFormat.format(currentBalance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentBalance >= 0 ? Colors.white : Colors.redAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),`;
    code = code.replace(match[0], replacement);
    console.log("Inflow block replaced.");
  } else {
    console.log("Inflow block NOT MATCHED");
  }
}

fs.writeFileSync(path, code);
console.log("Done.");
