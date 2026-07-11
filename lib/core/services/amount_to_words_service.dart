class AmountToWordsService {
  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  /// Converts a double monetary value into Indian Rupee text (Crores, Lakhs, Thousands)
  String convertToWords(double amount) {
    if (amount < 0) {
      return 'Negative ${convertToWords(amount.abs())}';
    }

    final integerPart = amount.truncate();
    final paisePart = ((amount - integerPart) * 100).round();

    String result = '';

    if (integerPart == 0) {
      result = 'Zero';
    } else {
      result = _convertInteger(integerPart);
    }

    result = 'Rupees $result';

    if (paisePart > 0) {
      final paiseWords = _convertInteger(paisePart);
      result += ' and $paiseWords Paise';
    }

    return '$result Only';
  }

  String _convertInteger(int number) {
    if (number == 0) return '';

    if (number < 20) {
      return _ones[number];
    }

    if (number < 100) {
      return '${_tens[number ~/ 10]}${number % 10 > 0 ? " " + _ones[number % 10] : ""}';
    }

    if (number < 1000) {
      return '${_ones[number ~/ 100]} Hundred${number % 100 > 0 ? " " + _convertInteger(number % 100) : ""}';
    }

    if (number < 100000) {
      return '${_convertInteger(number ~/ 1000)} Thousand${number % 1000 > 0 ? " " + _convertInteger(number % 1000) : ""}';
    }

    if (number < 10000000) {
      return '${_convertInteger(number ~/ 100000)} Lakh${number % 100000 > 0 ? " " + _convertInteger(number % 100000) : ""}';
    }

    // Handles Crores and above recursively
    return '${_convertInteger(number ~/ 10000000)} Crore${number % 10000000 > 0 ? " " + _convertInteger(number % 10000000) : ""}';
  }
}
