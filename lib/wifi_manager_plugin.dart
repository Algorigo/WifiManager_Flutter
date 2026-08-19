import 'dart:async';

import 'wifi_manager_plugin_platform_interface.dart';

class ScanResult {
  String ssid;
  int signalLevel;

  ScanResult(this.ssid, this.signalLevel);
}

class WifiManagerPlugin {
  static Future<String?> getPlatformVersion() {
    return WifiManagerPluginPlatform.instance.getPlatformVersion();
  }

  static Future<void> requestPermissions() async {
    return WifiManagerPluginPlatform.instance.requestPermissions();
  }

  static Future<String> getConnectedWifiApName() async {
    return WifiManagerPluginPlatform.instance.getConnectedWifiApName();
  }

  static Future<List<ScanResult>> scanWifi([bool only2GHz = false]) async {
    return WifiManagerPluginPlatform.instance.scanWifi(only2GHz);
  }

  static Future<Stream<String>> connectWifi(
      String ssid, String password) async {
    return WifiManagerPluginPlatform.instance.connectWifi(ssid, password);
  }

  static Future<bool> internetAvailable() async {
    return WifiManagerPluginPlatform.instance.internetAvailable();
  }
}
