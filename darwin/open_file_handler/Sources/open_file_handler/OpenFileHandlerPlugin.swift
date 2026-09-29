// Import the correct Flutter module and UI framework for each platform
#if os(iOS)
  import Flutter
  import UIKit
#elseif os(macOS)
  import FlutterMacOS
  import Cocoa
#endif

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var pendingURI: URL?
  private var iosURLsToRelease: [URL] = []
  private var eventSink: FlutterEventSink?

  private func processURLs() {
    guard let eventSink = eventSink, let url = pendingURI else { return }
    pendingURI = nil

    #if os(iOS)
      if url.startAccessingSecurityScopedResource() {
        iosURLsToRelease.append(url)
      }
    #endif

    eventSink(urlToMap(url))
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar's `messenger` is a method on iOS and a property on macOS.
    // Use a compile-time condition to handle this difference.
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(name: "open_file_handler", binaryMessenger: messenger)
    let instance = OpenFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "open_file_handler/hot_uris", binaryMessenger: messenger)
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
        for url in iosURLsToRelease {
          url.stopAccessingSecurityScopedResource()
        }
        iosURLsToRelease = []
      #endif
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    processURLs()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

#if os(iOS)
  extension OpenFileHandlerPlugin: FlutterSceneLifeCycleDelegate {
    public func scene(
      _ scene: UIScene, willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
      if let url = connectionOptions?.urlContexts.first?.url {
        pendingURI = url
      }
      return false
    }

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool
    {
      if let url = URLContexts.first?.url {
        pendingURI = url
      }
      processURLs()
      return true
    }
  }
#endif

#if os(macOS)
  extension OpenFileHandlerPlugin: FlutterAppLifecycleDelegate {
    public func handleOpen(_ urls: [URL]) -> Bool {
      if let url = urls.first {
        pendingURI = url
      }
      processURLs()
      return true
    }
  }
#endif

private func urlToMap(_ url: URL) -> [String: Any?] {
  [
    "name": url.lastPathComponent,
    "path": url.path,
    "uri": url.absoluteString,
  ]
}
