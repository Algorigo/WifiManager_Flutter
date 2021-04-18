import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiManagerPlugin {
  static const MethodChannel _channel =
      const MethodChannel('wifi_manager_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> requestPermissions() async {
    if (await Permission.locationWhenInUse.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      return;
    }

    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
    ].request();
    print(statuses[Permission.locationWhenInUse]);
  }

  static Future<String> getConnectedWifiApName() async {
    final String apName = await _channel.invokeMethod('getConnectedWifiApName');
    return apName;
  }

  static Future<void> connectWifi(String apName, String apPassword) async {
    await _channel.invokeMapMethod('connectWifi', {"apName": apName, "apPassword": apPassword});
  }
}
