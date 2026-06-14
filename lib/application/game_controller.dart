import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../domain/entities/direction.dart';
import '../domain/entities/game_data.dart';
import '../domain/entities/game_map.dart';
import '../domain/entities/item.dart';
import '../domain/entities/monster_instance.dart';
import '../domain/entities/save_data.dart';
import '../domain/entities/status_condition.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/services/monster_factory.dart';
import 'providers.dart';

/// 移動の結果
enum MoveResult { blocked, moved, encounter, heal, shop }

/// マップ上でのインタラクション種別
enum InteractionType { none, talk, sign }

class InteractionResult {
  final InteractionType type;
  final String title;
  final List<String> lines;
  const InteractionResult(this.type, this.title, this.lines);
  static const none = InteractionResult(InteractionType.none, '', []);
}

/// 進行中のゲームセッション。rev で再描画を通知する。
class GameSession {
  final SaveData save;
  final int rev;
  const GameSession(this.save, this.rev);

  GameSession bump() => GameSession(save, rev + 1);
}

/// ワールド・プレイヤー・所持品・図鑑など、進行状態を管理するコントローラ。
class GameController extends StateNotifier<GameSession?> {
  final Ref _ref;
  final Random _rng = Random();

  GameController(this._ref) : super(null);

  GameData get _data => _ref.read(gameDataProvider);
  SaveRepository get _saveRepo => _ref.read(saveRepositoryProvider);
  MonsterFactory get _factory => _ref.read(monsterFactoryProvider);

  SaveData? get save => state?.save;
  bool get hasActiveGame => state != null;
  bool hasSavedGame() => _saveRepo.hasSave();

  GameMap get currentMap => _data.map(save!.mapId);

  void _notify() => state = state?.bump();

  // ------------------------------------------------------------------ 開始
  Future<void> newGame(String playerName, int starterSpeciesId) async {
    final startMapId = _data.startMapId;
    final startMap = _data.map(startMapId);
    final starter = _factory.create(starterSpeciesId, 5);

    final data = SaveData(
      playerName: playerName.isEmpty ? 'トレーナー' : playerName,
      mapId: startMapId,
      playerX: startMap.spawn[0],
      playerY: startMap.spawn[1],
      money: GameConstants.startingMoney,
      party: [starter],
      box: [],
      bag: [
        BagItem(id: ItemIds.monsterBall, count: 5),
        BagItem(id: ItemIds.potion, count: 5),
      ],
      seen: {starterSpeciesId},
      caught: {starterSpeciesId},
      visitedMaps: {startMapId},
      savedAt: DateTime.now(),
    );
    state = GameSession(data, 0);
    await _saveRepo.save(data);
  }

  bool continueGame() {
    final loaded = _saveRepo.load();
    if (loaded == null) return false;
    // 種族データをひも付け
    for (final m in [...loaded.party, ...loaded.box]) {
      _factory.rebind(m);
    }
    state = GameSession(loaded, 0);
    return true;
  }

  void quitToTitle() {
    state = null;
  }

  // ------------------------------------------------------------------ 移動
  MoveResult move(Direction dir) {
    final s = save;
    if (s == null) return MoveResult.blocked;
    // バトル中は移動・エンカウントを無効化
    if (_ref.read(battleControllerProvider) != null) return MoveResult.blocked;
    s.facing = dir;

    final map = currentMap;
    final nx = s.playerX + dir.dx;
    final ny = s.playerY + dir.dy;

    // 端ワープ判定(枠の壁より優先)
    final edge = _edgeFor(dir, s, map);
    if (edge != null) {
      _applyWarp(edge.to, edge.tx, edge.ty);
      return MoveResult.moved;
    }

    if (!map.isWalkable(nx, ny) || map.npcAt(nx, ny) != null) {
      _notify();
      return MoveResult.blocked;
    }

    s.playerX = nx;
    s.playerY = ny;

    // ワープタイル
    for (final w in map.warps) {
      if (w.x == nx && w.y == ny) {
        _applyWarp(w.to, w.tx, w.ty);
        return MoveResult.moved;
      }
    }

    // 回復・ショップ
    if (map.isHealTile(nx, ny)) {
      _notify();
      return MoveResult.heal;
    }
    if (map.isShopTile(nx, ny)) {
      _notify();
      return MoveResult.shop;
    }

    // エンカウント
    if (map.isEncounterTile(nx, ny) && map.encounters.isNotEmpty) {
      if (_rng.nextDouble() < GameConstants.encounterRate) {
        final started = _startEncounter(map);
        if (started) return MoveResult.encounter;
      }
    }

    _notify();
    return MoveResult.moved;
  }

