import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../domain/entities/battle_state.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/monster_instance.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/status_condition.dart';
import '../widgets/hp_bar.dart';
import '../widgets/message_box.dart';
import '../widgets/monster_sprite.dart';
import '../widgets/retro_window.dart';
import '../widgets/type_badge.dart';

enum _Mode { message, command, chooseMove, chooseItem, chooseSwitch }

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  _Mode _mode = _Mode.message;
  bool _forcedSwitch = false;

  void _onMessagesDone() {
    final st = ref.read(battleControllerProvider);
    final battle = ref.read(battleControllerProvider.notifier);
    if (st == null) {
      _exit();
      return;
    }
    switch (st.outcome) {
      case BattleOutcome.won:
      case BattleOutcome.fled:
      case BattleOutcome.caught:
        battle.endBattle();
        _exit();
        return;
      case BattleOutcome.lost:
        ref.read(gameControllerProvider.notifier).whiteout();
        battle.endBattle();
        _exit();
        return;
      case BattleOutcome.ongoing:
        if (st.mustSwitch) {
          setState(() {
            _forcedSwitch = true;
            _mode = _Mode.chooseSwitch;
          });
        } else {
          setState(() => _mode = _Mode.command);
        }
    }
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/world');
    }
  }

  void _afterAction() => setState(() => _mode = _Mode.message);

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(battleControllerProvider);
    if (st == null) {
      return const Scaffold(body: Center(child: Text('...')));
    }
    final data = ref.watch(gameDataProvider);
    final delay = ref.read(settingsProvider).charDelayMs;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBFE3F0), Color(0xFFE6F0D4)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 戦闘フィールド
                Expanded(
                  child: Stack(
                    children: [
                      // 相手
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _StatusPlate(mon: st.enemyMon, showHpNumbers: false),
                      ),
                      Positioned(
                        top: 30,
                        right: 24,
                        child: MonsterSprite(species: st.enemyMon.species, size: 120, flip: true),
                      ),
                      // 自分
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _StatusPlate(mon: st.playerMon, showHpNumbers: true, showExp: true),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        child: MonsterSprite(species: st.playerMon.species, size: 140),
                      ),
                    ],
                  ),
                ),
                // 下部UI
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: _buildBottom(st, data, delay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(BattleState st, data, int delay) {
    switch (_mode) {
      case _Mode.message:
        return MessageQueueBox(
          messages: st.messages,
          charDelayMs: delay,
          onDone: _onMessagesDone,
        );
      case _Mode.command:
        return _CommandMenu(
          isWild: st.isWild,
          onFight: () => setState(() => _mode = _Mode.chooseMove),
          onItem: () => setState(() => _mode = _Mode.chooseItem),
          onSwitch: () => setState(() {
            _forcedSwitch = false;
            _mode = _Mode.chooseSwitch;
          }),
          onRun: () {
            ref.read(battleControllerProvider.notifier).run();
            _afterAction();
          },
        );
      case _Mode.chooseMove:
        return _MoveMenu(
          mon: st.playerMon,
          data: ref.read(gameDataProvider),
          onBack: () => setState(() => _mode = _Mode.command),
          onSelect: (i) {
            ref.read(battleControllerProvider.notifier).attack(i);
            _afterAction();
          },
        );
      case _Mode.chooseItem:
        return _ItemMenu(
          onBack: () => setState(() => _mode = _Mode.command),
          onUse: (id, isBall) {
            final battle = ref.read(battleControllerProvider.notifier);
            if (isBall) {
              battle.throwBall(id);
            } else {
              battle.useHealItem(id);
            }
            _afterAction();
          },
        );
      case _Mode.chooseSwitch:
        return _SwitchMenu(
          forced: _forcedSwitch,
          activeMon: st.playerMon,
          onBack: _forcedSwitch ? null : () => setState(() => _mode = _Mode.command),
          onSelect: (i) {
            ref.read(battleControllerProvider.notifier).switchTo(i, forced: _forcedSwitch);
            _afterAction();
          },
        );
    }
  }
}

class _StatusPlate extends StatelessWidget {
  final MonsterInstance mon;
  final bool showHpNumbers;
  final bool showExp;
  const _StatusPlate({required this.mon, required this.showHpNumbers, this.showExp = false});

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mon.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Text('Lv.${mon.level}', style: const TextStyle(fontSize: 12)),
              if (mon.status.label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: Colors.deepOrange,
                  child: Text(mon.status.shortLabel,
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          HpBar(ratio: mon.hpRatio, width: 130),
          if (showHpNumbers)
            Text('${mon.currentHp}/${mon.maxHp}', style: const TextStyle(fontSize: 11)),
          if (showExp) ...[
            const SizedBox(height: 2),
            ExpBar(ratio: mon.expRatio, width: 130),
          ],
        ],
      ),
    );
  }
}

