# open_file_handler

[![pub package](https://img.shields.io/pub/v/open_file_handler.svg)](https://pub.dev/packages/open_file_handler)

Flutter plugin to add 'Open with app' functionality to your app.

- This plugin is **NOT** about handling deep links, universal links or network links.
- This plugin is **NOT** about handling shared content.
- This plugin is about handling **Open with app** functionality on iOS / Android / macOS.
  - No need to create Xcode share extensions to use this plugin.
  - On iOS, this adds your app to 'Open with' menu in the Files app.
  - On macOS, this adds your app to 'Open with' menu in Finder.
- Handles both cold start and warm start in a single API!

## Requirements

- Android: AGP 9+ (Flutter 3.44+)
- iOS: [UISceneDelegate adoption](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)

## Usage

### iOS

Add `CFBundleDocumentTypes` to your `Info.plist` file to specify the types of files your app can handle. For example:

```xml
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>
    <string>Image File</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.image</string>
    </array>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSHandlerRank</key>
    <string>Default</string>
  </dict>
</array>
```

If your app can open the original document from Files app instead of an imported copy, you should enable in-place opening in your iOS `Info.plist`:

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

Call `OpenFileHandlerPlugin.handleOpenURI` in iOS scene delegate methods:

```swift
import open_file_handler

override func scene(
  _ scene: UIScene, willConnectTo session: UISceneSession,
  options connectionOptions: UIScene.ConnectionOptions
) {
  super.scene(scene, willConnectTo: session, options: connectionOptions)
  if let context = connectionOptions.urlContexts.first {
    OpenFileHandlerPlugin.handleOpenURI(context, alwaysCopy: false)
  }
}

override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  super.scene(scene, openURLContexts: URLContexts)
  if let context = URLContexts.first {
    OpenFileHandlerPlugin.handleOpenURI(context, alwaysCopy: false)
  }
}
```

When `alwaysCopy` is false, iOS copies only if `context.options.openInPlace` is false; when true, it always copies. Copies go to `<Caches dir>/_app/open_file_handler/<file>`.

See "Usage - Flutter" below for Flutter side usage.

### macOS

Add `CFBundleDocumentTypes` to your `Info.plist` file to specify the types of files your app can handle. For example:

```xml
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>
    <string>Image File</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.image</string>
    </array>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSHandlerRank</key>
    <string>Default</string>
  </dict>
</array>
```

Call `OpenFileHandlerPlugin.handleOpenURI` for the files you want to handle in your macOS `AppDelegate`:

```swift
import open_file_handler

override func application(_ application: NSApplication, open urls: [URL]) {
  super.application(application, open: urls)
  if let url = urls.first {
    OpenFileHandlerPlugin.handleOpenURI(url)
  }
}
```

See "Usage - Flutter" below for Flutter side usage.

### Android

Add intent filters to your `AndroidManifest.xml` file to specify the types of files your app can handle. For example:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />

    <!-- Media types your app can handle -->
    <data android:mimeType="image/*" />
    <data android:mimeType="video/*" />
    <data android:mimeType="audio/*" />
</intent-filter>
```

Set the activity's `android:launchMode` to `singleTask` and leave `android:taskAffinity` unset so Android can bring the existing app task forward. Handle incoming intents in main activity `MainActivity.kt`:

```kotlin
import com.fluttercavalry.open_file_handler.OpenFileHandlerPlugin

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleIntent(intent)
}

override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    handleIntent(intent)
}

private fun handleIntent(intent: Intent) {
    if (intent.action == Intent.ACTION_VIEW
        || intent.action == Intent.ACTION_EDIT
        // If `Intent.ACTION_SEND` is present in `AndroidManifest.xml`, it should be handled here as well.
        || intent.action == Intent.ACTION_SEND
    ) {
        val uri = intent.data ?: intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
        if (uri != null) {
            OpenFileHandlerPlugin.handleOpenURI(
                uri,
            alwaysCopy = true,
            )
        }
    }
}
```

#### `alwaysCopy`


- When `false`: files are not copied and URIs are passed directly to Flutter without local file paths.
  - You can use my other packages to read Android file URIs: [saf_stream](https://pub.dev/packages/saf_stream), [saf_util](https://pub.dev/packages/saf_util).
- When `true`: the file is copied to `context.cacheDir/_app/open_file_handler/<file>`. The original URI and local path are passed to Flutter.

See "Usage - Flutter" below for Flutter side usage.

### Flutter (this applies to all supported platforms)

```dart
final _openFileHandlerPlugin = OpenFileHandler();

// Usually in `initState` of your widget.
// This handles both cold start and warm start.
//  Cold start: your app is not running, user taps "Open with app".
//  Warm start: your app is running, user taps "Open with app".
_openFileHandlerPlugin.listen(
  (file) async {
    // Handle the incoming OpenFileHandlerFile with the following properties:
    // - `uri`: The original URI/URL of the file, even when copied. Always available.
    // - `name`: The name of the file.
    //   iOS/macOS: Always available.
    //   Android: Could be null if `DISPLAY_NAME` is not available from the content resolver.
    // - `path`: The path to the file.
    //   iOS: The original URL path, or the local cache path when copied.
    //   macOS: The original URL path.
    //   Android: The local cache path when `alwaysCopy` is true; otherwise null.
    // - `localCopy`: Whether `path` is reported as a local copy.
    //   iOS: True when copied because `openInPlace` is false or `alwaysCopy` is true.
    //   macOS: Always true.
    //   Android: True when `alwaysCopy` successfully copied the file.
    // - `localCopy`: Whether the plugin reports a local copy.
    //   iOS: True when the plugin copied the file; otherwise false.
    //   macOS: Always true.
    //   Android: True when `alwaysCopy` succeeded; otherwise false.

    // iOS only: release security-scoped URLs if needed.
    if (Platform.isIOS) {
      await _openFileHandlerPlugin.releaseIosURIs();
    }
  },
  onError: (error) {
    // Handle error.
  },
);
```
