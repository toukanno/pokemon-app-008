import '../entities/game_data.dart';

/// 静的ゲームデータの取得を抽象化するリポジトリ。
abstract class GameDataRepository {
  /// JSONアセットからゲームデータをロードする。
  Future<GameData> load();
}
