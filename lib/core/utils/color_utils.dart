import 'package:flutter/material.dart';

/// "#RRGGBB" 形式の文字列を Color に変換する。
Color hexToColor(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

/// 明度を少し調整した色を返す。
Color shade(Color c, double factor) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
}
