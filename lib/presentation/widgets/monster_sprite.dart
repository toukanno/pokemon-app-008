import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../../domain/entities/monster_species.dart';

/// 種族データから決定論的に「オリジナルのモンスター・エンブレム」を描画する。
///
/// 画像アセットを一切使わず、id・カラー・シェイプ番号から手続き的に生成するため、
/// 著作権上の懸念がなく、オフラインで 150 種以上を表現できる。
class MonsterSprite extends StatelessWidget {
  final MonsterSpecies species;
  final double size;
  final bool flip;

  const MonsterSprite({
    super.key,
    required this.species,
    this.size = 96,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget sprite = CustomPaint(
      size: Size(size, size),
      painter: _MonsterPainter(
        seed: species.id,
        shape: species.spriteShape,
        primary: hexToColor(species.spriteColor),
        secondary: hexToColor(species.spriteColor2),
        legendary: species.isLegendary,
      ),
    );
    if (flip) {
      sprite = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: sprite,
      );
    }
    return SizedBox(width: size, height: size, child: sprite);
  }
}

class _MonsterPainter extends CustomPainter {
  final int seed;
  final int shape;
  final Color primary;
  final Color secondary;
  final bool legendary;

  _MonsterPainter({
    required this.seed,
    required this.shape,
    required this.primary,
    required this.secondary,
    required this.legendary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed * 9973 + 7);
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.55;
    final bodyR = w * 0.30;

    final bodyPaint = Paint()..color = primary;
    final bellyPaint = Paint()..color = shade(secondary, 1.15);
    final outline = Paint()
      ..color = shade(primary, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, w * 0.025);

    // 伝説のオーラ
    if (legendary) {
      final aura = Paint()
        ..shader = RadialGradient(
          colors: [shade(secondary, 1.3).withValues(alpha: 0.6), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.5));
      canvas.drawCircle(Offset(cx, cy), w * 0.48, aura);
    }

    // あし
    final legPaint = Paint()..color = shade(primary, 0.8);
    for (final dx in [-bodyR * 0.5, bodyR * 0.5]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, cy + bodyR * 0.85), width: w * 0.16, height: h * 0.14),
        legPaint,
      );
    }

    // しっぽ / 付属物(シェイプで変化)
    _drawAppendages(canvas, size, rng, cx, cy, bodyR, legPaint);

    // どうたい
    final bodyPath = _bodyPath(shape % 6, cx, cy, bodyR, w, h);
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outline);

    // おなかの もよう
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + bodyR * 0.25), width: bodyR * 1.0, height: bodyR * 1.2),
      bellyPaint,
    );

    // みみ / つの
    _drawHead(canvas, size, rng, cx, cy, bodyR, bodyPaint, outline);

    // め
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = const Color(0xFF202020);
    final eyeY = cy - bodyR * 0.15;
    final eyeDx = bodyR * 0.42;
    for (final s in [-1.0, 1.0]) {
      final ec = Offset(cx + s * eyeDx, eyeY);
      canvas.drawCircle(ec, bodyR * 0.22, eyeWhite);
      canvas.drawCircle(ec.translate(s * bodyR * 0.04, bodyR * 0.03), bodyR * 0.11, eyePupil);
      canvas.drawCircle(ec.translate(-s * bodyR * 0.03, -bodyR * 0.05), bodyR * 0.04, eyeWhite);
    }

    // ほっぺ
    final cheek = Paint()..color = shade(secondary, 0.9).withValues(alpha: 0.7);
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + s * bodyR * 0.7, eyeY + bodyR * 0.3), bodyR * 0.12, cheek);
    }

    // くち
    final mouth = Paint()
      ..color = shade(primary, 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.02)
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(cx - bodyR * 0.18, eyeY + bodyR * 0.45)
      ..quadraticBezierTo(cx, eyeY + bodyR * 0.62, cx + bodyR * 0.18, eyeY + bodyR * 0.45);
    canvas.drawPath(mouthPath, mouth);
  }

  Path _bodyPath(int variant, double cx, double cy, double r, double w, double h) {
    final path = Path();
    switch (variant) {
      case 0: // まる
        path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.25));
        break;
      case 1: // たまご
        path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.2, height: r * 2.7));
        break;
      case 2: // しずく
        path.moveTo(cx, cy - r * 1.4);
        path.quadraticBezierTo(cx + r * 1.5, cy, cx + r * 0.9, cy + r * 1.2);
        path.quadraticBezierTo(cx, cy + r * 1.6, cx - r * 0.9, cy + r * 1.2);
        path.quadraticBezierTo(cx - r * 1.5, cy, cx, cy - r * 1.4);
        break;
      case 3: // ましかく(まるめ)
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2.3, height: r * 2.3),
          Radius.circular(r * 0.5),
        ));
        break;
      case 4: // ひしがた
        path.moveTo(cx, cy - r * 1.4);
        path.lineTo(cx + r * 1.3, cy);
        path.lineTo(cx, cy + r * 1.4);
        path.lineTo(cx - r * 1.3, cy);
        path.close();
        break;
      default: // よこながブロブ
        path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.6, height: r * 2.1));
    }
    return path;
  }

  void _drawHead(Canvas canvas, Size size, Random rng, double cx, double cy, double r, Paint body, Paint outline) {
    final kind = shape % 4;
    final earPaint = Paint()..color = body.color;
    switch (kind) {
      case 0: // とがった みみ
        for (final s in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(cx + s * r * 0.6, cy - r * 0.9)
            ..lineTo(cx + s * r * 1.0, cy - r * 1.9)
            ..lineTo(cx + s * r * 0.2, cy - r * 1.1)
            ..close();
          canvas.drawPath(p, earPaint);
          canvas.drawPath(p, outline);
        }
        break;
      case 1: // まるい みみ
        for (final s in [-1.0, 1.0]) {
          final c = Offset(cx + s * r * 0.7, cy - r * 1.1);
          canvas.drawCircle(c, r * 0.4, earPaint);
          canvas.drawCircle(c, r * 0.4, outline);
        }
        break;
      case 2: // つの 1ぽん
        final p = Path()
          ..moveTo(cx - r * 0.15, cy - r * 1.1)
          ..lineTo(cx, cy - r * 2.0)
          ..lineTo(cx + r * 0.15, cy - r * 1.1)
          ..close();
        canvas.drawPath(p, Paint()..color = shade(secondary, 0.9));
        break;
      default: // とげ
        for (final s in [-0.5, 0.0, 0.5]) {
          final p = Path()
            ..moveTo(cx + s * r - r * 0.12, cy - r * 1.05)
            ..lineTo(cx + s * r, cy - r * 1.6)
            ..lineTo(cx + s * r + r * 0.12, cy - r * 1.05)
            ..close();
          canvas.drawPath(p, Paint()..color = shade(secondary, 0.85));
        }
    }
  }

  void _drawAppendages(Canvas canvas, Size size, Random rng, double cx, double cy, double r, Paint legPaint) {
    final kind = shape % 3;
    final armPaint = Paint()..color = shade(legPaint.color, 1.05);
    if (kind == 0) {
      // しっぽ
      final tail = Path()
        ..moveTo(cx + r * 1.0, cy + r * 0.4)
        ..quadraticBezierTo(cx + r * 2.0, cy, cx + r * 1.7, cy - r * 0.8);
      canvas.drawPath(
        tail,
        Paint()
          ..color = shade(secondary, 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.35
          ..strokeCap = StrokeCap.round,
      );
    } else if (kind == 1) {
      // つばさ
      for (final s in [-1.0, 1.0]) {
        final wing = Path()
          ..moveTo(cx + s * r * 0.9, cy)
          ..quadraticBezierTo(cx + s * r * 2.0, cy - r * 0.6, cx + s * r * 1.6, cy + r * 0.6)
          ..close();
        canvas.drawPath(wing, Paint()..color = shade(secondary, 1.1).withValues(alpha: 0.85));
      }
    } else {
      // うで
      for (final s in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + s * r * 1.25, cy + r * 0.3), width: r * 0.45, height: r * 0.8),
          armPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonsterPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.shape != shape || oldDelegate.primary != primary;
}
