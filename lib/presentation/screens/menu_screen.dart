import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../widgets/retro_window.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final session = ref.watch(gameControllerProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('...')));
    }
    final save = session.save;

    return Scaffold(
      appBar: AppBar(title: const Text('メニュー')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RetroWindow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(save.playerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('しょじきん: ${save.money}えん'),
                  Text('つかまえた: ${save.caught.length} / ${ref.read(gameDataProvider).totalSpecies}'),
                  Text('てもち: ${save.party.length}ひき'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuItem(icon: Icons.pets, label: 'モンスター', onTap: () => context.push('/party')),
            _MenuItem(icon: Icons.menu_book, label: 'ずかん', onTap: () => context.push('/dex')),
            _MenuItem(icon: Icons.backpack, label: 'どうぐ', onTap: () => context.push('/bag')),
            _MenuItem(icon: Icons.inventory_2, label: 'ボックス', onTap: () => context.push('/box')),
            _MenuItem(icon: Icons.settings, label: 'せってい', onTap: () => context.push('/settings')),
            _MenuItem(
              icon: Icons.save,
              label: 'レポートを かく(セーブ)',
              onTap: () async {
                await ctrl.save_();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('レポートを かきました！')),
                  );
                }
              },
            ),
            const Divider(height: 32),
            _MenuItem(
              icon: Icons.logout,
              label: 'タイトルへ もどる',
              color: Colors.redAccent,
              onTap: () async {
                await ctrl.save_();
                ctrl.quitToTitle();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
