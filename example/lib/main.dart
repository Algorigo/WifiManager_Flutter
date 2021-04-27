import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rxdart/rxdart.dart';
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
  final _newApNameController = TextEditingController();
  String _newApPassword = "";
  StreamSubscription<String> _subscription = null;

  String get _scanTitle {
    return _subscription == null ? "Connect" : "Disconnect";
  }

  String _result = "";
  List<String> _scanResult = [];

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
    if (_subscription == null) {
      Stream<String> stream = await WifiManagerPlugin.connectWifi(
          _newApNameController.text, _newApPassword);
      _subscription = stream.doOnCancel(() {
        setState(() {
          _subscription = null;
        });
      }).listen((event) {
        print("event:$event");

        setState(() {
          _result = "Connected";
        });
      }, onError: (error) {
        print("onError:$error");
      }, onDone: () {
        print("onDone");
      });
      setState(() {});
    } else {
      _subscription?.cancel();
      _result = "Disconnected";
    }
  }

  Future<void> scanWifi() async {
    print("scanWifi");
    var wifiList = await WifiManagerPlugin.scanWifi(false);

    setState(() {
      _scanResult = wifiList;
    });
  }

  Future<void> scanResultSelected(int count) async {
    setState(() {
      _newApNameController.text = _scanResult[count];
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
                controller: _newApNameController,
                decoration: InputDecoration(hintText: 'Ap Name'),
              ),
              TextField(
                  decoration: InputDecoration(hintText: 'Ap Password'),
                  onChanged: (value) {
                    _newApPassword = value;
                  }),
              ElevatedButton(onPressed: connectNewAp, child: Text(_scanTitle)),
              ElevatedButton(onPressed: scanWifi, child: Text("Scan Wifi")),
              Text(_result),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _scanResult.length,
                  itemBuilder: (buildContext, position) {
                    return GestureDetector(
                      onTap: () => scanResultSelected(position),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        width: double.infinity,
                        child: Text(_scanResult[position]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
