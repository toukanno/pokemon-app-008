import 'package:flutter/material.dart';

/// レトロRPG風のテーマ。ライト/ダーク両対応。
class AppTheme {
  AppTheme._();

  // パレット
  static const Color brandGreen = Color(0xFF4CAF6E);
  static const Color brandBlue = Color(0xFF3E78B2);
  static const Color brandRed = Color(0xFFD94F4F);
  static const Color accentYellow = Color(0xFFF2C14E);

  static const String fontFamily = 'monospace';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF14161C) : const Color(0xFFF3F1E7),
      fontFamily: fontFamily,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2A2A2A),
        displayColor: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2A2A2A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E2330) : brandBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
    );
  }

  /// レトロウィンドウの背景色
  static Color windowFill(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF20242E) : const Color(0xFFFCFBF4);
  }

  /// レトロウィンドウの枠色
  static Color windowBorder(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF5A6478) : const Color(0xFF35506B);
  }
}
