/// ゲーム全体で使う定数。
class GameConstants {
  GameConstants._();

  static const String appTitle = 'モンスターズ・エレメンタ';
  static const String regionName = 'エレメンシア地方';

  /// セーブ関連
  static const String hiveBoxName = 'elementa_save_box';
  static const String saveKey = 'main_save';
  static const String settingsKey = 'settings';

  /// パーティ・ボックス
  static const int maxPartySize = 6;
  static const int boxCapacity = 120;

  /// バトル
  static const int maxMoves = 4;
  static const int maxLevel = 100;

  /// 草むらエンカウント率(歩数ごと)
  static const double encounterRate = 0.12;

  /// マップ描画
  static const double tileSize = 40.0;

  /// 所持金の初期値
  static const int startingMoney = 1500;
}

/// アイテムID(オリジナル)
class ItemIds {
  ItemIds._();
  static const String monsterBall = 'ball_normal';
  static const String superBall = 'ball_super';
  static const String hyperBall = 'ball_hyper';
  static const String potion = 'potion';
  static const String superPotion = 'super_potion';
  static const String hyperPotion = 'hyper_potion';
  static const String antidote = 'antidote';
  static const String awakening = 'awakening';
  static const String paralyzeHeal = 'paralyze_heal';
  static const String fullHeal = 'full_heal';
  static const String revive = 'revive';
}
