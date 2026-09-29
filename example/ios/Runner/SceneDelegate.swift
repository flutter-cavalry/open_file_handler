import Flutter
import UIKit
import open_file_handler

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let context = connectionOptions.urlContexts.first {
      OpenFileHandlerPlugin.handleOpenURI(context, alwaysCopy: true)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    if let context = URLContexts.first {
      OpenFileHandlerPlugin.handleOpenURI(context, alwaysCopy: true)
    }
  }
}
