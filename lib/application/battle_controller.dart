import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../domain/entities/battle_state.dart';
import '../domain/entities/experience.dart';
import '../domain/entities/game_data.dart';
import '../domain/entities/monster_instance.dart';
import '../domain/entities/move.dart';
import '../domain/services/battle_engine.dart';
import 'game_controller.dart';
import 'providers.dart';

/// バトルの進行を司るコントローラ。1アクションを同期的に解決し、
/// 表示メッセージ列とともに [BattleState] を更新する。
class BattleController extends StateNotifier<BattleState?> {
  final Ref _ref;
  final Random _rng = Random();

  BattleController(this._ref) : super(null);

  GameData get _data => _ref.read(gameDataProvider);
  BattleEngine get _engine => _ref.read(battleEngineProvider);
  GameController get _game => _ref.read(gameControllerProvider.notifier);

  int _runAttempts = 0;

  // ------------------------------------------------------------------ 開始
  void startWild(MonsterInstance playerMon, MonsterInstance enemyMon) {
    _runAttempts = 0;
    state = BattleState(
      playerMon: playerMon,
      enemyMon: enemyMon,
      isWild: true,
      messages: ['やせいの ${enemyMon.displayName}が とびだしてきた！'],
      outcome: BattleOutcome.ongoing,
      mustSwitch: false,
      busy: false,
      gainedExp: 0,
      rewardNotes: const [],
      caughtMonster: null,
      rev: 0,
    );
  }

  void clear() => state = null;

  // ------------------------------------------------------------------ こうげき
  void attack(int moveIndex) {
    final st = state;
    if (st == null || st.isOver || st.mustSwitch) return;
    final pm = st.playerMon;
    final em = st.enemyMon;
    if (moveIndex < 0 || moveIndex >= pm.moves.length) return;
    final learned = pm.moves[moveIndex];
    if (learned.currentPp <= 0) {
      _push(['その わざの のこりが ない！']);
      return;
    }
    learned.currentPp--;

    final messages = <String>[];
    final playerMove = _data.move(learned.moveId);
    final enemyLearned = _pickEnemyMove(em);
    final enemyMove = enemyLearned == null ? null : _data.move(enemyLearned.moveId);

    final playerFirst = _engine.aGoesFirst(pm, em);
    if (playerFirst) {
      _executeMove(pm, em, playerMove, messages);
      if (!em.isFainted && !pm.isFainted && enemyMove != null) {
        _executeMove(em, pm, enemyMove, messages);
      }
    } else {
      if (enemyMove != null) _executeMove(em, pm, enemyMove, messages);
      if (!pm.isFainted && !em.isFainted) {
        _executeMove(pm, em, playerMove, messages);
      }
    }

    _endOfTurn(messages, pm, em);
    _commitTurn(messages, pm, em);
  }

  // ------------------------------------------------------------------ どうぐ(ボール)
  void throwBall(String itemId) {
    final st = state;
    if (st == null || st.isOver || st.mustSwitch || st.busy) return;
    if (!st.isWild) {
      _push(['トレーナーの モンスターには つかえない！']);
      return;
    }
    final em = st.enemyMon;
    final pm = st.playerMon;
    final def = _data.items[itemId];
    if (def == null || _game.itemCount(itemId) <= 0) return;
    _game.removeItem(itemId, 1);

    final messages = <String>['${_game.save!.playerName}は ${def.name}を なげた！'];
    final result = _engine.tryCapture(em, def.power);
    for (var i = 0; i < result.shakes; i++) {
      messages.add('…カクッ');
    }
    if (result.success) {
      messages.add('やった！ ${em.displayName}を つかまえた！');
      _game.addMonster(em);
      messages.add('${em.displayName}を なかまに した！');
      state = st.copyWith(
        messages: messages,
        outcome: BattleOutcome.caught,
        caughtMonster: em,
        busy: false,
      );
      return;
    }

    messages.add(_breakMessage(result.shakes, em.displayName));
    // 失敗 → 相手の こうげき
    final enemyLearned = _pickEnemyMove(em);
    if (enemyLearned != null && !pm.isFainted) {
      _executeMove(em, pm, _data.move(enemyLearned.moveId), messages);
    }
    _endOfTurn(messages, pm, em);
    _finishNonAttack(messages, pm);
  }

