import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/monster_instance.dart';
import '../../domain/entities/move.dart';
import '../widgets/hp_bar.dart';
import '../widgets/monster_sprite.dart';
import '../widgets/retro_window.dart';
import '../widgets/type_badge.dart';

class PartyScreen extends ConsumerWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const Scaffold(body: SizedBox());
    final party = session.save.party;

    return Scaffold(
      appBar: AppBar(title: Text('てもち モンスター (${party.length})')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: party.length,
          itemBuilder: (context, i) {
            final mon = party[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: MonsterSprite(species: mon.species, size: 52),
                title: Row(
                  children: [
                    Text(mon.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('Lv.${mon.level}'),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    HpBar(ratio: mon.hpRatio, width: 140),
                    Text('${mon.currentHp}/${mon.maxHp}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _action(context, ref, ctrl, i, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'detail', child: Text('つよさをみる')),
                    if (i > 0) const PopupMenuItem(value: 'up', child: Text('うえへ')),
                    if (i < party.length - 1) const PopupMenuItem(value: 'down', child: Text('したへ')),
                    if (party.length > 1) const PopupMenuItem(value: 'box', child: Text('ボックスへ')),
                  ],
                ),
                onTap: () => _showDetail(context, ref, mon),
              ),
            );
          },
        ),
      ),
    );
  }

  void _action(BuildContext context, WidgetRef ref, ctrl, int i, String v) {
    switch (v) {
      case 'detail':
        _showDetail(context, ref, ref.read(gameControllerProvider)!.save.party[i]);
        break;
      case 'up':
        ctrl.swapPartyOrder(i, i - 1);
        break;
      case 'down':
        ctrl.swapPartyOrder(i, i + 1);
        break;
      case 'box':
        if (!ctrl.sendToBox(i)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('さいごの1ぴきは ボックスに いれられません')),
          );
        }
        break;
    }
  }

  void _showDetail(BuildContext context, WidgetRef ref, MonsterInstance mon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MonsterStatusSheet(mon: mon),
    );
  }
}

class MonsterStatusSheet extends ConsumerWidget {
  final MonsterInstance mon;
  const MonsterStatusSheet({super.key, required this.mon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: MonsterSprite(species: mon.species, size: 120)),
            const SizedBox(height: 8),
            Center(
              child: Text('${mon.displayName}  Lv.${mon.level}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Center(child: Text('No.${mon.species.id}  ${mon.species.category}')),
            const SizedBox(height: 8),
            Center(child: TypeBadgeRow(types: mon.species.types)),
            const SizedBox(height: 12),
            RetroWindow(
              child: Column(
                children: [
                  _statRow('HP', mon.currentHp, mon.maxHp),
                  _stat('こうげき', mon.attack),
                  _stat('ぼうぎょ', mon.defense),
                  _stat('とくしゅ', mon.special),
                  _stat('すばやさ', mon.speed),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('けいけんち'),
                      const Spacer(),
                      Expanded(flex: 2, child: ExpBar(ratio: mon.expRatio, width: 120)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('おぼえている わざ', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            for (final lm in mon.moves) _moveTile(context, data.move(lm.moveId), lm.currentPp, lm.maxPp),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int cur, int max) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Text(label), const Spacer(), Text('$cur / $max', style: const TextStyle(fontWeight: FontWeight.bold))]),
      );

  Widget _stat(String label, int v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Text(label), const Spacer(), Text('$v', style: const TextStyle(fontWeight: FontWeight.bold))]),
      );

  Widget _moveTile(BuildContext context, Move move, int pp, int maxPp) {
    return Card(
      child: ListTile(
        dense: true,
        title: Text(move.name),
        subtitle: Text(move.description, style: const TextStyle(fontSize: 11)),
        leading: TypeBadge(type: move.type, fontSize: 10),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('いりょく ${move.power == 0 ? '-' : move.power}', style: const TextStyle(fontSize: 10)),
            Text('PP $pp/$maxPp', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
