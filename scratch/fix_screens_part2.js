const fs = require('fs');
let content = fs.readFileSync('lib/features/orders/presentation/providers/order_providers.dart', 'utf8');

const replacement = `
  double get totalAmount {
    final subtotal = (quantity * rate) - discountAmount;
    final tax = (subtotal * gstPercent) / 100;
    return subtotal + tax;
  }

  double get taxAmount {
    final subtotal = (quantity * rate) - discountAmount;
    return (subtotal * gstPercent) / 100;
  }

  const CartItemState({`;

content = content.replace('  const CartItemState({', replacement);

fs.writeFileSync('lib/features/orders/presentation/providers/order_providers.dart', content);
console.log('Added totalAmount and taxAmount getters to CartItemState');
