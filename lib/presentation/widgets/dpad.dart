import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/direction.dart';

/// 押している間くりかえし発火するボタン。
class HoldButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onFire;
  final int intervalMs;

  const HoldButton({
    super.key,
    required this.child,
    required this.onFire,
    this.intervalMs = 160,
  });

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  Timer? _timer;
  bool _pressed = false;

  void _start() {
    setState(() => _pressed = true);
    widget.onFire();
    _timer = Timer.periodic(Duration(milliseconds: widget.intervalMs), (_) => widget.onFire());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}

/// 十字キー。
class DPad extends StatelessWidget {
  final void Function(Direction) onDirection;
  final double size;

  const DPad({super.key, required this.onDirection, this.size = 160});

  Widget _arrow(Direction dir, IconData icon) {
    return HoldButton(
      onFire: () => onDirection(dir),
      child: Container(
        width: size / 3,
        height: size / 3,
        decoration: BoxDecoration(
          color: const Color(0xFF3A4150),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: size / 6),
      ),
    );
  }

  Widget _gap() => SizedBox(width: size / 3, height: size / 3);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_gap(), _arrow(Direction.up, Icons.keyboard_arrow_up), _gap()]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _arrow(Direction.left, Icons.keyboard_arrow_left),
            Container(
              width: size / 3,
              height: size / 3,
              color: const Color(0xFF2C313D),
            ),
            _arrow(Direction.right, Icons.keyboard_arrow_right),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_gap(), _arrow(Direction.down, Icons.keyboard_arrow_down), _gap()]),
        ],
      ),
    );
  }
}

/// 丸い アクションボタン(A/Bなど)。
class RoundActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const RoundActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
