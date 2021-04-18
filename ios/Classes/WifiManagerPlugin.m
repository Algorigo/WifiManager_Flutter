#import "WifiManagerPlugin.h"
#if __has_include(<wifi_manager_plugin/wifi_manager_plugin-Swift.h>)
#import <wifi_manager_plugin/wifi_manager_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "wifi_manager_plugin-Swift.h"
#endif

@implementation WifiManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWifiManagerPlugin registerWithRegistrar:registrar];
}
@end
