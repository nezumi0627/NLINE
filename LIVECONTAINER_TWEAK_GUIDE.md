# LiveContainer 向け Tweak 開発仕様書

LiveContainer で動作する Tweak（.dylib）を開発する際の特殊な仕様、制約、および推奨設定についてまとめます。

## 1. ビルド構成 (Theos / Makefile)

### Rootless ターゲット
LiveContainer は非脱獄環境で動作するため、脱獄環境向けの絶対パス（`/Library/...` など）に依存しない **Rootless** スキームでのビルドが必要です。
- `Makefile` またはビルドコマンドで `THEOS_PACKAGE_SCHEME=rootless` を指定します。

### Substrate の依存関係 (rpath)
非脱獄環境には `/Library/Frameworks/CydiaSubstrate.framework` が存在しません。LiveContainer が提供する Substrate を利用するために、dylib の依存パスを相対パス（`@rpath`）に修正する必要があります。

**修正が必要なパスの例:**
- `/usr/lib/libsubstrate.dylib` → `@rpath/libsubstrate.dylib`
- `/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate` → `@rpath/CydiaSubstrate.framework/CydiaSubstrate`

**修正コマンド (Build Workflow 等で実行):**
```bash
install_name_tool -change /usr/lib/libsubstrate.dylib @rpath/libsubstrate.dylib YourTweak.dylib
install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate @rpath/CydiaSubstrate.framework/CydiaSubstrate YourTweak.dylib
```

## 2. アプリ内での制約 (Sandboxing)

### ファイルアクセス
- **/var/mobile/Library/Preferences/** などのシステムパスへの書き込み・読み込みはできません。
- Preferences（設定）を保存する場合は、アプリのドキュメントディレクトリ内や `NSUserDefaults`（SuiteName を指定しない標準的なもの）を使用してください。

### UIWindow / ライフサイクル
- LiveContainer 自体がホストアプリとして機能しているため、`[UIApplication sharedApplication].keyWindow` が意図したタイミングで取得できない場合があります。
- アラート表示など UI 操作を行う場合は、`dispatch_after` で少し待機するか、`rootViewController` が確実に存在することを確認してから実行してください。

## 3. 導入と実行

### ファイル形式
- LiveContainer は `.deb` ファイルではなく、直接的な `.dylib` ファイル（および設定用の `.plist`）を読み込みます。
- GitHub Actions 等でビルドした後は、`.theos/obj/` 内の `.dylib` を抽出して配布/使用します。

### フィルタ設定 (.plist)
- Tweak がどのアプリに注入されるかは、`.dylib` と同名の `.plist` ファイル内の `Bundles` 指定（例: `jp.naver.line`）に基づきます。
- LiveContainer の Tweak 管理画面でアプリごとにオン/オフを切り替えることも可能です。

## 4. デバッグ

### ログの確認
- `NSLog` は LiveContainer 内のログビューアー、または Mac の「コンソール」アプリ（デバイスを接続）から確認できます。
- 独自の接頭辞（例: `[NLINE]`）を付けてフィルタリングしやすくすることを推奨します。

### JIT (Just-In-Time)
- フック（Hooking）の動作には JIT が必要です。LiveContainer の設定で JIT が有効になっていることを確認してください（JIT が無効だと多くの Tweak は正しく動作しません）。

---

このドキュメントは LiveContainer 環境での Tweak 開発を円滑に進めるためのガイドラインです。仕様変更に合わせて随時更新してください。
