// Import the correct Flutter module and UI framework for each platform
#if os(iOS)
  import Flutter
  import UIKit
#elseif os(macOS)
  import FlutterMacOS
  import Cocoa
#endif

private struct PendingOpenRequest {
  let url: URL
  #if os(iOS)
    let openInPlace: Bool
    let alwaysCopy: Bool
  #endif
}

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // The latest request received by this instance, waiting for an event sink.
  private var pendingOpenRequest: PendingOpenRequest?
  #if os(iOS)
    private static weak var instance: OpenFileHandlerPlugin?
  #elseif os(macOS)
    private static weak var instance: OpenFileHandlerPlugin?
  #endif
  // Buffers a file-open request until Flutter calls register(with:) for this plugin.
  private static var pendingOpenBeforeRegistration: PendingOpenRequest?
  private var iosURLsToRelease: [URL] = []
  private var eventSink: FlutterEventSink?

  private func processURL() -> Bool {
    guard let eventSink = eventSink, let request = pendingOpenRequest else { return false }
    pendingOpenRequest = nil
    let url = request.url

    #if os(iOS)
      let openInPlace = request.openInPlace
      let alwaysCopy = request.alwaysCopy
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
          return false
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
    #elseif os(macOS)
      self.instance = instance
    #endif
    instance.pendingOpenRequest = pendingOpenBeforeRegistration
    pendingOpenBeforeRegistration = nil
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
    processURL()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

#if os(iOS)
  extension OpenFileHandlerPlugin {
    @discardableResult
    public static func handleOpenURI(_ context: UIOpenURLContext, alwaysCopy: Bool) -> Bool {
      guard context.url.isFileURL else { return false }
      if let instance = instance {
        instance.pendingOpenRequest = PendingOpenRequest(
          url: context.url,
          openInPlace: context.options.openInPlace,
          alwaysCopy: alwaysCopy)
        _ = instance.processURL()
      } else {
        pendingOpenBeforeRegistration = PendingOpenRequest(
          url: context.url,
          openInPlace: context.options.openInPlace,
          alwaysCopy: alwaysCopy)
      }
      return true
    }
  }
#endif

#if os(macOS)
  extension OpenFileHandlerPlugin {
    @discardableResult
    public static func handleOpenURI(_ url: URL) -> Bool {
      guard url.isFileURL else { return false }
      if let instance = instance {
        instance.pendingOpenRequest = PendingOpenRequest(url: url)
        _ = instance.processURL()
      } else {
        pendingOpenBeforeRegistration = PendingOpenRequest(url: url)
      }
      return true
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
