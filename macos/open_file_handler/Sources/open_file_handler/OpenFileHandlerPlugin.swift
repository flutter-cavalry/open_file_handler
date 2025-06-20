import Cocoa
import FlutterMacOS

public class OpenFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "open_file_handler", binaryMessenger: registrar.messenger)
    let instance = OpenFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: "open_file_handler/events", binaryMessenger: registrar.messenger)
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
      guard let userInfo = noti.userInfo else {
        return
      }
      events(userInfo)
    }
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("open_file_handler/events"), object: nil)
    return nil
  }
}
