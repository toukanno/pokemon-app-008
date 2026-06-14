import 'dart:convert';

import '../../core/constants/game_constants.dart';
import '../../domain/entities/save_data.dart';
import '../../domain/repositories/save_repository.dart';
import '../datasources/hive_save_source.dart';

class SaveRepositoryImpl implements SaveRepository {
  final HiveSaveSource _source;
  SaveRepositoryImpl(this._source);

  @override
  Future<void> init() => _source.init();

  @override
  bool hasSave() => _source.contains(GameConstants.saveKey);

  @override
  SaveData? load() {
    final raw = _source.read(GameConstants.saveKey);
    if (raw == null) return null;
    try {
      return SaveData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 破損データは無視
      return null;
    }
  }

  @override
  Future<void> save(SaveData data) async {
    data.savedAt = DateTime.now();
    await _source.write(GameConstants.saveKey, jsonEncode(data.toJson()));
  }

  @override
  Future<void> delete() => _source.remove(GameConstants.saveKey);

  @override
  String exportJson() {
    final raw = _source.read(GameConstants.saveKey);
    return raw ?? '';
  }

  @override
  Future<SaveData> importJson(String json) async {
    // 妥当性チェック(失敗時は例外)
    final data = SaveData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    await _source.write(GameConstants.saveKey, jsonEncode(data.toJson()));
    return data;
  }
}
