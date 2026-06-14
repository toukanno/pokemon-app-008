import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/monster_species.dart';
import '../widgets/monster_sprite.dart';
import '../widgets/retro_window.dart';
import '../widgets/type_badge.dart';

class DexDetailScreen extends ConsumerWidget {
  final int speciesId;
  const DexDetailScreen({super.key, required this.speciesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final species = data.species(speciesId);
    final caught = ref.watch(gameControllerProvider)?.save.caught ?? <int>{};

    return Scaffold(
      appBar: AppBar(title: Text('No.${species.id.toString().padLeft(3, '0')}  ${species.name}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: MonsterSprite(species: species, size: 150)),
            const SizedBox(height: 8),
            Center(
              child: Text(species.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Center(child: Text(species.category)),
            const SizedBox(height: 8),
            Center(child: TypeBadgeRow(types: species.types, fontSize: 13)),
            if (species.isLegendary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Chip(label: Text('でんせつ'), backgroundColor: Color(0xFFF2C14E)),
                ),
              ),
            const SizedBox(height: 16),
            RetroWindow(
              child: Text(species.dexEntry, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 12),
            RetroWindow(
              child: Column(
                children: [
                  Row(children: [const Text('たかさ'), const Spacer(), Text('${species.height} m')]),
                  Row(children: [const Text('おもさ'), const Spacer(), Text('${species.weight} kg')]),
                  const Divider(),
                  _stat('HP', species.baseStats.hp),
                  _stat('こうげき', species.baseStats.attack),
                  _stat('ぼうぎょ', species.baseStats.defense),
                  _stat('とくしゅ', species.baseStats.special),
                  _stat('すばやさ', species.baseStats.speed),
                  const Divider(),
                  Row(children: [
                    const Text('しゅぞくち ごうけい'),
                    const Spacer(),
                    Text('${species.baseStats.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (species.canEvolve) _evolution(context, data, species, caught),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('おぼえる わざ', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            for (final entry in species.learnset)
              ListTile(
                dense: true,
                leading: Text('Lv.${entry.level}', style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(data.move(entry.moveId).name),
                trailing: TypeBadge(type: data.move(entry.moveId).type, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: (v / 130).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('$v', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _evolution(BuildContext context, data, MonsterSpecies species, Set<int> caught) {
    final next = data.species(species.evolveTo!);
    return RetroWindow(
      child: Row(
        children: [
          Column(
            children: [
              MonsterSprite(species: species, size: 56),
              Text(species.name, style: const TextStyle(fontSize: 11)),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.arrow_forward),
              Text('Lv.${species.evolveLevel}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          Column(
            children: [
              MonsterSprite(species: next, size: 56),
              Text(caught.contains(next.id) ? next.name : '???', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
