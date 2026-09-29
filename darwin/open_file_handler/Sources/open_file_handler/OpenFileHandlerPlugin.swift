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
  #if os(iOS)
    private static weak var instance: OpenFileHandlerPlugin?
    private static var pendingOpen: (url: URL, openInPlace: Bool, alwaysCopy: Bool)?
    private var pendingOpenInPlace = true
    private var pendingAlwaysCopy = false
  #elseif os(macOS)
    private static weak var instance: OpenFileHandlerPlugin?
    private static var pendingOpen: URL?
  #endif
  private var iosURLsToRelease: [URL] = []
  private var eventSink: FlutterEventSink?

  private func processURLs() -> Bool {
    guard let eventSink = eventSink, let url = pendingURI else { return false }
    pendingURI = nil

    #if os(iOS)
      let openInPlace = pendingOpenInPlace
      pendingOpenInPlace = true
      let alwaysCopy = pendingAlwaysCopy
      pendingAlwaysCopy = false
      let hasSecurityScope = url.startAccessingSecurityScopedResource()
      if !openInPlace || alwaysCopy {
        defer {
          if hasSecurityScope { url.stopAccessingSecurityScopedResource() }
        }
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
          .appendingPathComponent("_app/open_file_handler", isDirectory: true)
        let copy = directory.appendingPathComponent(url.lastPathComponent)
        do {
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
          if FileManager.default.fileExists(atPath: copy.path) {
            try FileManager.default.removeItem(at: copy)
          }
          try FileManager.default.copyItem(at: url, to: copy)
          eventSink(urlToMap(url, path: copy.path, localCopy: true))
        } catch {
          try? FileManager.default.removeItem(at: copy)
          eventSink(
            FlutterError(
              code: "file_copy_failed", message: error.localizedDescription, details: nil))
        }
        return true
      }
      if hasSecurityScope {
        iosURLsToRelease.append(url)
      }
    #endif

    #if os(macOS)
      eventSink(urlToMap(url, localCopy: true))
    #else
      eventSink(urlToMap(url, localCopy: false))
    #endif
    return true
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
      self.instance = instance
      if let pending = pendingOpen {
        instance.pendingURI = pending.url
        instance.pendingOpenInPlace = pending.openInPlace
        instance.pendingAlwaysCopy = pending.alwaysCopy
        pendingOpen = nil
      }
    #elseif os(macOS)
      self.instance = instance
      instance.pendingURI = pendingOpen
      pendingOpen = nil
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
  extension OpenFileHandlerPlugin {
    public static func handleOpenURI(_ context: UIOpenURLContext, alwaysCopy: Bool) {
      guard context.url.isFileURL else { return }
      if let instance = instance {
        instance.pendingURI = context.url
        instance.pendingOpenInPlace = context.options.openInPlace
        instance.pendingAlwaysCopy = alwaysCopy
        _ = instance.processURLs()
      } else {
        pendingOpen = (context.url, context.options.openInPlace, alwaysCopy)
      }
    }
  }
#endif

#if os(macOS)
  extension OpenFileHandlerPlugin {
    public static func handleOpenURI(_ url: URL) {
      guard url.isFileURL else { return }
      if let instance = instance {
        instance.pendingURI = url
        _ = instance.processURLs()
      } else {
        pendingOpen = url
      }
    }
  }
#endif

private func urlToMap(_ url: URL, path: String? = nil, localCopy: Bool) -> [String: Any?] {
  [
    "name": url.lastPathComponent,
    "path": path ?? url.path,
    "uri": url.absoluteString,
    "localCopy": localCopy,
  ]
}
