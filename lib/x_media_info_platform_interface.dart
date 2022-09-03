import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'x_media_info_method_channel.dart';

abstract class XMediaInfoPlatform extends PlatformInterface {
  /// Constructs a XMediaInfoPlatform.
  XMediaInfoPlatform() : super(token: _token);

  static final Object _token = Object();

  static XMediaInfoPlatform _instance = MethodChannelXMediaInfo();

  /// The default instance of [XMediaInfoPlatform] to use.
  ///
  /// Defaults to [MethodChannelXMediaInfo].
  static XMediaInfoPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [XMediaInfoPlatform] when
  /// they register themselves.
  static set instance(XMediaInfoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
