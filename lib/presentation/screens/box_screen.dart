import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants/game_constants.dart';
import '../widgets/hp_bar.dart';
import '../widgets/monster_sprite.dart';

class BoxScreen extends ConsumerWidget {
  const BoxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(gameControllerProvider.notifier);
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const Scaffold(body: SizedBox());
    final box = session.save.box;
    final partyFull = session.save.party.length >= GameConstants.maxPartySize;

    return Scaffold(
      appBar: AppBar(title: Text('ボックス (${box.length}/${GameConstants.boxCapacity})')),
      body: SafeArea(
        child: box.isEmpty
            ? const Center(child: Text('ボックスは からっぽです'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: box.length,
                itemBuilder: (context, i) {
                  final mon = box[i];
                  return Card(
                    child: InkWell(
                      onTap: () {
                        if (partyFull) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('てもちが いっぱいです(6ひき)')),
                          );
                          return;
                        }
                        ctrl.withdrawFromBox(i);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${mon.displayName}を てもちに くわえた！')),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MonsterSprite(species: mon.species, size: 56),
                          Text(mon.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Lv.${mon.level}', style: const TextStyle(fontSize: 10)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: HpBar(ratio: mon.hpRatio, width: 60, height: 5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
