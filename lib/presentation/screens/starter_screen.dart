import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../domain/entities/monster_species.dart';
import '../widgets/message_box.dart';
import '../widgets/monster_sprite.dart';
import '../widgets/retro_window.dart';
import '../widgets/type_badge.dart';

class StarterScreen extends ConsumerStatefulWidget {
  const StarterScreen({super.key});

  @override
  ConsumerState<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends ConsumerState<StarterScreen> {
  final _nameController = TextEditingController(text: 'トレーナー');
  int _selected = 1; // species id

  static const _starterIds = [1, 4, 7];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider);
    final selectedSpecies = data.species(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('はじめての パートナー')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MessageQueueBox(
                charDelayMs: 14,
                messages: [
                  'ようこそ！ モンスターの せかいへ！',
                  'これから ぼうけんを ともにする パートナーを 1ぴき えらぼう。',
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'なまえ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final id in _starterIds)
                    Expanded(
                      child: _StarterChoice(
                        species: data.species(id),
                        selected: _selected == id,
                        onTap: () => setState(() => _selected = id),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              RetroWindow(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(selectedSpecies.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TypeBadgeRow(types: selectedSpecies.types),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(selectedSpecies.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(selectedSpecies.dexEntry, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: Text('${selectedSpecies.name}と ぼうけんに でる！'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() async {
    await ref.read(gameControllerProvider.notifier).newGame(_nameController.text.trim(), _selected);
    if (mounted) context.go('/world');
  }
}

class _StarterChoice extends StatelessWidget {
  final MonsterSpecies species;
  final bool selected;
  final VoidCallback onTap;

  const _StarterChoice({required this.species, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            MonsterSprite(species: species, size: 80),
            Text(species.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
