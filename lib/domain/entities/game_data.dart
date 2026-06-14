import 'monster_species.dart';
import 'move.dart';
import 'type_chart.dart';
import 'game_map.dart';
import 'item.dart';

/// 静的なゲームデータ(JSONからロード)をまとめて保持するコンテナ。
class GameData {
  final Map<int, MonsterSpecies> speciesById;
  final List<MonsterSpecies> speciesList;
  final Map<int, Move> movesById;
  final TypeChart typeChart;
  final Map<String, GameMap> maps;
  final String startMapId;
  final Map<String, ItemDef> items;

  const GameData({
    required this.speciesById,
    required this.speciesList,
    required this.movesById,
    required this.typeChart,
    required this.maps,
    required this.startMapId,
    required this.items,
  });

  MonsterSpecies species(int id) {
    final s = speciesById[id];
    if (s == null) throw StateError('未知の種族ID: $id');
    return s;
  }

  Move move(int id) {
    final m = movesById[id];
    if (m == null) throw StateError('未知の技ID: $id');
    return m;
  }

  GameMap map(String id) {
    final m = maps[id];
    if (m == null) throw StateError('未知のマップID: $id');
    return m;
  }

  int get totalSpecies => speciesList.length;
}
