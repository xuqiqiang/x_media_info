import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'x_media_info_platform_interface.dart';

/// An implementation of [XMediaInfoPlatform] that uses method channels.
class MethodChannelXMediaInfo extends XMediaInfoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('x_media_info');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
