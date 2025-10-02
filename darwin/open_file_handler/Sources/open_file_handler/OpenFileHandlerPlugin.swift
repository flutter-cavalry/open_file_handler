import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let binaryMessenger = registrar.messenger()
    #elseif os(macOS)
      let binaryMessenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(name: "open_file_handler", binaryMessenger: binaryMessenger)
    let instance = OpenFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "open_file_handler/events", binaryMessenger: binaryMessenger)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
  -> FlutterError?
  {
    NotificationCenter.default.addObserver(forName: NSNotification.Name("open_file_handler/events"), object: nil, queue: nil) { noti in
      guard let userInfo = noti.userInfo,
            let urls = userInfo["urls"] as? [URL] else {
        return
      }
      let files = urls.map {
        return [
          "name": $0.lastPathComponent,
          "path": $0.path,
          "uri": $0.absoluteString,
        ]
      }
      events([
        "files": files,
      ])
    }
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("open_file_handler/events"), object: nil)
    return nil
  }
}
