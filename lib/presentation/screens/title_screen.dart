import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/monster_sprite.dart';
import '../widgets/retro_window.dart';

class TitleScreen extends ConsumerWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final hasSave = controller.hasSavedGame();
    // 表紙モンスター(御三家の最終進化)
    final cover = data.speciesById[6] ?? data.speciesList.first;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1A2030), const Color(0xFF0E1018)]
                : [const Color(0xFF8FD0E8), const Color(0xFFE8F4DA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    GameConstants.appTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandBlue,
                      shadows: const [Shadow(color: Colors.white70, offset: Offset(2, 2))],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '〜 ${GameConstants.regionName}の ぼうけん 〜',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  MonsterSprite(species: cover, size: 160),
                  const SizedBox(height: 24),
                  RetroWindow(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSave) ...[
                          _MenuButton(
                            label: 'つづきから',
                            icon: Icons.play_arrow,
                            onTap: () {
                              if (controller.continueGame()) {
                                context.go('/world');
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        _MenuButton(
                          label: 'さいしょから',
                          icon: Icons.fiber_new,
                          onTap: () => _startNew(context, hasSave),
                        ),
                        const SizedBox(height: 10),
                        _MenuButton(
                          label: 'せってい',
                          icon: Icons.settings,
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'モンスター ${data.totalSpecies}しゅるい しゅうろく',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Text(
                    '※ 本作は 完全オリジナル作品です',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startNew(BuildContext context, bool hasSave) async {
    if (hasSave) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('かくにん'),
          content: const Text('あたらしく はじめると いまの セーブデータは きえてしまいます。よろしいですか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('はじめる')),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (context.mounted) context.go('/starter');
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }
}