class _CommandMenu extends StatelessWidget {
  final bool isWild;
  final VoidCallback onFight;
  final VoidCallback onItem;
  final VoidCallback onSwitch;
  final VoidCallback onRun;
  const _CommandMenu({
    required this.isWild,
    required this.onFight,
    required this.onItem,
    required this.onSwitch,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _cmd('たたかう', Icons.flash_on, const Color(0xFFD94F4F), onFight),
          _cmd('どうぐ', Icons.backpack, const Color(0xFF4CAF6E), onItem),
          _cmd('モンスター', Icons.swap_horiz, const Color(0xFF3E78B2), onSwitch),
          _cmd('にげる', Icons.directions_run, const Color(0xFF7A6FB0), onRun),
        ],
      ),
    );
  }

  Widget _cmd(String label, IconData icon, Color color, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(backgroundColor: color),
    );
  }
}

class _MoveMenu extends StatelessWidget {
  final MonsterInstance mon;
  final dynamic data;
  final VoidCallback onBack;
  final void Function(int) onSelect;
  const _MoveMenu({required this.mon, required this.data, required this.onBack, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < mon.moves.length; i++)
                _moveButton(context, i, data.move(mon.moves[i].moveId) as Move),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text('もどる')),
          ),
        ],
      ),
    );
  }

  Widget _moveButton(BuildContext context, int i, Move move) {
    final learned = mon.moves[i];
    final disabled = learned.currentPp <= 0;
    return InkWell(
      onTap: disabled ? null : () => onSelect(i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(move.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: disabled ? Colors.grey : null,
                )),
            const SizedBox(height: 2),
            Row(
              children: [
                TypeBadge(type: move.type, fontSize: 9),
                const Spacer(),
                Text('PP ${learned.currentPp}/${learned.maxPp}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends ConsumerWidget {
  final VoidCallback onBack;
  final void Function(String id, bool isBall) onUse;
  const _ItemMenu({required this.onBack, required this.onUse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final save = ref.watch(gameControllerProvider)!.save;
    final usable = save.bag.where((b) {
      final def = data.items[b.id];
      return def != null &&
          (def.category == ItemCategory.ball ||
              def.category == ItemCategory.heal ||
              def.category == ItemCategory.statusHeal);
    }).toList();

    return RetroWindow(
      child: SizedBox(
        height: 180,
        child: Column(
          children: [
            Expanded(
              child: usable.isEmpty
                  ? const Center(child: Text('つかえる どうぐが ない'))
                  : ListView.builder(
                      itemCount: usable.length,
                      itemBuilder: (context, i) {
                        final bag = usable[i];
                        final def = data.items[bag.id]!;
                        final isBall = def.category == ItemCategory.ball;
                        return ListTile(
                          dense: true,
                          leading: Icon(isBall ? Icons.catching_pokemon : Icons.medical_services,
                              color: isBall ? Colors.red : Colors.green),
                          title: Text(def.name),
                          trailing: Text('×${bag.count}'),
                          onTap: () => onUse(bag.id, isBall),
                        );
                      },
                    ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text('もどる')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchMenu extends ConsumerWidget {
  final bool forced;
  final MonsterInstance activeMon;
  final VoidCallback? onBack;
  final void Function(int) onSelect;
  const _SwitchMenu({required this.forced, required this.activeMon, required this.onBack, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(gameControllerProvider)!.save.party;
    return RetroWindow(
      child: SizedBox(
        height: 200,
        child: Column(
          children: [
            if (forced)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('つぎの モンスターを えらんでください！', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: party.length,
                itemBuilder: (context, i) {
                  final mon = party[i];
                  final isActive = identical(mon, activeMon);
                  return ListTile(
                    dense: true,
                    leading: MonsterSprite(species: mon.species, size: 36),
                    title: Text('${mon.displayName}  Lv.${mon.level}'),
                    subtitle: HpBar(ratio: mon.hpRatio, width: 100),
                    trailing: Text('${mon.currentHp}/${mon.maxHp}', style: const TextStyle(fontSize: 11)),
                    enabled: !mon.isFainted && !isActive,
                    onTap: (mon.isFainted || isActive) ? null : () => onSelect(i),
                  );
                },
              ),
            ),
            if (onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back), label: const Text('もどる')),
              ),
          ],
        ),
      ),
    );
  }
}
