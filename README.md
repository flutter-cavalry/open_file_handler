# open_file_handler

Adds "Open with app" functionality to your Flutter app.

- This plugin is **NOT** about handling deep links, universal links or network links.
- This plugin is **NOT** about handling share content.
- This plugin is about handling **Open with app** functionality on iOS / Android / macOS.
  - On iOS / macOS, no need to create share extensions!
- Handles both cold start and warm start in a single API!

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
    <string>Alternate</string>
  </dict>
</array>
```

Handle incoming URLs in `AppDelegate.swift`:

```swift
override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
  OpenFileHandlerPlugin.handleOpenURIs([url])
  return true
}
```

See "Usage - Flutter" below for Dart side usage.

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
    <string>Alternate</string>
  </dict>
</array>
```

Handle incoming URLs in `AppDelegate.swift`:

```swift
override func application(_ application: NSApplication, open urls: [URL]) {
  OpenFileHandlerPlugin.handleOpenURIs(urls)
}
```

See "Usage - Flutter" below for Dart side usage.

### Android

Add intent filters to your `AndroidManifest.xml` file to specify the types of files your app can handle. For example:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <!-- Media types your app can handle -->
    <data android:mimeType="image/*" />
    <data android:mimeType="video/*" />
    <data android:mimeType="audio/*" />
</intent-filter>
```

Handle incoming intents in main activity `MainActivity.kt`:

```kotlin
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
    if (intent.action == Intent.ACTION_VIEW || intent.action == Intent.ACTION_EDIT) {
        val uri = intent.data
        if (uri != null) {
            // See below for usage on `copyToLocal` option.
            val copyToLocal = true;
            OpenFileHandlerPlugin.handleOpenURIs(listOf(uri), copyToLocal)
        }
    }
}
```

#### `copyToLocal`

Unlike iOS / macOS, where file URLs can be converted to file paths directly, Android file URIs may not be directly accessible due to permission issues. To handle this, you use the `copyToLocal`.

- When `false`: no copy is made, and the URI is passed as-is to Dart side.
  - You can use my other packages to handle Android file URIs: [saf_stream](https://pub.dev/packages/saf_stream), [saf_util](https://pub.dev/packages/saf_util).
- When `true`: the file is copied to your app's local cache directory, and the local file path is passed to Dart side.

See "Usage - Flutter" below for Dart side usage.

### Flutter (this applies to all supported platforms)

```dart
final _openFileHandlerPlugin = OpenFileHandler();

// Usually in `initState` of your widget.
// This handles both cold start and warm start.
//  Cold start: your app is not running, user taps "Open with app".
//  Warm start: your app is running, user taps "Open with app".
_openFileHandlerPlugin.listen(
  (files) {
    // Handle incoming files.
    // `files` is a list of [OpenFileHandlerFile] objects with the following properties:
    // - `uri`: The URI/URL of the file. Always available.
    // - `name`: The name of the file.
    //   iOS/macOS: Always available.
    //   Android: Could be null if `DISPLAY_NAME` is not available from the content resolver.
    // - `path`: The path to the file.
    //   iOS/macOS: Always available.
    //   Android: Only available if you set `copyToLocal` to true when calling `OpenFileHandlerPlugin.handleOpenURIs`.
  },
  onError: (error) {
    // Handle error.
  },
);
```