  // ------------------------------------------------------------------ どうぐ(かいふく)
  void useHealItem(String itemId) {
    final st = state;
    if (st == null || st.isOver || st.mustSwitch || st.busy) return;
    final pm = st.playerMon;
    final msg = _game.applyItem(itemId, pm);
    if (msg == null) {
      _push(['いま つかっても こうかが なさそうだ。']);
      return;
    }
    final messages = <String>[msg];
    // 相手の こうげき(1ターン消費)
    final enemyLearned = _pickEnemyMove(st.enemyMon);
    if (enemyLearned != null && !pm.isFainted) {
      _executeMove(st.enemyMon, pm, _data.move(enemyLearned.moveId), messages);
    }
    _endOfTurn(messages, pm, st.enemyMon);
    _finishNonAttack(messages, pm);
  }

  // ------------------------------------------------------------------ こうたい
  void switchTo(int partyIndex, {bool forced = false}) {
    final st = state;
    if (st == null || st.isOver) return;
    final party = _game.save!.party;
    if (partyIndex < 0 || partyIndex >= party.length) return;
    final target = party[partyIndex];
    if (target.isFainted) return;
    if (identical(target, st.playerMon) && !forced) return;

    final messages = <String>['ゆけっ！ ${target.displayName}！'];
    if (forced) {
      state = st.copyWith(
        playerMon: target,
        messages: messages,
        mustSwitch: false,
        outcome: BattleOutcome.ongoing,
        busy: false,
      );
      return;
    }
    // 通常こうたい → 相手の こうげき
    state = st.copyWith(playerMon: target, messages: messages);
    final enemyLearned = _pickEnemyMove(st.enemyMon);
    if (enemyLearned != null && !target.isFainted) {
      _executeMove(st.enemyMon, target, _data.move(enemyLearned.moveId), messages);
    }
    _endOfTurn(messages, target, st.enemyMon);
    _finishNonAttack(messages, target);
  }

  // ------------------------------------------------------------------ にげる
  void run() {
    final st = state;
    if (st == null || st.isOver || st.mustSwitch || st.busy) return;
    if (!st.isWild) {
      _push(['しょうぶから にげられない！']);
      return;
    }
    _runAttempts++;
    final pm = st.playerMon;
    final em = st.enemyMon;
    if (_engine.tryRun(pm, em, _runAttempts)) {
      state = st.copyWith(
        messages: ['うまく にげきれた！'],
        outcome: BattleOutcome.fled,
        busy: false,
      );
      return;
    }
    final messages = <String>['しかし まわりこまれてしまった！'];
    final enemyLearned = _pickEnemyMove(em);
    if (enemyLearned != null && !pm.isFainted) {
      _executeMove(em, pm, _data.move(enemyLearned.moveId), messages);
    }
    _endOfTurn(messages, pm, em);
    _finishNonAttack(messages, pm);
  }

  // ================================================================== 内部
  void _push(List<String> messages) {
    final st = state;
    if (st == null) return;
    state = st.copyWith(messages: messages);
  }

  LearnedMove? _pickEnemyMove(MonsterInstance enemy) {
    if (enemy.moves.isEmpty) return null;
    final usable = enemy.moves.where((m) => m.currentPp > 0).toList();
    final pool = usable.isNotEmpty ? usable : enemy.moves;
    final chosen = pool[_rng.nextInt(pool.length)];
    if (chosen.currentPp > 0) chosen.currentPp--;
    return chosen;
  }

  void _executeMove(MonsterInstance attacker, MonsterInstance defender, Move move, List<String> messages) {
    if (!_engine.canAct(attacker, messages)) return;
    messages.add('${attacker.displayName}の ${move.name}！');

    if (move.effect == 'heal') {
      attacker.currentHp = attacker.maxHp;
      attacker.healStatusOnly();
      messages.add('${attacker.displayName}は ねむって たいりょくを かいふくした！');
      return;
    }

    if (move.isStatusMove) {
      if (!_engine.checkHit(move)) {
        messages.add('しかし うまく きまらなかった！');
        return;
      }
      _engine.applyMoveEffect(move, defender, messages);
      return;
    }

    // ダメージ技
    if (!_engine.checkHit(move)) {
      messages.add('${attacker.displayName}の こうげきは はずれた！');
      return;
    }
    final res = _engine.computeDamage(attacker, defender, move);
    defender.currentHp = (defender.currentHp - res.damage).clamp(0, defender.maxHp);
    if (res.critical) messages.add('きゅうしょに あたった！');
    final effMsg = _engine.effectivenessMessage(res.effectiveness);
    if (effMsg != null) messages.add(effMsg);
    if (defender.isFainted) {
      messages.add('${defender.displayName}は たおれた！');
    } else {
      _engine.applyMoveEffect(move, defender, messages);
    }
  }

