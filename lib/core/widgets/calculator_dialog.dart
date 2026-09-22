import 'package:flutter/material.dart';

class CalculatorDialog extends StatefulWidget {
  final double? initialValue;
  const CalculatorDialog({Key? key, this.initialValue}) : super(key: key);

  static Future<double?> show(BuildContext context, {double? initialValue}) {
    return showDialog<double>(
      context: context,
      builder: (context) => CalculatorDialog(initialValue: initialValue),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  double _firstOperand = 0;
  String _operator = '';
  bool _waitForNewOperand = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _display = _formatNumber(widget.initialValue!);
    }
  }

  String _formatNumber(double num) {
    if (num == num.toInt()) return num.toInt().toString();
    return num.toString();
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_waitForNewOperand) {
        _display = digit;
        _waitForNewOperand = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onDotPress() {
    setState(() {
      if (_waitForNewOperand) {
        _display = '0.';
        _waitForNewOperand = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperatorPress(String op) {
    setState(() {
      if (_operator.isNotEmpty && !_waitForNewOperand) {
        _calculateResult();
      } else {
        _firstOperand = double.tryParse(_display) ?? 0;
      }
      _operator = op;
      _waitForNewOperand = true;
    });
  }

  void _calculateResult() {
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;
    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case 'x':
      case '*':
        result = _firstOperand * secondOperand;
        break;
      case '/':
        result = secondOperand == 0 ? 0 : _firstOperand / secondOperand;
        break;
      default:
        return;
    }
    _display = _formatNumber(result);
    _firstOperand = result;
    _operator = '';
    _waitForNewOperand = true;
  }

  void _onEqualPress() {
    setState(() {
      _calculateResult();
      _operator = '';
    });
  }

  void _onClearPress() {
    setState(() {
      _display = '0';
      _firstOperand = 0;
      _operator = '';
      _waitForNewOperand = false;
    });
  }

  void _onDone() {
    final result = double.tryParse(_display);
    Navigator.of(context).pop(result);
  }

  Widget _buildButton(String text, {Color? color, Color? textColor, VoidCallback? onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed ?? () => _onDigitPress(text),
          child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                _buildButton('C', color: Colors.red.shade100, textColor: Colors.red, onPressed: _onClearPress),
                _buildButton('/', color: theme.colorScheme.primaryContainer, textColor: theme.colorScheme.onPrimaryContainer, onPressed: () => _onOperatorPress('/')),
                _buildButton('x', color: theme.colorScheme.primaryContainer, textColor: theme.colorScheme.onPrimaryContainer, onPressed: () => _onOperatorPress('x')),
                _buildButton('Done', color: theme.colorScheme.primary, textColor: theme.colorScheme.onPrimary, onPressed: _onDone),
              ],
            ),
            Row(
              children: [
                _buildButton('7'), _buildButton('8'), _buildButton('9'),
                _buildButton('-', color: theme.colorScheme.primaryContainer, textColor: theme.colorScheme.onPrimaryContainer, onPressed: () => _onOperatorPress('-')),
              ],
            ),
            Row(
              children: [
                _buildButton('4'), _buildButton('5'), _buildButton('6'),
                _buildButton('+', color: theme.colorScheme.primaryContainer, textColor: theme.colorScheme.onPrimaryContainer, onPressed: () => _onOperatorPress('+')),
              ],
            ),
            Row(
              children: [
                _buildButton('1'), _buildButton('2'), _buildButton('3'),
                _buildButton('=', color: theme.colorScheme.secondaryContainer, textColor: theme.colorScheme.onSecondaryContainer, onPressed: _onEqualPress),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 2, child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _onDigitPress('0'),
                    child: const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                )),
                _buildButton('.', onPressed: _onDotPress),
                Expanded(child: Container()), // Empty space to align with =
              ],
            ),
          ],
        ),
      ),
    );
  }
}
