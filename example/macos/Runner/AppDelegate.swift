import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func application(_ application: NSApplication, open urls: [URL]) {
    NotificationCenter.default.post(name: NSNotification.Name("open_file_handler/events"), object: nil, userInfo: ["urls": urls])
  }
}
