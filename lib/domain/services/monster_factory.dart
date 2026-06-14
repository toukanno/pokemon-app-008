import 'dart:math';

import '../entities/experience.dart';
import '../entities/game_data.dart';
import '../entities/monster_instance.dart';
import '../entities/monster_species.dart';
import '../entities/move.dart';

/// 種族データから個体([MonsterInstance])を生成するファクトリ。
class MonsterFactory {
  final GameData data;
  final Random _rng;

  MonsterFactory(this.data, {Random? rng}) : _rng = rng ?? Random();

  /// 指定レベルの新しい個体を生成する。
  MonsterInstance create(int speciesId, int level, {bool shiny = false}) {
    final species = data.species(speciesId);
    final exp = Experience.totalForLevel(level, species.growthRate);
    final moves = _movesForLevel(species, level);

    final instance = MonsterInstance(
      speciesId: speciesId,
      level: level,
      exp: exp,
      ivHp: _rng.nextInt(16),
      ivAttack: _rng.nextInt(16),
      ivDefense: _rng.nextInt(16),
      ivSpeed: _rng.nextInt(16),
      ivSpecial: _rng.nextInt(16),
      currentHp: 1,
      moves: moves,
    );
    instance.bind(species);
    instance.currentHp = instance.maxHp;
    return instance;
  }

  /// レベルに応じた習得技(最新の最大4つ)。
  List<LearnedMove> _movesForLevel(MonsterSpecies species, int level) {
    final learnable = species.learnset
        .where((e) => e.level <= level)
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    final ids = <int>[];
    for (final e in learnable) {
      if (!ids.contains(e.moveId)) ids.add(e.moveId);
    }
    // 最新の4つを残す
    final recent = ids.length > 4 ? ids.sublist(ids.length - 4) : ids;
    if (recent.isEmpty && species.learnset.isNotEmpty) {
      recent.add(species.learnset.first.moveId);
    }
    return recent.map((id) => LearnedMove.fromMove(data.move(id))).toList();
  }

  /// 既存個体を種族データにひも付け直す(ロード時)。
  void rebind(MonsterInstance instance) {
    instance.bind(data.species(instance.speciesId));
  }
}
