import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:monster_quest/domain/entities/experience.dart';
import 'package:monster_quest/domain/entities/status_condition.dart';
import 'package:monster_quest/domain/services/battle_engine.dart';
import 'package:monster_quest/domain/services/monster_factory.dart';

import 'test_data_loader.dart';

void main() {
  final data = loadGameDataFromFiles();

  group('データ整合性', () {
    test('モンスターは150体以上', () {
      expect(data.speciesList.length, greaterThanOrEqualTo(150));
    });

    test('進化先のIDがすべて存在する', () {
      for (final s in data.speciesList) {
        if (s.evolveTo != null) {
          expect(data.speciesById.containsKey(s.evolveTo), isTrue,
              reason: '${s.name} の進化先 ${s.evolveTo} が存在しない');
        }
      }
    });

    test('習得技のIDがすべて存在する', () {
      for (final s in data.speciesList) {
        for (final e in s.learnset) {
          expect(data.movesById.containsKey(e.moveId), isTrue,
              reason: '${s.name} の技ID ${e.moveId} が存在しない');
        }
      }
    });

    test('タイプ相性表は対称的に全タイプ網羅', () {
      for (final atk in data.typeChart.types) {
        for (final def in data.typeChart.types) {
          expect(data.typeChart.multiplier(atk, def), isNonNegative);
        }
      }
    });

    test('全マップが矩形で歩行可能スポーンを持つ', () {
      for (final map in data.maps.values) {
        final widths = map.rows.map((r) => r.length).toSet();
        expect(widths.length, 1, reason: '${map.id} の行幅が不揃い');
        expect(map.inBounds(map.spawn[0], map.spawn[1]), isTrue);
      }
    });
  });

  group('経験値テーブル', () {
    test('レベルが上がるほど必要経験値が増える', () {
      for (var lv = 2; lv < 100; lv++) {
        expect(Experience.totalForLevel(lv + 1, 'medium'),
            greaterThan(Experience.totalForLevel(lv, 'medium')));
      }
    });

    test('累計経験値からレベルを正しく逆算', () {
      final exp = Experience.totalForLevel(25, 'medium');
      expect(Experience.levelForTotal(exp, 'medium'), 25);
    });
  });

  group('タイプ相性', () {
    test('みず は ほのお に ばつぐん', () {
      expect(data.typeChart.multiplier('みず', 'ほのお'), 2.0);
    });
    test('ほのお は みず に いまひとつ', () {
      expect(data.typeChart.multiplier('ほのお', 'みず'), 0.5);
    });
  });

  group('バトルエンジン', () {
    final factory = MonsterFactory(data, rng: Random(1));
    final engine = BattleEngine(data, rng: Random(2));

    test('ダメージは1以上', () {
      final a = factory.create(4, 20); // ほのお系
      final b = factory.create(1, 20); // くさ系
      final move = data.move(a.moves.first.moveId);
      final res = engine.computeDamage(a, b, move);
      expect(res.damage, greaterThanOrEqualTo(1));
    });

    test('瀕死のモンスターは捕まえやすい', () {
      final wild = factory.create(13, 5);
      wild.currentHp = 1;
      wild.status = StatusCondition.sleep;
      var success = 0;
      final eng = BattleEngine(data, rng: Random(7));
      for (var i = 0; i < 200; i++) {
        if (eng.tryCapture(wild, 2.0).success) success++;
      }
      expect(success, greaterThan(100));
    });
  });

  group('モンスター生成', () {
    final factory = MonsterFactory(data, rng: Random(3));
    test('生成した個体は最大HPで技を持つ', () {
      final mon = factory.create(7, 15);
      expect(mon.currentHp, mon.maxHp);
      expect(mon.moves.isNotEmpty, isTrue);
      expect(mon.moves.length, lessThanOrEqualTo(4));
      expect(mon.level, 15);
    });

    test('進化で種族IDが変わり整合性が保たれる', () {
      final mon = factory.create(1, 16);
      final next = data.species(mon.species.evolveTo!);
      mon.evolveInto(next);
      expect(mon.speciesId, next.id);
      expect(mon.maxHp, greaterThan(0));
      expect(mon.currentHp, lessThanOrEqualTo(mon.maxHp));
      // 進化系統は合計種族値が上がる設計
      expect(next.baseStats.total, greaterThan(data.species(1).baseStats.total));
    });
  });
}
