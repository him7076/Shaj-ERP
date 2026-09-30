import 'package:flutter/material.dart';

class RoundOffField extends StatefulWidget {
  final double value;
  final ValueChanged<String> onChanged;

  const RoundOffField({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundOffField> createState() => _RoundOffFieldState();
}

class _RoundOffFieldState extends State<RoundOffField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant RoundOffField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if the value actually changed from outside,
    // and the user is not actively typing (to prevent cursor jumping).
    final currentTextValue = double.tryParse(_controller.text) ?? 0.0;
    if ((widget.value - currentTextValue).abs() > 0.001) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      textAlign: TextAlign.end,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      onChanged: widget.onChanged,
    );
  }
}
