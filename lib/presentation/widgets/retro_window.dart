import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// レトロRPG風の枠付きウィンドウ。
class RetroWindow extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? fill;

  const RetroWindow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppTheme.windowBorder(context);
    return Container(
      decoration: BoxDecoration(
        color: fill ?? AppTheme.windowFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 3),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.35),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
