import 'dart:math';

import '../entities/game_data.dart';
import '../entities/monster_instance.dart';
import '../entities/move.dart';
import '../entities/status_condition.dart';

/// ダメージ計算の結果
class DamageResult {
  final int damage;
  final double effectiveness;
  final bool critical;
  const DamageResult(this.damage, this.effectiveness, this.critical);
}

/// 捕獲判定の結果
class CaptureResult {
  final bool success;
  final int shakes; // 0..3
  const CaptureResult(this.success, this.shakes);
}

/// バトルの純粋ロジック(状態を持たない計算群)。
class BattleEngine {
  final GameData data;
  final Random _rng;

  BattleEngine(this.data, {Random? rng}) : _rng = rng ?? Random();

  /// 命中判定
  bool checkHit(Move move) {
    if (move.accuracy >= 100) return true;
    return _rng.nextInt(100) < move.accuracy;
  }

  /// ダメージ計算
  DamageResult computeDamage(MonsterInstance attacker, MonsterInstance defender, Move move) {
    if (move.power <= 0) return const DamageResult(0, 1.0, false);

    final isPhysical = move.category == MoveCategory.physical;
    var atkStat = isPhysical ? attacker.attack : attacker.special;
    final defStat = isPhysical ? defender.defense : defender.special;

    // やけどは ぶつりこうげきを はんげん
    if (isPhysical && attacker.status == StatusCondition.burn) {
      atkStat = (atkStat / 2).floor();
    }

    final critical = _rng.nextInt(16) == 0; // 約6%
    final critMul = critical ? 2.0 : 1.0;

    final base = (((2 * attacker.level / 5 + 2) * move.power * atkStat / max(1, defStat)) / 50) + 2;

    // タイプ一致(STAB)
    final stab = attacker.species.types.contains(move.type) ? 1.5 : 1.0;
    // タイプ相性
    final eff = data.typeChart.effectiveness(move.type, defender.species.types);
    // 乱数 0.85..1.00
    final rand = (85 + _rng.nextInt(16)) / 100.0;

    final dmg = (base * stab * eff * critMul * rand).floor();
    return DamageResult(max(1, dmg), eff, critical);
  }

  /// 行動前の状態異常チェック。行動できるなら true。メッセージを out に積む。
  bool canAct(MonsterInstance mon, List<String> out) {
    switch (mon.status) {
      case StatusCondition.sleep:
        if (mon.sleepTurns > 0) {
          mon.sleepTurns--;
          if (mon.sleepTurns <= 0) {
            mon.status = StatusCondition.none;
            out.add('${mon.displayName}は めを さました！');
            return true;
          }
          out.add('${mon.displayName}は ぐうぐう ねむっている。');
          return false;
        }
        mon.status = StatusCondition.none;
        return true;
      case StatusCondition.freeze:
        if (_rng.nextInt(100) < 20) {
          mon.status = StatusCondition.none;
          out.add('${mon.displayName}の こおりが とけた！');
          return true;
        }
        out.add('${mon.displayName}は こおって うごけない！');
        return false;
      case StatusCondition.paralyze:
        if (_rng.nextInt(100) < 25) {
          out.add('${mon.displayName}は からだが しびれて うごけない！');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  /// 技の追加効果(状態異常)を適用する。
  void applyMoveEffect(Move move, MonsterInstance target, List<String> out) {
    final effect = move.effect;
    if (effect == null || effect == 'none' || effect == 'heal') return;
    if (target.status != StatusCondition.none) return; // すでに状態異常
    if (_rng.nextInt(100) >= move.effectChance) return;

    final cond = StatusConditionX.fromName(effect);
    if (cond == StatusCondition.none) return;
    // タイプによる無効化(どくタイプは どくにならない 等)
    if (cond == StatusCondition.poison && target.species.types.contains('どく')) return;
    if (cond == StatusCondition.burn && target.species.types.contains('ほのお')) return;
    if (cond == StatusCondition.freeze && target.species.types.contains('こおり')) return;

    target.status = cond;
    if (cond == StatusCondition.sleep) {
      target.sleepTurns = 1 + _rng.nextInt(3);
    }
    out.add('${target.displayName}は ${cond.label}じょうたいに なった！');
  }

  /// ターン終了時の状態異常ダメージ。
  void endOfTurn(MonsterInstance mon, List<String> out) {
    if (mon.isFainted) return;
    if (mon.status == StatusCondition.poison) {
      final dmg = max(1, (mon.maxHp / 8).floor());
      mon.currentHp = max(0, mon.currentHp - dmg);
      out.add('${mon.displayName}は どくの ダメージを うけた！');
    } else if (mon.status == StatusCondition.burn) {
      final dmg = max(1, (mon.maxHp / 16).floor());
      mon.currentHp = max(0, mon.currentHp - dmg);
      out.add('${mon.displayName}は やけどの ダメージを うけた！');
    }
  }

  /// 行動順を決める。true なら a が先手。
  bool aGoesFirst(MonsterInstance a, MonsterInstance b) {
    var sa = a.speed;
    var sb = b.speed;
    if (a.status == StatusCondition.paralyze) sa = (sa / 2).floor();
    if (b.status == StatusCondition.paralyze) sb = (sb / 2).floor();
    if (sa == sb) return _rng.nextBool();
    return sa > sb;
  }

  /// 相性メッセージ
  String? effectivenessMessage(double eff) {
    if (eff == 0) return 'こうかが ないようだ…';
    if (eff >= 2) return 'こうかは ばつぐんだ！';
    if (eff < 1) return 'こうかは いまひとつの ようだ…';
    return null;
  }

  /// 捕獲判定
  CaptureResult tryCapture(MonsterInstance target, double ballPower) {
    final maxHp = target.maxHp;
    final hp = target.currentHp;
    final catchRate = target.species.catchRate;

    var statusBonus = 1.0;
    if (target.status == StatusCondition.sleep || target.status == StatusCondition.freeze) {
      statusBonus = 2.0;
    } else if (target.status != StatusCondition.none) {
      statusBonus = 1.5;
    }

    final a = ((3 * maxHp - 2 * hp) * catchRate * ballPower * statusBonus) / (3 * maxHp);
    if (a >= 255) return const CaptureResult(true, 3);

    final b = (1048576 / pow(255 / a, 0.25)).floor(); // 0..65535
    var shakes = 0;
    for (var i = 0; i < 3; i++) {
      if (_rng.nextInt(65536) < b) {
        shakes++;
      } else {
        return CaptureResult(false, shakes);
      }
    }
    // 3回ゆれたら捕獲(4回目判定)
    final success = _rng.nextInt(65536) < b;
    return CaptureResult(success, 3);
  }

  /// にげる成否
  bool tryRun(MonsterInstance player, MonsterInstance wild, int attempts) {
    if (player.speed >= wild.speed) return true;
    final odds = ((player.speed * 128 / max(1, wild.speed)).floor() + 30 * attempts) % 256;
    return _rng.nextInt(256) < odds;
  }
}
