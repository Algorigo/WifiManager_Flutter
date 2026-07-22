import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wifi_manager_plugin.dart';
import 'wifi_manager_plugin_method_channel.dart';

abstract class WifiManagerPluginPlatform extends PlatformInterface {
  /// Constructs a WifiManagerPluginPlatform.
  WifiManagerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static WifiManagerPluginPlatform _instance = MethodChannelWifiManagerPlugin();

  /// The default instance of [WifiManagerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelWifiManagerPlugin].
  static WifiManagerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WifiManagerPluginPlatform] when
  /// they register themselves.
  static set instance(WifiManagerPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<String> getConnectedWifiApName() {
    throw UnimplementedError('getConnectedWifiApName() has not been implemented.');
  }

  Future<List<ScanResult>> scanWifi([bool only2GHz = false]) {
    throw UnimplementedError('scanWifi() has not been implemented.');
  }

  Future<Stream<String>> connectWifi(String ssid, String password) {
    throw UnimplementedError('connectWifi() has not been implemented.');
  }

  Future<bool> internetAvailable() {
    throw UnimplementedError('internetAvailable() has not been implemented.');
  }
}
