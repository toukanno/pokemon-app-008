import '../../domain/entities/game_data.dart';
import '../../domain/repositories/game_data_repository.dart';
import '../datasources/asset_data_source.dart';

class GameDataRepositoryImpl implements GameDataRepository {
  final AssetDataSource _source;
  GameData? _cache;

  GameDataRepositoryImpl(this._source);

  @override
  Future<GameData> load() async {
    return _cache ??= await _source.load();
  }
}
