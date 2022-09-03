import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_media_info/x_media_info_method_channel.dart';

void main() {
  MethodChannelXMediaInfo platform = MethodChannelXMediaInfo();
  const MethodChannel channel = MethodChannel('x_media_info');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
