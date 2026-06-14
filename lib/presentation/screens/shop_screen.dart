import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../data/datasources/item_catalog.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('フレンドリィショップ'),
          bottom: const TabBar(tabs: [Tab(text: 'かう'), Tab(text: 'うる')]),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _MoneyBar(),
              const Expanded(
                child: TabBarView(children: [_BuyTab(), _SellTab()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(gameControllerProvider)?.save.money ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Text('しょじきん: $money えん', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _BuyTab extends ConsumerWidget {
  const _BuyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final id in ItemCatalog.shopStock)
          if (data.items[id] != null)
            Card(
              child: ListTile(
                title: Text(data.items[id]!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data.items[id]!.description, style: const TextStyle(fontSize: 11)),
                trailing: Text('${data.items[id]!.price} えん'),
                onTap: () => _buy(context, ref, ctrl, id),
              ),
            ),
      ],
    );
  }

  void _buy(BuildContext context, WidgetRef ref, ctrl, String id) async {
    final def = ref.read(gameDataProvider).items[id]!;
    int qty = 1;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${def.name}を かう'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('たんか: ${def.price} えん'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setState(() => qty = (qty - 1).clamp(1, 99)), icon: const Icon(Icons.remove)),
                  Text('$qty', style: const TextStyle(fontSize: 20)),
                  IconButton(onPressed: () => setState(() => qty = (qty + 1).clamp(1, 99)), icon: const Icon(Icons.add)),
                ],
              ),
              Text('ごうけい: ${def.price * qty} えん', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('やめる')),
            FilledButton(onPressed: () => Navigator.pop(ctx, qty), child: const Text('かう')),
          ],
        ),
      ),
    );
    if (result == null) return;
    final ok = ctrl.buy(id, result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '${def.name}を $result こ かいました！' : 'おかねが たりません！')),
      );
    }
  }
}

class _SellTab extends ConsumerWidget {
  const _SellTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final bag = ref.watch(gameControllerProvider)?.save.bag ?? [];
    if (bag.isEmpty) return const Center(child: Text('うれる どうぐが ない'));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final item in bag)
          if (data.items[item.id] != null)
            Card(
              child: ListTile(
                title: Text(data.items[item.id]!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('うりね: ${data.items[item.id]!.price ~/ 2} えん'),
                trailing: Text('×${item.count}'),
                onTap: () {
                  ctrl.sell(item.id, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${data.items[item.id]!.name}を うりました')),
                  );
                },
              ),
            ),
      ],
    );
  }
}
