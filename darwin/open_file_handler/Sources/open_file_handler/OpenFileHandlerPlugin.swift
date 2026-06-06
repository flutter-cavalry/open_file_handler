import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var _pendingURIs: [URL] = []
  private var _iosURLsToRelease: [URL] = []

  private var _eventSink: FlutterEventSink?

  func processURLs() -> Bool {
    if let eventSink = _eventSink {

      var urlsWithAccess = _pendingURIs
      _pendingURIs = []

      #if os(iOS)
        // For files shared from Files app, we need to call `startAccessingSecurityScopedResource` to get the access permission. We also need to remember to call `stopAccessingSecurityScopedResource` when the permission is no longer needed, which will be handled in `releaseIosURIs` method.
        // For files shared from Photos app, we don't need to call `startAccessingSecurityScopedResource`, and we can directly access the file using the URL.
        _iosURLsToRelease = urlsWithAccess.filter { $0.startAccessingSecurityScopedResource() }
      #endif

      if !urlsWithAccess.isEmpty {
        let uriMaps = urlsWithAccess.map { urlToMap($0) }
        eventSink(uriMaps)
        return true
      }
    }
    return false
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let binaryMessenger = registrar.messenger()
    #elseif os(macOS)
      let binaryMessenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "open_file_handler", binaryMessenger: binaryMessenger)
    let instance = OpenFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "open_file_handler/hot_uris", binaryMessenger: binaryMessenger)
    eventChannel.setStreamHandler(instance)

    #if os(iOS)
      registrar.addSceneDelegate(instance)
    #elseif os(macOS)
      registrar.addApplicationDelegate(instance)
    #endif
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "releaseIosURIs":
      #if os(iOS)
        for url in _iosURLsToRelease {
          url.stopAccessingSecurityScopedResource()
        }
        _iosURLsToRelease = []
      #endif
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    _eventSink = events
    processURLs()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    _eventSink = nil
    return nil
  }
}

#if os(iOS)
  extension OpenFileHandlerPlugin: FlutterSceneLifeCycleDelegate {
    // Called when the app launches and creates a new scene.
    public func scene(
      _ scene: UIScene, willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
      let urls = connectionOptions?.urlContexts.map { $0.url }

      _pendingURIs.append(contentsOf: urls ?? [])

      // Return false here to allow other plugins to handle `willConnectTo` event.
      return false
    }

    // Called when the app is already running in memory
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool
    {
      let urls = URLContexts.map { $0.url }
      _pendingURIs.append(contentsOf: urls)
      processURLs()

      // Return true because we are expected to handle the URLs in this callback, and we don't want other plugins to also handle the same URLs.
      return true
    }
  }
#endif

#if os(macOS)
  extension OpenFileHandlerPlugin: FlutterAppLifecycleDelegate {
    public func handleOpen(_ urls: [URL]) -> Bool {
      _pendingURIs.append(contentsOf: urls)
      processURLs()
      
      // Return true because we are expected to handle the URLs in this callback, and we don't want other plugins to also handle the same URLs.
      return true
    }
  }
#endif

func urlToMap(_ url: URL) -> [String: Any?] {
  return [
    "name": url.lastPathComponent,
    "path": url.path,
    "uri": url.absoluteString,
  ]
}
