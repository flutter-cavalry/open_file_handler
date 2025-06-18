import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'open_file_handler_platform_interface.dart';

/// An implementation of [OpenFileHandlerPlatform] that uses method channels.
class MethodChannelOpenFileHandler extends OpenFileHandlerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('open_file_handler');
  final eventChannel = const EventChannel('open_file_handler/events');

  @override
  StreamSubscription<dynamic> listen(
    Function(List<OpenFileHandlerFile> files) onEvent, {
    Function? onError,
  }) {
    final stream = eventChannel.receiveBroadcastStream();
    return stream.listen((event) {
      final mapList =
          (event as Map<dynamic, dynamic>)['files'] as List<dynamic>;
      final List<OpenFileHandlerFile> files = mapList.map((map) {
        return OpenFileHandlerFile(
          name: map['name'] as String,
          uri: map['uri'] as String,
          path: map['path'] as String,
        );
      }).toList();
      onEvent(files);
    }, onError: (error) => onError?.call(error));
  }
}
