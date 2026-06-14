/// 技のカテゴリ
enum MoveCategory { physical, special, status }

MoveCategory _categoryFromString(String s) {
  switch (s) {
    case 'physical':
      return MoveCategory.physical;
    case 'special':
      return MoveCategory.special;
    default:
      return MoveCategory.status;
  }
}

/// 技(わざ)の定義。JSON からロードされる不変データ。
class Move {
  final int id;
  final String name;
  final String type;
  final int power;
  final int accuracy;
  final int pp;
  final MoveCategory category;

  /// 付加効果: poison / paralyze / sleep / burn / freeze / heal / none / null
  final String? effect;
  final int effectChance;
  final String description;

  const Move({
    required this.id,
    required this.name,
    required this.type,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.category,
    required this.effect,
    required this.effectChance,
    required this.description,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      power: json['power'] as int,
      accuracy: json['accuracy'] as int,
      pp: json['pp'] as int,
      category: _categoryFromString(json['category'] as String),
      effect: json['effect'] as String?,
      effectChance: (json['effectChance'] ?? 0) as int,
      description: (json['desc'] ?? '') as String,
    );
  }

  bool get isStatusMove => category == MoveCategory.status;
}

/// モンスターが習得した技の現在状態(残りPP)。
class LearnedMove {
  final int moveId;
  int currentPp;
  final int maxPp;

  LearnedMove({
    required this.moveId,
    required this.currentPp,
    required this.maxPp,
  });

  factory LearnedMove.fromMove(Move move) =>
      LearnedMove(moveId: move.id, currentPp: move.pp, maxPp: move.pp);

  Map<String, dynamic> toJson() => {
        'moveId': moveId,
        'currentPp': currentPp,
        'maxPp': maxPp,
      };

  factory LearnedMove.fromJson(Map<String, dynamic> json) => LearnedMove(
        moveId: json['moveId'] as int,
        currentPp: json['currentPp'] as int,
        maxPp: json['maxPp'] as int,
      );
}
