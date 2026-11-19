# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`wifi_manager_plugin` is Algorigo's Flutter plugin for Wi-Fi tasks that need native code. It requests location permission, reads the SSID of the connected network, scans for networks (Android only), and joins a network as a long-lived stream. Android does this through `RxWifiManager` from Algorigo's `algorigoutil` library; iOS uses `NEHotspotConfiguration`. It also has a Dart-only internet check. The pubspec registers Android, iOS, Linux, macOS and Windows, but the three desktop platforms are Flutter templates that only answer `getPlatformVersion`. Consumers add it as a git dependency pinned to a tag (`url: https://github.com/Algorigo/WifiManager_Flutter.git`, `ref: 2.4.0`). Its in-house consumer is `algo_platform_library` (smart-chair provisioning and access-point detection). The `example/` uses `path: ../`. README.md and CHANGELOG.md are Flutter templates.

## Commands

```bash
flutter pub get
flutter analyze                     # no analysis_options.yaml at the root (only example/ has one)
flutter test                        # mock-platform + mocked-MethodChannel getPlatformVersion tests
flutter test test/wifi_manager_plugin_method_channel_test.dart
cd example && flutter run           # buttons for permission, connected AP, scan, connect, internet check
cd example/android && ./gradlew testDebugUnitTest   # Kotlin template test (per its header comment; build the example once first)
```

Only `getPlatformVersion` has automated tests. Everything else has to be checked on a device with the example. `linux/test` and `windows/test` hold template gtest files.

## Architecture

The Dart layering follows `plugin_platform_interface`: the static `WifiManagerPlugin` facade → `WifiManagerPluginPlatform.instance` → `MethodChannelWifiManagerPlugin`. That class talks to MethodChannel `wifi_manager_plugin` and EventChannel `wifi_manager_connect_wifi`. The channel names are hardcoded in Dart, Kotlin (`companion object`) and Swift (`register`).

| Dart API | transport | Android | iOS |
|---|---|---|---|
| `requestPermissions()` | none; Dart `permission_handler` `locationWhenInUse`, throws `PermissionException` | | |
| `getConnectedWifiApName()` | method `getConnectedWifiApName` | `WifiManager.connectionInfo.ssid` with the surrounding quotes cut off (without permission this yields `unknown ssid`) | iOS 14+ `NEHotspotNetwork.fetchCurrent`, else `CNCopyCurrentNetworkInfo` |
| `scanWifi([only2GHz])` | method `scanWifi(bool)` → `[{ssid, signalLevel}]` | `RxWifiManager.scan`, 10 s timeout, `signalLevel` bucketed 0–3 | always `FlutterError("Unsupported")` |
| `connectWifi(ssid, pw)` | method `connectWifi({ssid,password})` → int id, then EventChannel listen with that id | `RxWifiManager.connectWifi` state `name`s; 20 s timeout below API 29 | apply `NEHotspotConfiguration`, verify the SSID, emit `"Connected"` |
| `internetAvailable()` | none; Dart `InternetAddress.lookup('google.com')` | | |

### connectWifi protocol and behaviour

- **Two steps.** The method call builds the native Rx observable, stores it under a random 64-bit id and returns that id. The Dart `_Observable` then listens on the shared EventChannel with the id as the `receiveBroadcastStream` argument. Native `onListen` subscribes the stored observable, and `onCancel` disposes it. A stream that is never listened to leaves its observable in the native map.
- **Cancelling disconnects on iOS.** The iOS stream never completes (it is concatenated with an empty `PublishSubject`). Disposing it calls `NEHotspotConfigurationManager.removeConfiguration(forSSID:)`, which drops the network. Callers must stay subscribed for as long as they need the connection. `algo_platform_library` stays subscribed while it runs its TCP provisioning against the chair, then cancels with `.first`.
- **Event values differ by platform:** iOS emits `"Connected"`, Android emits `RxWifiManager` state names.
- **Android below API 29:** the timeout's `doOnError` calls `result.error(...)` on a MethodChannel result that already replied with `success(id)`.

### Other gotchas

- **Android needs an Activity.** The plugin's `context` is a `lateinit` set in `onAttachedToActivity`, so any call before an Activity attaches (e.g. from a background engine) crashes.
- **Global RxJava error handler.** Android's `onAttachedToEngine` installs `RxJavaPlugins.setErrorHandler`, which logs `UndeliverableException` and swallows every other error. This applies to all RxJava code in the host app, including `algo_platform_jsag`'s native side.
- **iOS null SSID.** When iOS is not on Wi-Fi it returns `nil` for the SSID, and Dart's `final String apName = await …` then throws a type error instead of a clean exception.

## Native dependencies

- **Android:** `com.algorigo.library:algorigoutil:1.5.0` (provides `com.algorigo.library.rx.RxWifiManager`), RxJava 3.1.12 and RxAndroid 3. Only `google()` and `mavenCentral()` are declared. The manifest adds `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`. compileSdk 37, minSdk 24, AGP 9.0.1, Kotlin 2.3.20.
- **iOS:**
  - `ios/wifi_manager_plugin/Package.swift` is the live build (SPM, iOS 13.0, RxSwift + RxCocoa ≥ 6.10.2). The example uses SPM with no Podfile.
  - `ios/wifi_manager_plugin.podspec` is stale (version 2.2.0, iOS 9.0, RxSwift ~> 6.9.0) and its `source_files = 'Classes/**/*'` matches nothing, so a CocoaPods build compiles no Swift.
- **macOS:** has a valid Package.swift and podspec, but only implements `getPlatformVersion`.
- **Host app on iOS:**
  - Entitlements `com.apple.developer.networking.HotspotConfiguration` and `com.apple.developer.networking.wifi-info` (see `example/ios/Runner/Runner.entitlements`), plus `NSLocationWhenInUseUsageDescription`.
  - `permission_handler` compiles its location handler only when the host app enables `PERMISSION_LOCATION` (see permission_handler's iOS setup). The podspec's `-DPERMISSION_LOCATION=1` applies only to this pod, and the example's Xcode project at HEAD does not define it.

## Conventions

- Git-flow: `release/x.y.z` bumps `version:` in pubspec.yaml, merges to `master` (tag `x.y.z`) and back to `develop`. Several releases were merged as GitHub pull requests from a fork. Commit messages are mostly Korean.
- `algo_platform_library` pins this plugin by tag (`ref: 2.4.0`). Adding or changing an API means editing the Dart platform interface, the method-channel class, Kotlin and Swift together, then bumping library's ref.
