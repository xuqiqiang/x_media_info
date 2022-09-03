import 'package:flutter_test/flutter_test.dart';
import 'package:x_media_info/x_media_info.dart';
import 'package:x_media_info/x_media_info_platform_interface.dart';
import 'package:x_media_info/x_media_info_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockXMediaInfoPlatform 
    with MockPlatformInterfaceMixin
    implements XMediaInfoPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final XMediaInfoPlatform initialPlatform = XMediaInfoPlatform.instance;

  test('$MethodChannelXMediaInfo is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelXMediaInfo>());
  });

  test('getPlatformVersion', () async {
    XMediaInfo xMediaInfoPlugin = XMediaInfo();
    MockXMediaInfoPlatform fakePlatform = MockXMediaInfoPlatform();
    XMediaInfoPlatform.instance = fakePlatform;
  
    expect(await xMediaInfoPlugin.getPlatformVersion(), '42');
  });
}
