import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/datasources/asset_data_source.dart';
import 'data/datasources/hive_save_source.dart';
import 'data/repositories/game_data_repository_impl.dart';
import 'data/repositories/save_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 縦横両対応
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 永続化(Hive)を初期化
  final hiveSource = HiveSaveSource();
  final saveRepo = SaveRepositoryImpl(hiveSource);
  await saveRepo.init();

  // 静的ゲームデータをロード
  final dataRepo = GameDataRepositoryImpl(AssetDataSource());
  final gameData = await dataRepo.load();

  runApp(
    ProviderScope(
      overrides: [
        gameDataProvider.overrideWithValue(gameData),
        saveRepositoryProvider.overrideWithValue(saveRepo),
        hiveSourceProvider.overrideWithValue(hiveSource),
      ],
      child: const ElementaApp(),
    ),
  );
}
