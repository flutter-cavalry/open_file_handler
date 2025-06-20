import 'dart:async';

import 'open_file_handler_platform_interface.dart';

class OpenFileHandler {
  StreamSubscription<dynamic> listen(
    Function(OpenFileHandlerFile file) onEvent, {
    Function? onError,
  }) {
    return OpenFileHandlerPlatform.instance.listen(onEvent, onError: onError);
  }
}
