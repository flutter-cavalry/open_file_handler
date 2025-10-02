import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let map = [
      "name": url.lastPathComponent,
      "path": url.path,
      "uri": url.absoluteString,
    ]
    
    NotificationCenter.default.post(name: NSNotification.Name("open_file_handler/hot_uris"), object: nil, userInfo: map)
    return true
  }
}
