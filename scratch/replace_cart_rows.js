const fs = require('fs');

const replacement = (className, providerName, isPurchase, itemNameProp = 'itemName') => `class ${className} extends ConsumerWidget {
  final bool isFixedAsset;
  final int index;
  final CartItemState cartItem;
  final bool isGstInclusive;
  const ${className}({Key? key, required this.index, required this.cartItem, required this.isGstInclusive, this.isFixedAsset = false}) : super(key: key);

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
          FullScreenItemEntry.show(
            context,
            isPurchase: ${isPurchase},
            isFixedAsset: isFixedAsset,
            excludeBundles: !(cartItem.item.isBundle ?? false),
            onlyBundles: cartItem.item.isBundle ?? false,
            initialData: FullScreenItemEntryData(
              item: cartItem.item,
              quantity: cartItem.quantity,
              rate: cartItem.rate,
              discountAmount: cartItem.discountAmount,
              discountPercent: cartItem.discountPercent,
              gstRate: cartItem.gstPercent,
              unit: cartItem.unit ?? 'PCS',
              batchNumber: cartItem.batchNumber,
              mfgDate: parseDate(cartItem.mfgDate),
              expDate: parseDate(cartItem.expiryDate),
              saleRate: cartItem.item.sellRate ?? cartItem.rate,
              purchaseRate: cartItem.item.buyRate ?? 0.0,
              isSaleRateWithTax: cartItem.item.isSaleRateWithTax ?? false,
              isPurchaseRateWithTax: cartItem.item.isPurchaseRateWithTax ?? false,
            ),
            onAdd: (data) {
              ref.read(${providerName}.notifier).updateItemAt(
                index,
                quantity: data.quantity,
                unit: data.unit,
                rate: data.rate,
                buyRate: data.purchaseRate,
                discountPercent: data.discountPercent,
                discountAmount: data.discountAmount,
                batchNumber: data.batchNumber,
                mfgDate: data.mfgDate != null ? DateFormat('MM/yyyy').format(data.mfgDate!) : null,
                expiryDate: data.expDate != null ? DateFormat('MM/yyyy').format(data.expDate!) : null,
              );
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
                      cartItem.item.${itemNameProp},
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹ \${cartItem.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => ref.read(${providerName}.notifier).removeItemAt(index),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: \${cartItem.quantity} \${cartItem.unit ?? 'PCS'} x Rate: \${cartItem.rate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Subtotal: \${(cartItem.quantity * cartItem.rate).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (cartItem.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Discount: -₹ \${cartItem.discountAmount.toStringAsFixed(2)}\${cartItem.discountPercent > 0 ? ' (\${cartItem.discountPercent.toStringAsFixed(2)}%)' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              if (cartItem.taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Tax @ \${cartItem.gstPercent}%: +₹ \${cartItem.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              if (enableItemDesc && cartItem.description != null && cartItem.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Desc: \${cartItem.description}',
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

function processFile(file, className, providerName, isPurchase, itemNameProp = 'itemName') {
  if (!fs.existsSync(file)) return;
  let c = fs.readFileSync(file, 'utf8');
  const startIdx = c.indexOf(`class ${className}`);
  if (startIdx === -1) return;
  
  c = c.substring(0, startIdx) + replacement(className, providerName, isPurchase, itemNameProp) + '\n';
  fs.writeFileSync(file, c);
  console.log(`Replaced ${className} in ${file}`);
}

processFile('lib/features/sales/presentation/screens/add_edit_invoice_screen.dart', 'InvoiceCartItemRow', 'invoiceCartProvider', 'false');
processFile('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 'PurchaseCartItemRow', 'purchaseCartProvider', 'true');
processFile('lib/features/orders/presentation/screens/add_edit_order_screen.dart', 'OrderCartItemRow', 'orderCartProvider', 'false');
processFile('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'CreditNoteCartItemRow', 'creditNoteCartProvider', 'false');
processFile('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 'DebitNoteCartItemRow', 'debitNoteCartProvider', 'true');
