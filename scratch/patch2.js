const fs = require('fs');
const path = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
let lines = fs.readFileSync(path, 'utf8').split(/\r?\n/);

let start = -1;
let end = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('trailing: Row(') && lines[i + 1] && lines[i + 1].includes('mainAxisSize: MainAxisSize.min') && lines[i + 3] && lines[i + 3].includes('icon: const Icon(Icons.edit_outlined')) {
    start = i;
    end = i + 14;
    break;
  }
}
if (start !== -1) {
  lines.splice(start, end - start + 1, '                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),');
  console.log('Replaced trailing buttons.');
} else {
  console.log('Not found edit block');
}

let start2 = -1;
let end2 = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('Expanded(') && lines[i + 1] && lines[i + 1].includes('child: Column(') && lines[i + 7] && lines[i + 7].includes('Total Inflows (+)')) {
    start2 = i;
    end2 = i + 35;
    break;
  }
}

if (start2 !== -1) {
  lines.splice(start2, end2 - start2 + 1, `Expanded(
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
                    ),`);
  console.log('Replaced inflow/outflow block.');
} else {
  console.log('Not found inflow block');
}

fs.writeFileSync(path, lines.join('\n'));
