import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/hive_save_source.dart';
import '../domain/entities/battle_state.dart';
import '../domain/entities/game_data.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/services/battle_engine.dart';
import '../domain/services/monster_factory.dart';
import 'battle_controller.dart';
import 'game_controller.dart';
import 'settings_controller.dart';

/// main() で override される: ロード済みの静的ゲームデータ。
final gameDataProvider = Provider<GameData>((ref) {
  throw UnimplementedError('gameDataProvider は main() で override してください');
});

/// main() で override される: 初期化済みセーブリポジトリ。
final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  throw UnimplementedError('saveRepositoryProvider は main() で override してください');
});

/// main() で override される: 設定永続化用の Hive ソース。
final hiveSourceProvider = Provider<HiveSaveSource>((ref) {
  throw UnimplementedError('hiveSourceProvider は main() で override してください');
});

final battleEngineProvider = Provider<BattleEngine>((ref) {
  return BattleEngine(ref.watch(gameDataProvider));
});

final monsterFactoryProvider = Provider<MonsterFactory>((ref) {
  return MonsterFactory(ref.watch(gameDataProvider));
});

final settingsProvider =
    StateNotifierProvider<SettingsController, GameSettings>((ref) {
  return SettingsController(ref.watch(hiveSourceProvider));
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSession?>((ref) {
  return GameController(ref);
});

final battleControllerProvider =
    StateNotifierProvider<BattleController, BattleState?>((ref) {
  return BattleController(ref);
});
