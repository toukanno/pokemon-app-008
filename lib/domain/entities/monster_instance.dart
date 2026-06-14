import '../../core/constants/game_constants.dart';
import 'experience.dart';
import 'monster_species.dart';
import 'move.dart';
import 'status_condition.dart';

/// 所持している個々のモンスター(個体)。セーブ対象。
///
/// [species] はロード時に [bind] でひも付ける(JSONには種族IDのみ保存)。
class MonsterInstance {
  int speciesId;
  String? nickname;
  int level;
  int exp;

  /// 個体値(0..15)。同じ種族でも個体差を出す。
  final int ivHp;
  final int ivAttack;
  final int ivDefense;
  final int ivSpeed;
  final int ivSpecial;

  int currentHp;
  StatusCondition status;
  int sleepTurns;
  List<LearnedMove> moves;

  /// 図鑑/UI用にロード時にひも付けられる種族データ
  MonsterSpecies? _species;

  MonsterInstance({
    required this.speciesId,
    this.nickname,
    required this.level,
    required this.exp,
    required this.ivHp,
    required this.ivAttack,
    required this.ivDefense,
    required this.ivSpeed,
    required this.ivSpecial,
    required this.currentHp,
    this.status = StatusCondition.none,
    this.sleepTurns = 0,
    required this.moves,
  });

  MonsterSpecies get species {
    final s = _species;
    if (s == null) {
      throw StateError('MonsterInstance(speciesId=$speciesId) に species が bind されていません');
    }
    return s;
  }

  void bind(MonsterSpecies species) => _species = species;

  String get displayName => nickname ?? species.name;

  // ---- ステータス計算(シンプルな第1世代風) ----
  int _stat(int base, int iv) =>
      ((2 * base + iv) * level ~/ 100) + 5;

  int get maxHp =>
      ((2 * species.baseStats.hp + ivHp) * level ~/ 100) + level + 10;
  int get attack => _stat(species.baseStats.attack, ivAttack);
  int get defense => _stat(species.baseStats.defense, ivDefense);
  int get speed => _stat(species.baseStats.speed, ivSpeed);
  int get special => _stat(species.baseStats.special, ivSpecial);

  bool get isFainted => currentHp <= 0;

  double get hpRatio => maxHp == 0 ? 0 : (currentHp / maxHp).clamp(0.0, 1.0);

  int get expForNextLevel =>
      Experience.totalForLevel(level + 1, species.growthRate);
  int get expForCurrentLevel =>
      Experience.totalForLevel(level, species.growthRate);

  double get expRatio {
    if (level >= GameConstants.maxLevel) return 1.0;
    final cur = exp - expForCurrentLevel;
    final need = expForNextLevel - expForCurrentLevel;
    if (need <= 0) return 0;
    return (cur / need).clamp(0.0, 1.0);
  }

  /// 進化させる。HPの実数は維持し、最大HPの増加分だけ底上げする。
  void evolveInto(MonsterSpecies next) {
    final oldMax = maxHp;
    speciesId = next.id;
    _species = next;
    final gain = maxHp - oldMax;
    currentHp = (currentHp + (gain > 0 ? gain : 0)).clamp(0, maxHp);
  }

  void healFully() {
    currentHp = maxHp;
    status = StatusCondition.none;
    sleepTurns = 0;
    for (final m in moves) {
      m.currentPp = m.maxPp;
    }
  }

  void healStatusOnly() {
    status = StatusCondition.none;
    sleepTurns = 0;
  }

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'nickname': nickname,
        'level': level,
        'exp': exp,
        'ivHp': ivHp,
        'ivAttack': ivAttack,
        'ivDefense': ivDefense,
        'ivSpeed': ivSpeed,
        'ivSpecial': ivSpecial,
        'currentHp': currentHp,
        'status': status.storageName,
        'sleepTurns': sleepTurns,
        'moves': moves.map((m) => m.toJson()).toList(),
      };

  factory MonsterInstance.fromJson(Map<String, dynamic> json) {
    return MonsterInstance(
      speciesId: json['speciesId'] as int,
      nickname: json['nickname'] as String?,
      level: json['level'] as int,
      exp: json['exp'] as int,
      ivHp: json['ivHp'] as int,
      ivAttack: json['ivAttack'] as int,
      ivDefense: json['ivDefense'] as int,
      ivSpeed: json['ivSpeed'] as int,
      ivSpecial: json['ivSpecial'] as int,
      currentHp: json['currentHp'] as int,
      status: StatusConditionX.fromName(json['status'] as String? ?? 'none'),
      sleepTurns: (json['sleepTurns'] ?? 0) as int,
      moves: (json['moves'] as List)
          .map((e) => LearnedMove.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
