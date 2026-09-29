import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_file_handler/open_file_handler.dart';
import 'package:open_file_handler/open_file_handler_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('listen emits one file from a native map event', () async {
    const channel = 'open_file_handler/hot_uris';
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel(channel),
      (call) async => null,
    );

    final received = <OpenFileHandlerFile>[];
    final subscription = OpenFileHandler().listen(received.add);
    addTearDown(() async {
      await subscription.cancel();
      messenger.setMockMethodCallHandler(const MethodChannel(channel), null);
    });

    messenger.handlePlatformMessage(
      channel,
      codec.encodeSuccessEnvelope({
        'name': 'report.txt',
        'path': '/tmp/report.txt',
        'uri': 'file:///Documents/report.txt',
        'localCopy': true,
      }),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.name, 'report.txt');
    expect(received.single.uri, 'file:///Documents/report.txt');
    expect(received.single.path, '/tmp/report.txt');
    expect(received.single.localCopy, isTrue);
  });
}