  void _endOfTurn(List<String> messages, MonsterInstance pm, MonsterInstance em) {
    if (!em.isFainted && !pm.isFainted) {
      _engine.endOfTurn(pm, messages);
      _engine.endOfTurn(em, messages);
    }
  }

  /// こうげきターンの結末を確定する(勝敗・交代要求)。
  void _commitTurn(List<String> messages, MonsterInstance pm, MonsterInstance em) {
    final st = state!;
    if (em.isFainted) {
      _handleWin(messages, pm, em);
      state = st.copyWith(messages: messages, outcome: BattleOutcome.won, busy: false);
      return;
    }
    _finishNonAttack(messages, pm);
  }

  /// プレイヤー側の気絶のみを判定して状態を確定する。
  void _finishNonAttack(List<String> messages, MonsterInstance pm) {
    final st = state!;
    if (pm.isFainted) {
      if (_game.hasAbleMonster) {
        state = st.copyWith(messages: messages, mustSwitch: true, busy: false);
      } else {
        messages.add('${_game.save!.playerName}は めの まえが まっくらに なった！');
        state = st.copyWith(messages: messages, outcome: BattleOutcome.lost, busy: false);
      }
      return;
    }
    state = st.copyWith(messages: messages, busy: false);
  }

  void _handleWin(List<String> messages, MonsterInstance pm, MonsterInstance em) {
    final exp = Experience.gainFromDefeat(em.species.baseExp, em.level);
    final money = em.level * 5;
    _game.gainMoney(money);
    pm.exp += exp;
    messages.add('やせいの ${em.displayName}を たおした！');
    messages.add('${pm.displayName}は $exp けいけんちを かくとく！');

    while (pm.level < GameConstants.maxLevel &&
        pm.exp >= Experience.totalForLevel(pm.level + 1, pm.species.growthRate)) {
      final oldMax = pm.maxHp;
      pm.level++;
      pm.currentHp += (pm.maxHp - oldMax);
      messages.add('${pm.displayName}は レベル${pm.level}に あがった！');
      for (final entry in pm.species.learnset.where((e) => e.level == pm.level)) {
        _learnMove(pm, entry.moveId, messages);
      }
      if (pm.species.canEvolve && pm.level >= pm.species.evolveLevel!) {
        final next = _data.species(pm.species.evolveTo!);
        final oldName = pm.displayName;
        messages.add('おや…？ $oldName の ようすが…！');
        pm.evolveInto(next);
        _game.markCaught(next.id);
        messages.add('$oldName は ${next.name}に しんかした！');
      }
    }
  }

  void _learnMove(MonsterInstance pm, int moveId, List<String> messages) {
    if (pm.moves.any((m) => m.moveId == moveId)) return;
    final move = _data.move(moveId);
    if (pm.moves.length < GameConstants.maxMoves) {
      pm.moves.add(LearnedMove.fromMove(move));
      messages.add('${pm.displayName}は あたらしく ${move.name}を おぼえた！');
    } else {
      // 最も古い技と入れ替え
      pm.moves.removeAt(0);
      pm.moves.add(LearnedMove.fromMove(move));
      messages.add('${pm.displayName}は ${move.name}を おぼえた！');
    }
  }

  String _breakMessage(int shakes, String name) {
    switch (shakes) {
      case 0:
        return 'おっと！ ボールに はいらなかった！';
      case 1:
        return 'あっ！ もう ちょっと だったのに！';
      case 2:
        return 'おしい！ あと いっぽ だった！';
      default:
        return '$nameは ボールから でてきてしまった！';
    }
  }

  /// バトル終了後の後始末(状態の初期化)。アイテム/お金は既に反映済み。
  void endBattle() {
    _game.autosave();
    state = null;
  }
}
