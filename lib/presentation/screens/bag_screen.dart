import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/status_condition.dart';
import '../widgets/monster_sprite.dart';

class BagScreen extends ConsumerWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const Scaffold(body: SizedBox());
    final bag = session.save.bag;

    return Scaffold(
      appBar: AppBar(title: const Text('どうぐ')),
      body: SafeArea(
        child: bag.isEmpty
            ? const Center(child: Text('どうぐを もっていません'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bag.length,
                itemBuilder: (context, i) {
                  final item = bag[i];
                  final def = data.items[item.id];
                  if (def == null) return const SizedBox();
                  return Card(
                    child: ListTile(
                      leading: _icon(def.category),
                      title: Text(def.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(def.description, style: const TextStyle(fontSize: 11)),
                      trailing: Text('×${item.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _useItem(context, ref, def),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _icon(ItemCategory c) {
    switch (c) {
      case ItemCategory.ball:
        return const Icon(Icons.catching_pokemon, color: Colors.red);
      case ItemCategory.heal:
        return const Icon(Icons.healing, color: Colors.green);
      case ItemCategory.statusHeal:
        return const Icon(Icons.local_pharmacy, color: Colors.purple);
      case ItemCategory.revive:
        return const Icon(Icons.favorite, color: Colors.pink);
      default:
        return const Icon(Icons.category);
    }
  }

  void _useItem(BuildContext context, WidgetRef ref, ItemDef def) async {
    if (def.category == ItemCategory.ball || def.category == ItemCategory.other) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${def.name}は フィールドでは つかえません')),
      );
      return;
    }
    final party = ref.read(gameControllerProvider)!.save.party;
    final idx = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('だれに つかう？', style: TextStyle(fontWeight: FontWeight.bold))),
          for (var i = 0; i < party.length; i++)
            ListTile(
              leading: MonsterSprite(species: party[i].species, size: 40),
              title: Text('${party[i].displayName}  Lv.${party[i].level}'),
              subtitle: Text('HP ${party[i].currentHp}/${party[i].maxHp}'
                  '${party[i].status.label.isNotEmpty ? ' (${party[i].status.label})' : ''}'),
              onTap: () => Navigator.pop(context, i),
            ),
        ],
      ),
    );
    if (idx == null) return;
    final msg = ref.read(gameControllerProvider.notifier).applyItem(def.id, party[idx]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'こうかが なかった…')),
      );
    }
  }
}
