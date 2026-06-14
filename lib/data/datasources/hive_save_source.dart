import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/game_constants.dart';

/// Hive を使った低レベルのキー/バリュー保存。
///
/// セーブデータは JSON 文字列としてそのまま格納するため、
/// TypeAdapter の生成(build_runner)は不要で堅牢。
class HiveSaveSource {
  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(GameConstants.hiveBoxName);
  }

  Box<String> get _requireBox {
    final b = _box;
    if (b == null) throw StateError('HiveSaveSource が init されていません');
    return b;
  }

  String? read(String key) => _requireBox.get(key);

  Future<void> write(String key, String value) => _requireBox.put(key, value);

  Future<void> remove(String key) => _requireBox.delete(key);

  bool contains(String key) => _requireBox.containsKey(key);
}
