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
    if let first = urls.first {
      let map = [
        "name": first.lastPathComponent,
        "path": first.path,
        "uri": first.absoluteString,
      ]
      
      NotificationCenter.default.post(name: NSNotification.Name("open_file_handler/events"), object: nil, userInfo: map)
    }
  }
}
