import 'package:flutter/material.dart';

/// HPバー(残量で色が変わる)。
class HpBar extends StatelessWidget {
  final double ratio;
  final double height;
  final double width;

  const HpBar({super.key, required this.ratio, this.height = 8, this.width = 120});

  Color get _color {
    if (ratio > 0.5) return const Color(0xFF49C24D);
    if (ratio > 0.2) return const Color(0xFFF2C14E);
    return const Color(0xFFD94F4F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: ratio, end: ratio),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 経験値バー
class ExpBar extends StatelessWidget {
  final double ratio;
  final double width;
  const ExpBar({super.key, required this.ratio, this.width = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: ratio.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF49A7D9),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
