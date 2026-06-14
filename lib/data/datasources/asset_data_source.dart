import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/game_data.dart';
import '../../domain/entities/game_map.dart';
import '../../domain/entities/monster_species.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/type_chart.dart';
import 'item_catalog.dart';

/// assets/data 配下の JSON を読み込み、[GameData] を構築する。
class AssetDataSource {
  Future<GameData> load() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/data/monsters.json'),
      rootBundle.loadString('assets/data/moves.json'),
      rootBundle.loadString('assets/data/types.json'),
      rootBundle.loadString('assets/data/world.json'),
    ]);

    final monstersRaw = jsonDecode(results[0]) as List;
    final movesRaw = jsonDecode(results[1]) as List;
    final typesRaw = jsonDecode(results[2]) as Map<String, dynamic>;
    final worldRaw = jsonDecode(results[3]) as Map<String, dynamic>;

    final speciesList = monstersRaw
        .map((e) => MonsterSpecies.fromJson(e as Map<String, dynamic>))
        .toList();
    final speciesById = {for (final s in speciesList) s.id: s};

    final movesById = <int, Move>{};
    for (final m in movesRaw) {
      final move = Move.fromJson(m as Map<String, dynamic>);
      movesById[move.id] = move;
    }

    final typeChart = TypeChart.fromJson(typesRaw);

    final maps = <String, GameMap>{};
    final mapsRaw = worldRaw['maps'] as Map<String, dynamic>;
    mapsRaw.forEach((id, value) {
      maps[id] = GameMap.fromJson(value as Map<String, dynamic>);
    });

    return GameData(
      speciesById: speciesById,
      speciesList: speciesList,
      movesById: movesById,
      typeChart: typeChart,
      maps: maps,
      startMapId: worldRaw['startMap'] as String,
      items: ItemCatalog.build(),
    );
  }
}
