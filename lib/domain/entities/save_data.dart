import 'direction.dart';
import 'item.dart';
import 'monster_instance.dart';

/// セーブデータ本体。Hive には本オブジェクトの JSON 文字列を保存する。
class SaveData {
  static const int currentVersion = 1;

  int version;
  String playerName;
  String mapId;
  int playerX;
  int playerY;
  Direction facing;
  int money;

  List<MonsterInstance> party;
  List<MonsterInstance> box;
  List<BagItem> bag;

  /// 図鑑: みつけた / つかまえた
  Set<int> seen;
  Set<int> caught;

  /// たびに でかけたことの ある マップ
  Set<String> visitedMaps;

  int playTimeSeconds;
  DateTime savedAt;

  SaveData({
    this.version = currentVersion,
    required this.playerName,
    required this.mapId,
    required this.playerX,
    required this.playerY,
    this.facing = Direction.down,
    required this.money,
    required this.party,
    required this.box,
    required this.bag,
    required this.seen,
    required this.caught,
    required this.visitedMaps,
    this.playTimeSeconds = 0,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'playerName': playerName,
        'mapId': mapId,
        'playerX': playerX,
        'playerY': playerY,
        'facing': facing.storageName,
        'money': money,
        'party': party.map((m) => m.toJson()).toList(),
        'box': box.map((m) => m.toJson()).toList(),
        'bag': bag.map((b) => b.toJson()).toList(),
        'seen': seen.toList(),
        'caught': caught.toList(),
        'visitedMaps': visitedMaps.toList(),
        'playTimeSeconds': playTimeSeconds,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      version: (json['version'] ?? 1) as int,
      playerName: json['playerName'] as String,
      mapId: json['mapId'] as String,
      playerX: json['playerX'] as int,
      playerY: json['playerY'] as int,
      facing: DirectionX.fromName(json['facing'] as String?),
      money: json['money'] as int,
      party: (json['party'] as List)
          .map((e) => MonsterInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      box: (json['box'] as List)
          .map((e) => MonsterInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      bag: (json['bag'] as List)
          .map((e) => BagItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      seen: (json['seen'] as List).cast<int>().toSet(),
      caught: (json['caught'] as List).cast<int>().toSet(),
      visitedMaps: (json['visitedMaps'] as List).cast<String>().toSet(),
      playTimeSeconds: (json['playTimeSeconds'] ?? 0) as int,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