  _EdgeMatch? _edgeFor(Direction dir, SaveData s, GameMap map) {
    String? edgeName;
    if (dir == Direction.left && s.playerX <= 1) edgeName = 'left';
    if (dir == Direction.right && s.playerX >= map.width - 2) edgeName = 'right';
    if (dir == Direction.up && s.playerY <= 1) edgeName = 'top';
    if (dir == Direction.down && s.playerY >= map.height - 2) edgeName = 'bottom';
    if (edgeName == null) return null;
    for (final e in map.edgeWarps) {
      if (e.edge == edgeName) return _EdgeMatch(e.to, e.tx, e.ty);
    }
    return null;
  }

  void _applyWarp(String mapId, int tx, int ty) {
    final s = save!;
    s.mapId = mapId;
    s.playerX = tx;
    s.playerY = ty;
    s.visitedMaps.add(mapId);
    _notify();
    autosave();
  }

  bool _startEncounter(GameMap map) {
    final active = activeMonster();
    if (active == null) return false;
    final entry = _weightedEncounter(map);
    final level = entry.min + _rng.nextInt(max(1, entry.max - entry.min + 1));
    final wild = _factory.create(entry.species, level);
    markSeen(wild.speciesId);
    _ref.read(battleControllerProvider.notifier).startWild(active, wild);
    return true;
  }

  EncounterEntry _weightedEncounter(GameMap map) {
    final total = map.encounters.fold<int>(0, (a, e) => a + e.weight);
    var roll = _rng.nextInt(total);
    for (final e in map.encounters) {
      if (roll < e.weight) return e;
      roll -= e.weight;
    }
    return map.encounters.first;
  }

  // ------------------------------------------------------------------ 会話
  InteractionResult interactInFront() {
    final s = save;
    if (s == null) return InteractionResult.none;
    final map = currentMap;
    final fx = s.playerX + s.facing.dx;
    final fy = s.playerY + s.facing.dy;

    final npc = map.npcAt(fx, fy);
    if (npc != null) {
      return InteractionResult(InteractionType.talk, npc.name, npc.lines);
    }
    final sign = map.signAt(fx, fy);
    if (sign != null) {
      return InteractionResult(InteractionType.sign, 'かんばん', [sign.text]);
    }
    return InteractionResult.none;
  }

  // ------------------------------------------------------------------ 回復
  void healParty() {
    final s = save!;
    for (final m in s.party) {
      m.healFully();
    }
    _notify();
    autosave();
  }

  // ------------------------------------------------------------------ パーティ/ボックス
  MonsterInstance? activeMonster() {
    final s = save;
    if (s == null) return null;
    for (final m in s.party) {
      if (!m.isFainted) return m;
    }
    return null;
  }

  bool get hasAbleMonster => activeMonster() != null;

  void addMonster(MonsterInstance mon) {
    final s = save!;
    _factory.rebind(mon);
    if (s.party.length < GameConstants.maxPartySize) {
      s.party.add(mon);
    } else {
      s.box.add(mon);
    }
    markCaught(mon.speciesId);
    _notify();
  }

  void swapPartyOrder(int a, int b) {
    final s = save!;
    if (a < 0 || b < 0 || a >= s.party.length || b >= s.party.length) return;
    final tmp = s.party[a];
    s.party[a] = s.party[b];
    s.party[b] = tmp;
    _notify();
  }

  /// パーティからボックスへ(最低1匹は残す)
  bool sendToBox(int partyIndex) {
    final s = save!;
    if (s.party.length <= 1) return false;
    if (partyIndex < 0 || partyIndex >= s.party.length) return false;
    s.box.add(s.party.removeAt(partyIndex));
    _notify();
    return true;
  }

  bool withdrawFromBox(int boxIndex) {
    final s = save!;
    if (s.party.length >= GameConstants.maxPartySize) return false;
    if (boxIndex < 0 || boxIndex >= s.box.length) return false;
    s.party.add(s.box.removeAt(boxIndex));
    _notify();
    return true;
  }

  // ------------------------------------------------------------------ 図鑑
  void markSeen(int speciesId) {
    final s = save;
    if (s == null) return;
    if (s.seen.add(speciesId)) _notify();
  }

