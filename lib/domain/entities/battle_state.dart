import 'monster_instance.dart';

enum BattleOutcome { ongoing, won, lost, caught, fled }

/// バトルの状態。BattleController が更新する。
class BattleState {
  final MonsterInstance playerMon;
  final MonsterInstance enemyMon;
  final bool isWild;

  /// 直近のアクションで表示するメッセージ列
  final List<String> messages;
  final BattleOutcome outcome;

  /// プレイヤーのモンスターがひんしで交代が必要
  final bool mustSwitch;

  /// 行動解決中(入力ロック)
  final bool busy;

  /// 勝利/捕獲時の報酬情報
  final int gainedExp;
  final List<String> rewardNotes;

  /// 捕獲したモンスター(あれば)
  final MonsterInstance? caughtMonster;

  /// 通知用リビジョン
  final int rev;

  const BattleState({
    required this.playerMon,
    required this.enemyMon,
    required this.isWild,
    required this.messages,
    required this.outcome,
    required this.mustSwitch,
    required this.busy,
    required this.gainedExp,
    required this.rewardNotes,
    required this.caughtMonster,
    required this.rev,
  });

  BattleState copyWith({
    MonsterInstance? playerMon,
    MonsterInstance? enemyMon,
    List<String>? messages,
    BattleOutcome? outcome,
    bool? mustSwitch,
    bool? busy,
    int? gainedExp,
    List<String>? rewardNotes,
    MonsterInstance? caughtMonster,
  }) {
    return BattleState(
      playerMon: playerMon ?? this.playerMon,
      enemyMon: enemyMon ?? this.enemyMon,
      isWild: isWild,
      messages: messages ?? this.messages,
      outcome: outcome ?? this.outcome,
      mustSwitch: mustSwitch ?? this.mustSwitch,
      busy: busy ?? this.busy,
      gainedExp: gainedExp ?? this.gainedExp,
      rewardNotes: rewardNotes ?? this.rewardNotes,
      caughtMonster: caughtMonster ?? this.caughtMonster,
      rev: rev + 1,
    );
  }

  bool get isOver => outcome != BattleOutcome.ongoing;
}
