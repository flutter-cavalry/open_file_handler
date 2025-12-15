import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static var _instance: OpenFileHandlerPlugin?
  private static var _coldOpenURIs: [URL] = []
  private static var _coldOriginal = false
  private static var _coldAccessing = false;
  // On iOS, URLs have security scope, so we need to keep them before releasing.
  private static var _iosPendingOpenURI: URL?
  
  private var _eventSink: FlutterEventSink?
  
  public static func handleOpenURIs(_ urls: [URL], original: Bool = true) {
#if os(iOS)
    if let firstURI = urls.first {
      _coldAccessing = firstURI.startAccessingSecurityScopedResource()
      _iosPendingOpenURI = firstURI
    }
#endif // os(iOS)
    _coldOriginal = original
    if let eventSink = _instance?._eventSink {
      let uriMaps = urls.map { urlToMap($0, original: original) }
      eventSink(uriMaps)
    } else {
      _coldOpenURIs.append(contentsOf: urls)
    }
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    if OpenFileHandlerPlugin._instance == nil {
#if os(iOS)
      let binaryMessenger = registrar.messenger()
#elseif os(macOS)
      let binaryMessenger = registrar.messenger
#endif
      let channel = FlutterMethodChannel(name: "open_file_handler", binaryMessenger: binaryMessenger)
      let instance = OpenFileHandlerPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
      let eventChannel = FlutterEventChannel(
        name: "open_file_handler/hot_uris", binaryMessenger: binaryMessenger)
      eventChannel.setStreamHandler(instance)
      
      OpenFileHandlerPlugin._instance = instance
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "releaseIosURIs":
      OpenFileHandlerPlugin._iosPendingOpenURI?.stopAccessingSecurityScopedResource()
      OpenFileHandlerPlugin._iosPendingOpenURI = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
  -> FlutterError?
  {
    _eventSink = events
    // Do it after return.
    if !OpenFileHandlerPlugin._coldOpenURIs.isEmpty {
      DispatchQueue.main.async {
        let uriMaps = OpenFileHandlerPlugin._coldOpenURIs.map { urlToMap($0, original: OpenFileHandlerPlugin._coldOriginal) }
        events(uriMaps)
        OpenFileHandlerPlugin._coldOpenURIs.removeAll()
      }
    }
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    _eventSink = nil
    return nil
  }
}

func urlToMap(_ url: URL, original: Bool) -> [String: Any?] {
  return [
    "name": url.lastPathComponent,
    "path": url.path,
    "uri": url.absoluteString,
    "original": original
  ]
}
