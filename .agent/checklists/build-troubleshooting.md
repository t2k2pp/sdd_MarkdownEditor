# Flutter ビルドトラブルシューティング

ビルドエラー発生時のクイックリファレンス。

---

## エラーメッセージ → 解決策マッピング

### Android

| エラーメッセージ | 原因 | 解決策 |
|----------------|------|--------|
| `uses-sdk:minSdkVersion X cannot be smaller than version Y` | プラグインがより高いminSdkを要求 | `android/app/build.gradle` の `minSdk` を Y に引き上げ |
| `NDK at ... did not have a source.properties file` | NDKバージョン不一致 | `sdkmanager "ndk;27.0.12077973"` でインストール |
| `Unresolved reference: Registrar` | 古いFlutter Embedding v1 API | パッケージを最新版に更新 |
| `Execution failed for task ':app:compileDebugKotlin'` | Kotlin互換性問題 | Kotlinバージョン確認、AGP/Gradle更新 |
| `Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'` | Gradle同期失敗 | `./gradlew clean` 後に再ビルド |
| `The project uses incompatible version of the Android Gradle plugin` | AGP/Gradle不一致 | 互換性マトリクス参照して両方更新 |
| `Minimum supported Gradle version is X.Y` | Gradle古い | `gradle-wrapper.properties` 更新 |
| `Plugin with id 'kotlin-android' not found` | Kotlin設定漏れ | `build.gradle` に kotlin plugin 追加 |

### iOS

| エラーメッセージ | 原因 | 解決策 |
|----------------|------|--------|
| `CocoaPods could not find compatible versions` | Pod依存関係競合 | `rm -rf Pods Podfile.lock && pod install --repo-update` |
| `The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to X.X` | iOS最低バージョン不一致 | Podfile と project.pbxproj を更新 |
| `No such module 'Flutter'` | Flutter framework不足 | `flutter clean && flutter pub get && cd ios && pod install` |
| `Signing for "Runner" requires a development team` | 署名設定未設定 | Xcode でチーム選択、または `--no-codesign` |
| `Unable to load contents of file list` | 生成ファイル不足 | `flutter clean && flutter build ios` |
| `Multiple commands produce` | ビルド設定競合 | DerivedData削除、クリーンビルド |

### 共通

| エラーメッセージ | 原因 | 解決策 |
|----------------|------|--------|
| `Error: Cannot run with sound null safety` | null-safety不整合 | `flutter pub upgrade --major-versions` |
| `Pub get failed` | パッケージ解決失敗 | `flutter pub cache repair` |
| `Target of URI doesn't exist` | import先不在 | パッケージ依存関係確認、`flutter pub get` |

---

## 環境問題クイックフィックス

### Androidビルド失敗時

```powershell
# 1. クリーンビルド
flutter clean
flutter pub get

# 2. Gradleキャッシュクリア
cd android
./gradlew clean
./gradlew --stop
cd ..

# 3. 再ビルド
flutter build apk --debug
```

### iOSビルド失敗時

```bash
# 1. クリーンビルド
flutter clean
flutter pub get

# 2. Podsクリア
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*
pod cache clean --all
pod install --repo-update
cd ..

# 3. 再ビルド
flutter build ios --debug --no-codesign
```

---

## バージョン互換性確認

### AGP/Gradle/Kotlin マトリクス

| AGP | Gradle | Kotlin | Java |
|-----|--------|--------|------|
| 8.1.x | 8.0+ | 1.9.0+ | 17 |
| 8.2.x | 8.4+ | 1.9.22+ | 17 |
| 8.3.x | 8.5+ | 2.0.0+ | 17 |

### Xcode/Swift/iOS マトリクス

| Xcode | Swift | iOS最低 |
|-------|-------|---------|
| 15.0+ | 5.9+ | 12.0+ |
| 15.2+ | 5.9.2+ | 13.0+ |
| 16.0+ | 6.0+ | 13.0+ |

---

## チェックポイント

ビルドエラー発生時の確認順序:

1. [ ] `flutter doctor -v` で環境確認
2. [ ] エラーメッセージを上記表で検索
3. [ ] 該当パッケージのGitHub Issueを検索
4. [ ] `flutter clean && flutter pub get` 実行
5. [ ] プラットフォーム固有のクリーンビルド実行
6. [ ] バージョン互換性マトリクス確認
7. [ ] 解決しない場合はユーザーに報告
