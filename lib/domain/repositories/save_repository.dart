import '../entities/save_data.dart';

/// セーブデータの永続化を抽象化するリポジトリ。
abstract class SaveRepository {
  Future<void> init();

  /// セーブデータが存在するか
  bool hasSave();

  /// ロード(なければ null)
  SaveData? load();

  /// 保存
  Future<void> save(SaveData data);

  /// 削除
  Future<void> delete();

  /// バックアップ用に JSON 文字列としてエクスポート
  String exportJson();

  /// JSON 文字列からインポートして保存
  Future<SaveData> importJson(String json);
}