  void markCaught(int speciesId) {
    final s = save;
    if (s == null) return;
    s.seen.add(speciesId);
    if (s.caught.add(speciesId)) _notify();
  }

  // ------------------------------------------------------------------ 所持品/お金
  int itemCount(String id) {
    final s = save;
    if (s == null) return 0;
    final found = s.bag.where((b) => b.id == id);
    return found.isEmpty ? 0 : found.first.count;
  }

  void addItem(String id, int count) {
    final s = save!;
    final existing = s.bag.where((b) => b.id == id).toList();
    if (existing.isEmpty) {
      s.bag.add(BagItem(id: id, count: count));
    } else {
      existing.first.count += count;
    }
    _notify();
  }

  bool removeItem(String id, int count) {
    final s = save!;
    final existing = s.bag.where((b) => b.id == id).toList();
    if (existing.isEmpty || existing.first.count < count) return false;
    existing.first.count -= count;
    if (existing.first.count <= 0) {
      s.bag.removeWhere((b) => b.id == id);
    }
    _notify();
    return true;
  }

  bool buy(String itemId, int qty) {
    final s = save!;
    final def = _data.items[itemId];
    if (def == null) return false;
    final total = def.price * qty;
    if (s.money < total) return false;
    s.money -= total;
    addItem(itemId, qty);
    autosave();
    return true;
  }

  bool sell(String itemId, int qty) {
    final def = _data.items[itemId];
    if (def == null) return false;
    if (!removeItem(itemId, qty)) return false;
    save!.money += (def.price ~/ 2) * qty;
    _notify();
    autosave();
    return true;
  }

  void gainMoney(int amount) {
    save!.money += amount;
    _notify();
  }

  // ------------------------------------------------------------------ アイテム使用
  /// モンスターにアイテムを使う。成功時はメッセージを返し、アイテムを消費する。
  String? applyItem(String itemId, MonsterInstance mon) {
    final def = _data.items[itemId];
    if (def == null) return null;
    String msg;
    switch (def.category) {
      case ItemCategory.heal:
        if (mon.isFainted || mon.currentHp >= mon.maxHp) return null;
        final before = mon.currentHp;
        mon.currentHp = min(mon.maxHp, mon.currentHp + def.power.toInt());
        msg = '${mon.displayName}の HPが ${mon.currentHp - before} かいふくした！';
        break;
      case ItemCategory.statusHeal:
        final cleared = _clearStatus(itemId, mon);
        if (!cleared) return null;
        msg = '${mon.displayName}の じょうたいが もとに もどった！';
        break;
      case ItemCategory.revive:
        if (!mon.isFainted) return null;
        mon.currentHp = max(1, (mon.maxHp * def.power).toInt());
        mon.healStatusOnly();
        msg = '${mon.displayName}は げんきを とりもどした！';
        break;
      default:
        return null;
    }
    removeItem(itemId, 1);
    _notify();
    autosave();
    return msg;
  }

  bool _clearStatus(String itemId, MonsterInstance mon) {
    if (mon.status == StatusCondition.none) return false;
    switch (itemId) {
      case ItemIds.antidote:
        if (mon.status != StatusCondition.poison) return false;
        break;
      case ItemIds.awakening:
        if (mon.status != StatusCondition.sleep) return false;
        break;
      case ItemIds.paralyzeHeal:
        if (mon.status != StatusCondition.paralyze) return false;
        break;
      case ItemIds.fullHeal:
        break; // どの状態でもOK
      default:
        return false;
    }
    mon.status = StatusCondition.none;
    mon.sleepTurns = 0;
    return true;
  }

  /// 全滅時の処理: 回復してスタートの街へ戻す。
  void whiteout() {
    final s = save!;
    healParty();
    final startMap = _data.map(_data.startMapId);
    s.mapId = _data.startMapId;
    s.playerX = startMap.spawn[0];
    s.playerY = startMap.spawn[1];
    _notify();
    autosave();
  }

  // ------------------------------------------------------------------ 保存
  void refresh() => _notify();

  Future<void> save_() async {
    final s = save;
    if (s != null) await _saveRepo.save(s);
  }

  void autosave() {
    final s = save;
    if (s != null) {
      // ベストエフォート(awaitしない)
      _saveRepo.save(s);
    }
  }
}

class _EdgeMatch {
  final String to;
  final int tx;
  final int ty;
  const _EdgeMatch(this.to, this.tx, this.ty);
}
