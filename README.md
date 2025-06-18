# open_file_handler

Flutter plugin to add 'Open with app' functionality to your app (iOS /macOS only).

Note that **this is not share extension**. This plugin is based on `CFBundleDocumentTypes` and `AppDelegate` methods to handle file opening events. To trigger the 'Open with this app' functionality:

- iOS
  - In Files app, long press on a file, select "Share", then choose your app from the list.
- macOS
  - In Finder, right-click on a file, select "Open With", then choose your app from the list.

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

Add the following to your `AppDelegate.swift`:

```swift
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    NotificationCenter.default.post(name: NSNotification.Name("open_file_handler/events"), object: nil, userInfo: ["urls": [url]])
    return true
  }
```

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

Add the following to your `AppDelegate.swift`:

```swift
  override func application(_ application: NSApplication, open urls: [URL]) {
    NotificationCenter.default.post(name: NSNotification.Name("open_file_handler/events"), object: nil, userInfo: ["urls": urls])
  }
```

### Dart side (this applies to all supported platforms)

```dart
final _openFileHandlerPlugin = OpenFileHandler();

// Usually in `initState` of your widget.
_openFileHandlerPlugin.listen(
  (files) {
    // Handle files.
    // Each file is a [OpenFileHandlerFile] object with the following properties:
    // - `name`: The name of the file.
    // - `path`: The path to the file.
    // - `uri`: The URI/URL of the file.
  },
  onError: (error) {
    // Handle error.
  },
);
```
