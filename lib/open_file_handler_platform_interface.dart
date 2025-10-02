import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'open_file_handler_method_channel.dart';

class OpenFileHandlerFile {
  final String? name;
  final String? path;
  final String uri;

  OpenFileHandlerFile({
    required this.name,
    required this.path,
    required this.uri,
  });

  @override
  String toString() {
    return 'OpenFileHandlerFile{name: $name, path: $path, uri: $uri}';
  }
}

abstract class OpenFileHandlerPlatform extends PlatformInterface {
  /// Constructs a OpenFileHandlerPlatform.
  OpenFileHandlerPlatform() : super(token: _token);

  static final Object _token = Object();

  static OpenFileHandlerPlatform _instance = MethodChannelOpenFileHandler();

  /// The default instance of [OpenFileHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelOpenFileHandler].
  static OpenFileHandlerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OpenFileHandlerPlatform] when
  /// they register themselves.
  static set instance(OpenFileHandlerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  StreamSubscription<dynamic> listen(
    Function(List<OpenFileHandlerFile> files) onEvent, {
    Function? onError,
  }) {
    throw UnimplementedError('listen() has not been implemented.');
  }
}
