import 'package:flutter/material.dart';

import '../../domain/entities/direction.dart';
import '../../domain/entities/game_map.dart';

/// タイルマップとプレイヤーを描画するビュー。プレイヤーを中心に表示する。
class WorldView extends StatelessWidget {
  final GameMap map;
  final int playerX;
  final int playerY;
  final Direction facing;
  final bool isDark;

  const WorldView({
    super.key,
    required this.map,
    required this.playerX,
    required this.playerY,
    required this.facing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _WorldPainter(
          map: map,
          playerX: playerX,
          playerY: playerY,
          facing: facing,
          isCave: map.kind == 'cave',
          isDark: isDark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final GameMap map;
  final int playerX;
  final int playerY;
  final Direction facing;
  final bool isCave;
  final bool isDark;

  static const double tile = 44;

  _WorldPainter({
    required this.map,
    required this.playerX,
    required this.playerY,
    required this.facing,
    required this.isCave,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final originX = size.width / 2 - (playerX + 0.5) * tile;
    final originY = size.height / 2 - (playerY + 0.5) * tile;

    // 背景(マップ外)
    canvas.drawRect(Offset.zero & size, Paint()..color = isCave ? const Color(0xFF1A1714) : const Color(0xFF2E5E34));

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final px = originX + x * tile;
        final py = originY + y * tile;
        if (px > size.width || py > size.height || px + tile < 0 || py + tile < 0) {
          continue;
        }
        _drawTile(canvas, map.rows[y][x], px, py);
      }
    }

    // NPC
    for (final npc in map.npcs) {
      final px = originX + npc.x * tile;
      final py = originY + npc.y * tile;
      _drawNpc(canvas, px, py, npc.sprite);
    }

    // プレイヤー(中心)
    _drawPlayer(canvas, size.width / 2 - tile / 2, size.height / 2 - tile / 2);

    // どうくつの くらやみ(ビネット)
    if (isCave) {
      final vignette = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.45, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, vignette);
    }
  }

  void _drawTile(Canvas canvas, String t, double px, double py) {
    final rect = Rect.fromLTWH(px, py, tile, tile);
    final ground = Paint()..color = isCave ? const Color(0xFF4A443E) : const Color(0xFF8BC773);
    canvas.drawRect(rect, ground);

    switch (t) {
      case 'T': // き
        canvas.drawCircle(rect.center.translate(0, 2), tile * 0.42, Paint()..color = const Color(0xFF2F7D3A));
        canvas.drawCircle(rect.center.translate(-6, -4), tile * 0.22, Paint()..color = const Color(0xFF3E9A4B));
        break;
      case '.': // みち
        canvas.drawRect(rect, Paint()..color = isCave ? const Color(0xFF5C554D) : const Color(0xFFD8C89A));
        break;
      case ':': // くさ(装飾)
        _grassBlades(canvas, rect, const Color(0xFF6FB45C));
        break;
      case '~': // しげみ
        canvas.drawRect(rect, Paint()..color = const Color(0xFF4F9B43));
        _grassBlades(canvas, rect, const Color(0xFF2F7A34), dense: true);
        break;
      case 'W': // みず
        canvas.drawRect(rect, Paint()..color = const Color(0xFF4A90D9));
        canvas.drawRect(rect.deflate(tile * 0.3), Paint()..color = const Color(0xFF6FB0EE));
        break;
      case 'R': // いわ(どうくつ)
        canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
            Paint()..color = const Color(0xFF6E665C));
        break;
      case 'B': // たてもの
        canvas.drawRect(rect, Paint()..color = const Color(0xFFB0A89A));
        canvas.drawRect(Rect.fromLTWH(px, py, tile, tile * 0.35), Paint()..color = const Color(0xFF8A7E6E));
        break;
      case 'H': // かいふくセンター
        _roof(canvas, rect, const Color(0xFFD94F4F));
        break;
      case 'P': // ショップ
        _roof(canvas, rect, const Color(0xFF3E78B2));
        break;
      case 'D': // ドア
        canvas.drawRect(rect.deflate(tile * 0.25), Paint()..color = const Color(0xFF6B4A2B));
        break;
      case 'F': // さく
        final p = Paint()
          ..color = const Color(0xFF9C6B3C)
          ..strokeWidth = 3;
        canvas.drawLine(rect.centerLeft, rect.centerRight, p);
        break;
      default:
        break;
    }
  }

  void _grassBlades(Canvas canvas, Rect rect, Color color, {bool dense = false}) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final n = dense ? 5 : 3;
    for (var i = 0; i < n; i++) {
      final x = rect.left + rect.width * (i + 1) / (n + 1);
      canvas.drawLine(Offset(x, rect.bottom - 4), Offset(x, rect.bottom - tile * (dense ? 0.45 : 0.3)), p);
    }
  }

  void _roof(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE8E2D2));
    final roof = Path()
      ..moveTo(rect.left, rect.top + tile * 0.45)
      ..lineTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.top + tile * 0.45)
      ..close();
    canvas.drawPath(roof, Paint()..color = color);
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - tile * 0.12, rect.bottom - tile * 0.4, tile * 0.24, tile * 0.4),
      Paint()..color = const Color(0xFF6B4A2B),
    );
  }

  void _drawNpc(Canvas canvas, double px, double py, int sprite) {
    final center = Offset(px + tile / 2, py + tile / 2);
    final colors = [const Color(0xFFE0A050), const Color(0xFFE070A0), const Color(0xFF50A0E0)];
    final c = colors[sprite % colors.length];
    canvas.drawCircle(center.translate(0, 4), tile * 0.28, Paint()..color = c);
    canvas.drawCircle(center.translate(0, -tile * 0.18), tile * 0.18, Paint()..color = const Color(0xFFF0C8A0));
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, -tile * 0.22), radius: tile * 0.2),
      3.14, 3.14, true, Paint()..color = const Color(0xFF40342A),
    );
  }

  void _drawPlayer(Canvas canvas, double px, double py) {
    final center = Offset(px + tile / 2, py + tile / 2);
    // からだ
    canvas.drawCircle(center.translate(0, 5), tile * 0.27, Paint()..color = const Color(0xFF3E78B2));
    // あたま
    canvas.drawCircle(center.translate(0, -tile * 0.16), tile * 0.19, Paint()..color = const Color(0xFFF0C8A0));
    // ぼうし
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, -tile * 0.2), radius: tile * 0.22),
      3.14, 3.14, true, Paint()..color = const Color(0xFFD94F4F),
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - tile * 0.22, center.dy - tile * 0.2, tile * 0.44, 4),
      Paint()..color = const Color(0xFFB83A3A),
    );
    // むき(三角)
    final dir = Paint()..color = Colors.white;
    final c2 = center.translate(facing.dx * tile * 0.32, facing.dy * tile * 0.32 + 2);
    canvas.drawCircle(c2, 3, dir);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) =>
      old.playerX != playerX ||
      old.playerY != playerY ||
      old.facing != facing ||
      old.map.id != map.id ||
      old.isDark != isDark;
}
