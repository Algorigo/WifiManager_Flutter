import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_manager_plugin/wifi_manager_plugin.dart';
import 'package:wifi_manager_plugin/wifi_manager_plugin_platform_interface.dart';
import 'package:wifi_manager_plugin/wifi_manager_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWifiManagerPluginPlatform
    with MockPlatformInterfaceMixin
    implements WifiManagerPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Stream<String>> connectWifi(String ssid, String password) {
    // TODO: implement connectWifi
    throw UnimplementedError();
  }

  @override
  Future<String> getConnectedWifiApName() {
    // TODO: implement getConnectedWifiApName
    throw UnimplementedError();
  }

  @override
  Future<bool> internetAvailable() {
    // TODO: implement internetAvailable
    throw UnimplementedError();
  }

  @override
  Future<void> requestPermissions() {
    // TODO: implement requestPermissions
    throw UnimplementedError();
  }

  @override
  Future<List<ScanResult>> scanWifi([bool only2GHz = false]) {
    // TODO: implement scanWifi
    throw UnimplementedError();
  }
}

void main() {
  final WifiManagerPluginPlatform initialPlatform = WifiManagerPluginPlatform.instance;

  test('$MethodChannelWifiManagerPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWifiManagerPlugin>());
  });

  test('getPlatformVersion', () async {
    MockWifiManagerPluginPlatform fakePlatform = MockWifiManagerPluginPlatform();

    expect(await fakePlatform.getPlatformVersion(), '42');
  });
}
