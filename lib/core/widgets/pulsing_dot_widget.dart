import 'package:flutter/material.dart';

class PulsingDotWidget extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDotWidget({
    Key? key,
    this.color = const Color(0xFF10B981),
    this.size = 10.0,
  }) : super(key: key);

  @override
  State<PulsingDotWidget> createState() => _PulsingDotWidgetState();
}

class _PulsingDotWidgetState extends State<PulsingDotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulseVal = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing ring
            Container(
              width: widget.size + (pulseVal * 8),
              height: widget.size + (pulseVal * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(1.0 - pulseVal),
              ),
            ),
            // Inner solid core dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
