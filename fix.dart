import 'dart:io';

void main() {
  final files = [
    'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
    'lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart',
    'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart'
  ];

  for (var fPath in files) {
    final f = File(fPath);
    if (!f.existsSync()) continue;
    var text = f.readAsStringSync();

    // 1. Update invoice_cart_provider logic in add_edit_invoice_screen
    if (fPath.contains('invoice')) {
      final oldLogic = '''                            onPressed: (idx) {
                                  setState(() {
                                    
                                  _isDiscountPercent = idx == 0;
                                  // trigger re-calc
                                  final double? amt = double.tryParse(_discountController.text);
                                  if (_isDiscountPercent) {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(amt, null);
                                  } else {
                                    ref.read(invoiceCartProvider.notifier).setDiscounts(null, amt);
                                  }
                                
                                  });
                            },''';
      final newLogic = '''                            onPressed: (idx) {
                                  setState(() {
                                    bool newIsPercent = idx == 0;
                                    if (newIsPercent == _isDiscountPercent) return;
                                    
                                    final totals = ref.read(invoiceCartProvider.notifier).calculateTotals(null);
                                    final double currentCalculatedDiscount = totals['discountAmount'] ?? 0.0;
                                    final double subtotalAndGst = (totals['taxableAmount'] ?? 0.0) + (totals['totalGstAmount'] ?? 0.0);
                                    
                                    _isDiscountPercent = newIsPercent;
                                    
                                    if (_isDiscountPercent) {
                                       double percent = 0.0;
                                       if (subtotalAndGst > 0) percent = (currentCalculatedDiscount / subtotalAndGst) * 100.0;
                                       _discountController.text = (percent % 1 == 0) ? percent.toInt().toString() : percent.toStringAsFixed(2);
                                       ref.read(invoiceCartProvider.notifier).setDiscounts(percent, 0.0);
                                    } else {
                                       _discountController.text = (currentCalculatedDiscount % 1 == 0) ? currentCalculatedDiscount.toInt().toString() : currentCalculatedDiscount.toStringAsFixed(2);
                                       ref.read(invoiceCartProvider.notifier).setDiscounts(0.0, currentCalculatedDiscount);
                                    }
                                  });
                            },''';
      text = text.replaceAll(oldLogic, newLogic);
    } 
    // 2. Update local _recalculateTotals logic in purchase, credit, debit
    else {
      final oldLogicLocal = '''                            onPressed: (idx) {
                                  setState(() {
                                    
                                  _isDiscountPercent = idx == 0;
                                  _recalculateTotals();
                                
                                  });
                            },''';
      final newLogicLocal = '''                            onPressed: (idx) {
                                  setState(() {
                                    bool newIsPercent = idx == 0;
                                    if (newIsPercent == _isDiscountPercent) return;
                                    
                                    _isDiscountPercent = newIsPercent;
                                    
                                    if (_isDiscountPercent) {
                                       double percent = 0.0;
                                       if (_subtotal > 0) percent = (_discountAmount / _subtotal) * 100.0;
                                       _discountController.text = (percent % 1 == 0) ? percent.toInt().toString() : percent.toStringAsFixed(2);
                                    } else {
                                       _discountController.text = (_discountAmount % 1 == 0) ? _discountAmount.toInt().toString() : _discountAmount.toStringAsFixed(2);
                                    }
                                    _recalculateTotals();
                                  });
                            },''';
      text = text.replaceAll(oldLogicLocal, newLogicLocal);
    }

    f.writeAsStringSync(text);
  }

  // 3. Update providers
  final providerFiles = [
    'lib/features/sales/presentation/providers/invoice_providers.dart',
    'lib/features/transactions/presentation/providers/transaction_providers.dart'
  ];

  for (var pPath in providerFiles) {
    final p = File(pPath);
    if (!p.existsSync()) continue;
    var pText = p.readAsStringSync();
    
    final oldProv = '''  void setDiscounts(double? percent, double? amount) {
    state = state.copyWith(
      discountPercent: percent ?? state.discountPercent,
      discountAmount: amount ?? state.discountAmount,
    );
  }''';
    final newProv = '''  void setDiscounts(double? percent, double? amount) {
    state = state.copyWith(
      discountPercent: percent ?? 0.0,
      discountAmount: amount ?? 0.0,
    );
  }''';
    pText = pText.replaceAll(oldProv, newProv);
    p.writeAsStringSync(pText);
  }
}
