import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../widgets/monster_sprite.dart';

class DexScreen extends ConsumerWidget {
  const DexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final session = ref.watch(gameControllerProvider);
    final seen = session?.save.seen ?? <int>{};
    final caught = session?.save.caught ?? <int>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('ずかん'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'みつけた: ${seen.length}    つかまえた: ${caught.length} / ${data.totalSpecies}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.82,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: data.speciesList.length,
          itemBuilder: (context, i) {
            final species = data.speciesList[i];
            final isSeen = seen.contains(species.id);
            final isCaught = caught.contains(species.id);
            return InkWell(
              onTap: isSeen ? () => context.push('/dex/${species.id}') : null,
              child: Card(
                color: isCaught ? Theme.of(context).colorScheme.primaryContainer : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No.${species.id.toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 10)),
                    if (isSeen)
                      MonsterSprite(species: species, size: 56)
                    else
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.help_outline, size: 40, color: Colors.grey),
                      ),
                    Text(
                      isSeen ? species.name : '???',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    if (isCaught)
                      const Icon(Icons.check_circle, size: 14, color: Colors.green)
                    else
                      const SizedBox(height: 14),
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
