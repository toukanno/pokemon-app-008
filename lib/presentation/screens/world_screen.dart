import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/game_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/direction.dart';
import '../widgets/dpad.dart';
import '../widgets/message_box.dart';
import '../widgets/world_view.dart';

class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> {
  List<String>? _dialog;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleMove(Direction dir) {
    if (_dialog != null) return;
    final result = ref.read(gameControllerProvider.notifier).move(dir);
    switch (result) {
      case MoveResult.encounter:
        context.push('/battle');
        break;
      case MoveResult.heal:
        final ctrl = ref.read(gameControllerProvider.notifier);
        ctrl.healParty();
        setState(() => _dialog = [
              'かいふくセンターへ ようこそ！',
              'モンスターたちが すっかり げんきに なりました！',
              'また あそびに きてくださいね。',
            ]);
        break;
      case MoveResult.shop:
        context.push('/shop');
        break;
      case MoveResult.moved:
      case MoveResult.blocked:
        break;
    }
  }

  void _interact() {
    if (_dialog != null) return;
    final result = ref.read(gameControllerProvider.notifier).interactInFront();
    if (result.type != InteractionType.none) {
      setState(() => _dialog = result.lines);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      _handleMove(Direction.up);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      _handleMove(Direction.down);
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _handleMove(Direction.left);
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _handleMove(Direction.right);
    } else if (k == LogicalKeyboardKey.keyZ || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
      if (_dialog != null) return KeyEventResult.handled;
      _interact();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) {
      // セッションなし → タイトルへ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final save = session.save;
    final ctrl = ref.read(gameControllerProvider.notifier);
    final map = ctrl.currentMap;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: WorldView(
                map: map,
                playerX: save.playerX,
                playerY: save.playerY,
                facing: save.facing,
                isDark: isDark,
              ),
            ),
            // 上部情報
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _InfoChip(icon: Icons.place, label: map.name),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.paid, label: '${save.money}'),
                    const Spacer(),
                    _InfoChip(icon: Icons.menu_book, label: '${save.caught.length}/${ref.read(gameDataProvider).totalSpecies}'),
                  ],
                ),
              ),
            ),
            // メニューボタン(右上)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 44, right: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'menu',
                    onPressed: () => context.push('/menu'),
                    child: const Icon(Icons.apps),
                  ),
                ),
              ),
            ),
            // 下部コントロール
            if (_dialog == null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DPad(onDirection: _handleMove, size: 150),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RoundActionButton(
                              label: 'A',
                              color: const Color(0xFF4CAF6E),
                              onTap: _interact,
                            ),
                            const SizedBox(height: 12),
                            RoundActionButton(
                              label: '≡',
                              color: const Color(0xFF7A6FB0),
                              onTap: () => context.push('/menu'),
                              size: 48,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // 会話ダイアログ
            if (_dialog != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: MessageQueueBox(
                      messages: _dialog!,
                      charDelayMs: ref.read(settingsProvider).charDelayMs,
                      onDone: () => setState(() => _dialog = null),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
