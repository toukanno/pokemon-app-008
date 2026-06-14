# モンスターズ・エレメンタ (Elementa Monsters)

初代モンスター収集RPGに **強くインスパイアされた完全オリジナル** の Android 向けゲームです。
Nintendo / Game Freak / Creatures の著作物・商標は一切使用していません。モンスター・タイプ・技・地名・ストーリーはすべて本作の創作です。

> 旧バージョン(PokeAPI を使ったブラウザ版の習作)は `legacy_web/` に保管しています。本作は Flutter による完全な作り直しです。

---

## 特徴

| 分類 | 内容 |
| --- | --- |
| ジャンル | モンスター収集RPG |
| 対応 | Android（オフラインプレイ対応） |
| UI | 日本語 / レトロRPG風 / ダークモード対応 / 縦横画面両対応 |
| モンスター | **151種**（オリジナル）・属性12種・進化・図鑑・捕獲 |
| バトル | ターン制・4つの技・状態異常・属性相性・経験値・レベルアップ・進化 |
| ワールド | 複数の街/道路/ダンジョン・草むらランダムエンカウント・NPC会話・ショップ・回復施設 |
| データ | JSONベース・Hiveローカル保存・バックアップ/復元機能 |

### モンスター・スプライトについて

150体以上のモンスターのドット絵は、**画像アセットを使わず** 種族データ（ID・カラー・形状番号）から
`CustomPainter` で手続き的に生成しています（`lib/presentation/widgets/monster_sprite.dart`）。
これにより著作権上の懸念がなく、完全オフラインで多数のモンスターを表現できます。

---

## 技術スタック / アーキテクチャ

- **Flutter**（stable 3.27.x）/ Dart 3
- **Riverpod**（状態管理）
- **go_router**（ルーティング）
- **Hive**（ローカル永続化 / NoSQL）
- **Clean Architecture + Repository パターン**

```
lib/
├── main.dart                  # エントリポイント（Hive初期化・データロード・DI）
├── app.dart                   # MaterialApp.router・テーマ
├── core/                      # 横断的関心事（定数・テーマ・ルータ・ユーティリティ）
│   ├── constants/
│   ├── theme/
│   ├── router/
│   └── utils/
├── domain/                    # ビジネスルール（フレームワーク非依存）
│   ├── entities/              # MonsterSpecies / MonsterInstance / Move / SaveData ...
│   ├── repositories/          # 抽象インタフェース
│   └── services/              # BattleEngine / MonsterFactory（純粋ロジック）
├── data/                      # データ層（実装）
│   ├── datasources/           # AssetDataSource（JSON）/ HiveSaveSource
│   └── repositories/          # *RepositoryImpl
├── application/               # アプリケーション層（Riverpod コントローラ）
│   ├── providers.dart
│   ├── game_controller.dart   # ワールド・所持品・図鑑・セーブ
│   ├── battle_controller.dart # バトル進行
│   └── settings_controller.dart
└── presentation/              # UI層
    ├── screens/               # 各画面
    └── widgets/               # 再利用ウィジェット
```

依存方向は `presentation → application → domain ← data` で、`domain` は外側に依存しません。

### データ

ゲームの静的データは `assets/data/` に JSON で格納し、`tools/` の Python スクリプトで生成・再生成できます。

| ファイル | 内容 | 生成スクリプト |
| --- | --- | --- |
| `monsters.json` | モンスター151種の種族データ | `tools/generate_data.py` |
| `moves.json` | 技43種 | `tools/generate_data.py` |
| `types.json` | 属性12種と相性表 | `tools/generate_data.py` |
| `world.json` | 街/道路/ダンジョンのマップ・NPC・エンカウント | `tools/generate_world.py` |

```bash
python3 tools/generate_data.py    # monsters/moves/types を再生成
python3 tools/generate_world.py   # world を再生成
```

---

## あそびかた

1. タイトルで「さいしょから」を選び、なまえと最初のパートナー（くさ/ほのお/みず）を選択
2. 十字キー（画面ボタン / 矢印キー・WASD）で移動。`A`ボタンでNPCや看板を調べる
3. **しげみ** に入ると野生モンスターとランダムエンカウント
4. バトルは「たたかう / どうぐ / モンスター / にげる」のターン制。すばやさで先攻が決まる
5. **エレメンボール** で捕獲して仲間を増やす（手持ち6匹、超過分はボックスへ）
6. **かいふくセンター**（赤い屋根）に乗ると全回復、**ショップ**（青い屋根）で道具購入
7. メニューから ずかん・どうぐ・ボックス・せってい・セーブ が可能

### 操作

| 操作 | 入力 |
| --- | --- |
| 移動 | 画面の十字キー / 矢印キー / WASD |
| 調べる・決定 | `A`ボタン / Z / Enter / Space |
| メニュー | `≡`ボタン |

---

## ビルド / 実行

### 必要環境
- Flutter SDK 3.27.x（stable）
- Android SDK（platform 35 / build-tools）+ JDK 17

```bash
flutter pub get
flutter run                 # 接続中の端末/エミュレータで実行
flutter analyze             # 静的解析
flutter test                # 単体テスト
flutter build apk --release # リリースAPK
```

詳細は **[RELEASE.md](RELEASE.md)**（リリース手順書）、テストは **[TESTING.md](TESTING.md)**（テスト手順書）を参照してください。

> **ビルドに関する注意**：Android のビルドには Google Maven（`dl.google.com` / `maven.google.com`）へのアクセスが必須です。
> ネットワーク制限のある CI/サンドボックス環境では、付属の GitHub Actions ワークフロー
> `.github/workflows/build.yml` が解析・テスト・APKビルドを自動実行し、APK を成果物としてアップロードします。

---

## ライセンス / 権利表記

本作は学習・創作目的のオリジナル作品です。既存の商業作品のキャラクター・名称・画像・音源は使用していません。
