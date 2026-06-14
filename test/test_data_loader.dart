import 'dart:convert';
import 'dart:io';

import 'package:monster_quest/data/datasources/item_catalog.dart';
import 'package:monster_quest/domain/entities/game_data.dart';
import 'package:monster_quest/domain/entities/game_map.dart';
import 'package:monster_quest/domain/entities/monster_species.dart';
import 'package:monster_quest/domain/entities/move.dart';
import 'package:monster_quest/domain/entities/type_chart.dart';

/// テスト用に assets/data の JSON を直接ファイルから読み込んで [GameData] を構築する。
/// (rootBundle を使わないので flutter test の VM 上で動作する)
GameData loadGameDataFromFiles() {
  Map<String, dynamic> readMap(String name) =>
      jsonDecode(File('assets/data/$name').readAsStringSync()) as Map<String, dynamic>;
  List<dynamic> readList(String name) =>
      jsonDecode(File('assets/data/$name').readAsStringSync()) as List;

  final speciesList = readList('monsters.json')
      .map((e) => MonsterSpecies.fromJson(e as Map<String, dynamic>))
      .toList();
  final speciesById = {for (final s in speciesList) s.id: s};

  final movesById = <int, Move>{};
  for (final m in readList('moves.json')) {
    final move = Move.fromJson(m as Map<String, dynamic>);
    movesById[move.id] = move;
  }

  final typeChart = TypeChart.fromJson(readMap('types.json'));

  final world = readMap('world.json');
  final maps = <String, GameMap>{};
  (world['maps'] as Map<String, dynamic>).forEach((id, value) {
    maps[id] = GameMap.fromJson(value as Map<String, dynamic>);
  });

  return GameData(
    speciesById: speciesById,
    speciesList: speciesList,
    movesById: movesById,
    typeChart: typeChart,
    maps: maps,
    startMapId: world['startMap'] as String,
    items: ItemCatalog.build(),
  );
}
