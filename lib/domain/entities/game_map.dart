/// マップ上のワープ
class Warp {
  final int x;
  final int y;
  final String to;
  final int tx;
  final int ty;
  const Warp({required this.x, required this.y, required this.to, required this.tx, required this.ty});

  factory Warp.fromJson(Map<String, dynamic> json) => Warp(
        x: json['x'] as int,
        y: json['y'] as int,
        to: json['to'] as String,
        tx: json['tx'] as int,
        ty: json['ty'] as int,
      );
}

/// マップ端のワープ(その辺に到達するとワープ)
class EdgeWarp {
  final String edge; // left/right/top/bottom
  final String to;
  final int tx;
  final int ty;
  const EdgeWarp({required this.edge, required this.to, required this.tx, required this.ty});

  factory EdgeWarp.fromJson(Map<String, dynamic> json) => EdgeWarp(
        edge: json['edge'] as String,
        to: json['to'] as String,
        tx: json['tx'] as int,
        ty: json['ty'] as int,
      );
}

/// NPC
class Npc {
  final int x;
  final int y;
  final String name;
  final int sprite;
  final List<String> lines;
  const Npc({required this.x, required this.y, required this.name, required this.sprite, required this.lines});

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        x: json['x'] as int,
        y: json['y'] as int,
        name: json['name'] as String,
        sprite: (json['sprite'] ?? 0) as int,
        lines: (json['lines'] as List).cast<String>(),
      );
}

/// かんばん
class Sign {
  final int x;
  final int y;
  final String text;
  const Sign({required this.x, required this.y, required this.text});

  factory Sign.fromJson(Map<String, dynamic> json) => Sign(
        x: json['x'] as int,
        y: json['y'] as int,
        text: json['text'] as String,
      );
}

/// エンカウント表エントリ
class EncounterEntry {
  final int species;
  final int min;
  final int max;
  final int weight;
  const EncounterEntry({required this.species, required this.min, required this.max, required this.weight});

  factory EncounterEntry.fromJson(Map<String, dynamic> json) => EncounterEntry(
        species: json['species'] as int,
        min: json['min'] as int,
        max: json['max'] as int,
        weight: json['weight'] as int,
      );
}

/// タイルマップ
class GameMap {
  final String id;
  final String name;
  final String kind; // town/route/cave
  final List<String> rows;
  final List<int> spawn;
  final List<Warp> warps;
  final List<EdgeWarp> edgeWarps;
  final List<Npc> npcs;
  final List<Sign> signs;
  final List<EncounterEntry> encounters;
  final List<List<int>> healTiles;
  final List<List<int>> shopTiles;

  const GameMap({
    required this.id,
    required this.name,
    required this.kind,
    required this.rows,
    required this.spawn,
    required this.warps,
    required this.edgeWarps,
    required this.npcs,
    required this.signs,
    required this.encounters,
    required this.healTiles,
    required this.shopTiles,
  });

  int get width => rows.isEmpty ? 0 : rows.first.length;
  int get height => rows.length;

  String tileAt(int x, int y) {
    if (y < 0 || y >= height || x < 0 || x >= width) return 'T';
    return rows[y][x];
  }

  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  /// 進入可能か(壁/木/水/岩/建物/さくは不可)
  bool isWalkable(int x, int y) {
    if (!inBounds(x, y)) return false;
    const blocked = {'T', 'B', 'W', 'R', 'F'};
    return !blocked.contains(tileAt(x, y));
  }

  bool isEncounterTile(int x, int y) => tileAt(x, y) == '~';

  Npc? npcAt(int x, int y) {
    for (final n in npcs) {
      if (n.x == x && n.y == y) return n;
    }
    return null;
  }

  Sign? signAt(int x, int y) {
    for (final s in signs) {
      if (s.x == x && s.y == y) return s;
    }
    return null;
  }

  bool isHealTile(int x, int y) => healTiles.any((t) => t[0] == x && t[1] == y);
  bool isShopTile(int x, int y) => shopTiles.any((t) => t[0] == x && t[1] == y);

  factory GameMap.fromJson(Map<String, dynamic> json) {
    List<List<int>> tiles(String key) => ((json[key] ?? []) as List)
        .map((e) => (e as List).cast<int>())
        .toList();
    return GameMap(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      rows: (json['rows'] as List).cast<String>(),
      spawn: (json['spawn'] as List).cast<int>(),
      warps: (json['warps'] as List).map((e) => Warp.fromJson(e as Map<String, dynamic>)).toList(),
      edgeWarps: (json['edgeWarps'] as List).map((e) => EdgeWarp.fromJson(e as Map<String, dynamic>)).toList(),
      npcs: (json['npcs'] as List).map((e) => Npc.fromJson(e as Map<String, dynamic>)).toList(),
      signs: (json['signs'] as List).map((e) => Sign.fromJson(e as Map<String, dynamic>)).toList(),
      encounters: (json['encounters'] as List).map((e) => EncounterEntry.fromJson(e as Map<String, dynamic>)).toList(),
      healTiles: tiles('healTiles'),
      shopTiles: tiles('shopTiles'),
    );
  }
}
