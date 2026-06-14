import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/color_utils.dart';

/// タイプを色付きのバッジで表示する。
class TypeBadge extends ConsumerWidget {
  final String type;
  final double fontSize;

  const TypeBadge({super.key, required this.type, this.fontSize = 12});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(gameDataProvider).typeChart.colors;
    final color = hexToColor(colors[type] ?? '#A8A878');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: shade(color, 0.6), width: 1.5),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: shade(color, 0.25),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 複数タイプを横並びで表示。
class TypeBadgeRow extends StatelessWidget {
  final List<String> types;
  final double fontSize;
  const TypeBadgeRow({super.key, required this.types, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [for (final t in types) TypeBadge(type: t, fontSize: fontSize)],
    );
  }
}
