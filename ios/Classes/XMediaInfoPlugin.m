#import "XMediaInfoPlugin.h"
#if __has_include(<x_media_info/x_media_info-Swift.h>)
#import <x_media_info/x_media_info-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "x_media_info-Swift.h"
#endif

@implementation XMediaInfoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftXMediaInfoPlugin registerWithRegistrar:registrar];
}
@end
