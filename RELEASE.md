# リリース手順書 — モンスターズ・エレメンタ

本書は Android 向けリリースビルド（APK / AAB）の作成手順をまとめたものです。

## 1. 前提環境

| ツール | バージョン |
| --- | --- |
| Flutter SDK | stable 3.27.x |
| Dart | 3.6 以上（Flutter同梱） |
| JDK | 17（AGP 8.6 / Gradle 8.9 と互換） |
| Android SDK | platform-tools / platforms;android-35 / build-tools;35.0.0 |

ネットワークから **Google Maven（`dl.google.com`, `maven.google.com`）** にアクセスできることが必須です。

### 環境確認
```bash
flutter --version
flutter doctor          # Android toolchain が ✓ であること
```

## 2. 依存関係の取得
```bash
flutter pub get
```

## 3. 品質ゲート（リリース前チェック）
```bash
flutter analyze         # 0 issue であること
flutter test            # 全テスト pass であること
```

## 4. バージョン番号の更新

`pubspec.yaml` の `version` を更新します（`<バージョン名>+<ビルド番号>`）。
```yaml
version: 1.0.0+1   # 例: 1.0.1+2 に更新
```
- `1.0.0` … `versionName`（ユーザー向け表示）
- `+1` … `versionCode`（ストアで単調増加が必須）

## 5. 署名設定（ストア配布時）

開発中はデバッグ鍵で署名されます（`android/app/build.gradle` の `signingConfig = signingConfigs.debug`）。
ストア配布には専用のリリース鍵を作成します。

```bash
keytool -genkey -v -keystore ~/elementa-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias elementa
```

`android/key.properties` を作成（このファイルは Git 管理しないこと）：
```properties
storePassword=********
keyPassword=********
keyAlias=elementa
storeFile=/絶対パス/elementa-release.jks
```

`android/app/build.gradle` にリリース署名を追加：
```gradle
// android { } の前
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release   // debug から変更
        }
    }
}
```

## 6. ビルド

### APK（端末への直接配布・サイドロード）
```bash
flutter build apk --release
# 出力: build/app/outputs/flutter-apk/app-release.apk
```

ABIごとに分割（サイズ削減）：
```bash
flutter build apk --release --split-per-abi
# app-armeabi-v7a-release.apk / app-arm64-v8a-release.apk / app-x86_64-release.apk
```

### App Bundle（Google Play 推奨）
```bash
flutter build appbundle --release
# 出力: build/app/outputs/bundle/release/app-release.aab
```

## 7. 動作確認（リリースビルド）
```bash
flutter install --release          # 接続端末へインストール
# または
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
- 起動 → 新規ゲーム → 御三家選択 → 移動 → エンカウント → バトル → 捕獲 → セーブ → 再起動して「つづきから」で復帰できることを確認。

## 8. CI による自動ビルド

`.github/workflows/build.yml` が push / PR / 手動実行で以下を自動化します。
1. `flutter analyze`
2. `flutter test`
3. `flutter build apk --release`（通常版 + ABI分割版）
4. APK を **Actions の Artifacts**（`elementa-monsters-apk`）にアップロード

GitHub の **Actions** タブから生成された APK をダウンロードできます。

## 9. ストア提出チェックリスト

- [ ] `versionCode` を前回より増加させた
- [ ] リリース鍵で署名した AAB を用意した
- [ ] アプリ名・アイコン・スクリーンショットを用意した
- [ ] プライバシーポリシー（本アプリはオフライン・データ収集なし）
- [ ] 権利表記：完全オリジナル作品である旨を明記
