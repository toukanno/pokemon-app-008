import '../../core/constants/game_constants.dart';

/// 経験値テーブル。成長タイプごとに必要経験値を算出する。
class Experience {
  Experience._();

  /// 指定レベルに到達するのに必要な累計経験値。
  static int totalForLevel(int level, String growthRate) {
    if (level <= 1) return 0;
    final n = level;
    switch (growthRate) {
      case 'fast':
        return (4 * n * n * n) ~/ 5;
      case 'slow':
        return (5 * n * n * n) ~/ 4;
      case 'medium':
      default:
        return n * n * n;
    }
  }

  /// 現在の累計経験値からレベルを逆算。
  static int levelForTotal(int totalExp, String growthRate) {
    var level = 1;
    while (level < GameConstants.maxLevel &&
        totalForLevel(level + 1, growthRate) <= totalExp) {
      level++;
    }
    return level;
  }

  /// 撃破時に得られる経験値。
  static int gainFromDefeat(int baseExp, int defeatedLevel) {
    return ((baseExp * defeatedLevel) / 7).floor() + 1;
  }
}
