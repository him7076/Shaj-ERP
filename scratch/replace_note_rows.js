const fs = require('fs');

const replacement = (isPurchase, itemClass) => `class PurchaseCartItemRow extends ConsumerWidget {
  final int index;
  final ${itemClass} item;
  final VoidCallback onDelete;
  final Function(double qty, double rate, double discount, double gstRate) onChanged;

  const PurchaseCartItemRow({
    Key? key,
    required this.index,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enableItemDesc = ref.watch(sharedPreferencesProvider).getBool('enable_item_wise_description') ?? false;

    DateTime? parseDate(String? d) {
      if (d == null || d.isEmpty) return null;
      try {
        final parts = d.split('/');
        if (parts.length == 2) {
          return DateTime(int.parse(parts[1]), int.parse(parts[0]));
        }
        return DateTime.parse(d);
      } catch (e) {
        return null;
      }
    }

    final double qty = item.quantity ?? 1.0;
    final double rate = item.rate ?? 0.0;
    final double discountAmount = item.discount ?? 0.0;
    final double gstPct = item.gstRate ?? 0.0;
    final double total = item.totalAmount ?? 0.0;
    final double taxAmount = item.gstAmount ?? 0.0;

    return NeuCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ref.watch(themeProvider).themeType == ThemeType.neumorphism ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.item.value == null) return;
          FullScreenItemEntry.show(
            context,
            isPurchase: ${isPurchase},
            isFixedAsset: false,
            excludeBundles: false,
            onlyBundles: false,
            initialData: FullScreenItemEntryData(
              item: item.item.value!,
              quantity: qty,
              rate: rate,
              discountAmount: discountAmount,
              discountPercent: 0.0,
              gstRate: gstPct,
              unit: item.unit ?? 'PCS',
              batchNumber: item.batchNumber,
              mfgDate: parseDate(item.mfgDate),
              expDate: parseDate(item.expiryDate),
              saleRate: item.item.value!.sellRate ?? rate,
              purchaseRate: item.item.value!.buyRate ?? 0.0,
              isSaleRateWithTax: item.item.value!.isSaleRateWithTax ?? false,
              isPurchaseRateWithTax: item.item.value!.isPurchaseRateWithTax ?? false,
            ),
            onAdd: (data) {
              item.unit = data.unit;
              item.batchNumber = data.batchNumber;
              item.mfgDate = data.mfgDate != null ? DateFormat('MM/yyyy').format(data.mfgDate!) : null;
              item.expiryDate = data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null;
              item.description = data.item.description;
              
              onChanged(data.quantity, data.rate, data.discountAmount, data.gstRate);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#\${index + 1}  ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(
                    child: Text(
                      item.itemName ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹ \${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: \${qty} \${item.unit ?? 'PCS'} x Rate: \${rate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Subtotal: \${(qty * rate).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Discount: -₹ \${discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              if (taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tax @ \${gstPct}%: +₹ \${taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              if (enableItemDesc && item.description != null && item.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Desc: \${item.description}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}`;

function processFile(file, isPurchase, itemClass) {
  if (!fs.existsSync(file)) return;
  let c = fs.readFileSync(file, 'utf8');
  const startIdx = c.indexOf(`class PurchaseCartItemRow`);
  if (startIdx === -1) return;
  
  c = c.substring(0, startIdx) + replacement(isPurchase, itemClass) + '\n';
  fs.writeFileSync(file, c);
  console.log(`Replaced PurchaseCartItemRow in ${file}`);
}

processFile('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'false', 'CreditNoteItem');
processFile('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 'true', 'DebitNoteItem');
