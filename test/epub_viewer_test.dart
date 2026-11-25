import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('vocsy_epub_viewer');
  const MethodChannel pageChannel = MethodChannel('page');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pageChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pageChannel, null);
  });

  test('locatorStream is one shared broadcast stream', () {
    expect(identical(VocsyEpub.locatorStream, VocsyEpub.locatorStream), isTrue);
  });

  test('listeners share a single page listen and cancel once', () async {
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pageChannel, (MethodCall methodCall) async {
      methods.add(methodCall.method);
      return null;
    });

    final first = VocsyEpub.locatorStream.listen((_) {});
    final second = VocsyEpub.locatorStream.listen((_) {});
    await pumpEventQueue();

    expect(methods, ['listen']);

    await first.cancel();
    await pumpEventQueue();
    expect(methods, ['listen']);

    await second.cancel();
    await pumpEventQueue();
    expect(methods, ['listen', 'cancel']);
  });
}
