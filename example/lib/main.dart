import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:wifi_manager_plugin/wifi_manager_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _apName = "";
  String _newApName = "";
  String _newApPassword = "";
  String _scanResult = "";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await WifiManagerPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    await getApName();
  }

  Future<void> getApName() async {
    String apName = "";
    try {
      await WifiManagerPlugin.requestPermissions();
      apName = await WifiManagerPlugin.getConnectedWifiApName();
    } catch (e) {
      print("getConnectedWifiApName error:$e");
    }

    setState(() {
      _apName = apName;
    });
  }

  Future<void> connectNewAp() async {
    print("connectNewAp");
    await WifiManagerPlugin.connectWifi(_newApName, _newApPassword);

    await getApName();
  }

  Future<void> scanWifi() async {
    print("scanWifi");
    var wifiList = await WifiManagerPlugin.scanWifi(false);

    setState(() {
      _scanResult = wifiList.join("\n");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(onPressed: getApName, child: Text("Get Ap Info")),
              Text('ApName on: $_apName'),
              TextField(
                  decoration: InputDecoration(hintText: 'Ap Name'),
                  onChanged: (value) {
                    _newApName = value;
                  }),
              TextField(
                  decoration: InputDecoration(hintText: 'Ap Password'),
                  onChanged: (value) {
                    _newApPassword = value;
                  }),
              ElevatedButton(onPressed: connectNewAp, child: Text("Conntect")),
              ElevatedButton(onPressed: scanWifi, child: Text("Scan Wifi")),
              Expanded(child: Text(_scanResult)),
            ],
          ),
        ),
      ),
    );
  }
}
