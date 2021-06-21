import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class PermissionException implements Exception {
  PermissionStatus status;

  PermissionException(this.status);

  @override
  String toString() {
    switch (status) {
      case PermissionStatus.denied:
        return "permission denied";
      case PermissionStatus.limited:
        return "permission limited";
      case PermissionStatus.permanentlyDenied:
        return "permission permanentlyDenied";
      case PermissionStatus.restricted:
        return "permission restricted";
      default:
        return super.toString();
    }
  }
}

class WifiManagerPlugin {
  static const MethodChannel _channel =
      const MethodChannel('wifi_manager_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> requestPermissions() async {
    if (await Permission.locationWhenInUse.isGranted) {
      // Either the permission was already granted before or the user just granted it.
      return;
    }

    // You can request multiple permissions at once.
    PermissionStatus status = await Permission.locationWhenInUse.request();
    if (status != PermissionStatus.granted) {
      throw PermissionException(status);
    }
  }

  static Future<String> getConnectedWifiApName() async {
    final String apName = await _channel.invokeMethod('getConnectedWifiApName');
    return apName;
  }

  static Future<List<String>> scanWifi([bool only2GHz = false]) async {
    return _channel.invokeMethod('scanWifi', only2GHz).then((value) {
      var list = value as List<dynamic>;
      return list.map((e) => e as String).toList();
    });
  }

  static Future<Stream<String>> connectWifi(
      String ssid, String password) async {
    var id = await _channel
        .invokeMethod('connectWifi', {'ssid': ssid, 'password': password});
    return _Observable(id as int);
  }

  static Future<bool> internetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (e) {
      print('not connected:$e');
    }
    return false;
  }
}

class _Observable<T> extends Stream<T> {
  static const EventChannel _eventChannel =
      const EventChannel('wifi_manager_connect_wifi');

  _Observable(this._id);

  int _id;

  @override
  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _eventChannel
        .receiveBroadcastStream(_id)
        .map((event) => event as T)
        .listen((event) => onData?.call(event),
            onError: (error) => onError?.call(error),
            onDone: () => onDone?.call(),
            cancelOnError: true);
  }
}
