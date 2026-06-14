/// 種族の基礎ステータス
class BaseStats {
  final int hp;
  final int attack;
  final int defense;
  final int speed;
  final int special;

  const BaseStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.special,
  });

  factory BaseStats.fromJson(Map<String, dynamic> json) => BaseStats(
        hp: json['hp'] as int,
        attack: json['attack'] as int,
        defense: json['defense'] as int,
        speed: json['speed'] as int,
        special: json['special'] as int,
      );

  int get total => hp + attack + defense + speed + special;
}

/// レベル習得技
class LearnsetEntry {
  final int level;
  final int moveId;
  const LearnsetEntry({required this.level, required this.moveId});

  factory LearnsetEntry.fromJson(Map<String, dynamic> json) => LearnsetEntry(
        level: json['level'] as int,
        moveId: json['move'] as int,
      );
}

/// モンスターの種族データ(図鑑エントリ)。完全オリジナル。
class MonsterSpecies {
  final int id;
  final String name;
  final String category;
  final List<String> types;
  final BaseStats baseStats;
  final int catchRate;
  final int baseExp;
  final String growthRate;
  final int? evolveTo;
  final int? evolveLevel;
  final List<LearnsetEntry> learnset;
  final String dexEntry;
  final double height;
  final double weight;
  final bool isLegendary;
  final String spriteColor;
  final String spriteColor2;
  final int spriteShape;

  const MonsterSpecies({
    required this.id,
    required this.name,
    required this.category,
    required this.types,
    required this.baseStats,
    required this.catchRate,
    required this.baseExp,
    required this.growthRate,
    required this.evolveTo,
    required this.evolveLevel,
    required this.learnset,
    required this.dexEntry,
    required this.height,
    required this.weight,
    required this.isLegendary,
    required this.spriteColor,
    required this.spriteColor2,
    required this.spriteShape,
  });

  factory MonsterSpecies.fromJson(Map<String, dynamic> json) {
    return MonsterSpecies(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      types: (json['types'] as List).cast<String>(),
      baseStats: BaseStats.fromJson(json['baseStats'] as Map<String, dynamic>),
      catchRate: json['catchRate'] as int,
      baseExp: json['baseExp'] as int,
      growthRate: json['growthRate'] as String,
      evolveTo: json['evolveTo'] as int?,
      evolveLevel: json['evolveLevel'] as int?,
      learnset: (json['learnset'] as List)
          .map((e) => LearnsetEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      dexEntry: json['dexEntry'] as String,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      isLegendary: (json['isLegendary'] ?? false) as bool,
      spriteColor: json['spriteColor'] as String,
      spriteColor2: (json['spriteColor2'] ?? json['spriteColor']) as String,
      spriteShape: (json['spriteShape'] ?? 0) as int,
    );
  }

  bool get canEvolve => evolveTo != null && evolveLevel != null;
}
