import Flutter
import UIKit
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import NetworkExtension
import RxSwift

enum WifiManagerError : Error {
    case notSupportedOsVersion(version: String)
    case wifiNotConnected
}

public class SwiftWifiManagerPlugin: NSObject {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "wifi_manager_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftWifiManagerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    let connectWifiEventChannel = FlutterEventChannel(name: "wifi_manager_connect_wifi", binaryMessenger: registrar.messenger())
    connectWifiEventChannel.setStreamHandler(instance)
  }

  private var observableDic = [Int: Observable<String>]()
  private var disposableDic = [Int: Disposable]()
}

extension SwiftWifiManagerPlugin: FlutterPlugin {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
    case "getConnectedWifiApName":
        if let ssid = SwiftWifiManagerPlugin.getConnectedWifiApName() {
          result(ssid)
        } else {
          result(FlutterError(code: "Unsupported", message: nil, details: nil))
        }
    case "connectWifi":
        if let arguments = call.arguments as? [String: Any],
           let ssid = arguments["ssid"] as? String,
           let password = arguments["password"] as? String {
            let id = Int.random(in: Int.min...Int.max)
            let observable: Observable<String>
            if #available(iOS 11.0, *) {
                observable = Observable<String>.create { (emitter) in
                    let configuation = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
                    configuation.joinOnce = true
                    NEHotspotConfigurationManager.shared.apply(configuation) { (error) in
                        if let error = error {
                            print("connect error:\(error)")
                            emitter.onError(error)
                        } else {
                            let connectedWifi = SwiftWifiManagerPlugin.getConnectedWifiApName()
                            if (ssid == connectedWifi) {
                                emitter.onNext("Connected")
                            } else {
                                emitter.onError(WifiManagerError.wifiNotConnected)
                            }
                        }
                    }
                    return Disposables.create()
                }.do(onDispose: {
                    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
//                     NEHotspotConfigurationManager.shared.getConfiguredSSIDs { list in
//                         print("list:\(list)")
//                     }
                })
            } else {
                // Fallback on earlier versions
                observable = Observable.error(WifiManagerError.notSupportedOsVersion(version: ProcessInfo().operatingSystemVersionString))
            }
            observableDic[id] = observable
            result(id)
        } else {
            result(FlutterError(code: "IllegalArgument", message: nil, details: nil))
        }
    case "scanWifi":
        result(FlutterError(code: "Unsupported", message: nil, details: nil))
    default:
        result(FlutterMethodNotImplemented)
    }
  }

  fileprivate static func getConnectedWifiApName() -> String? {
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
      for interface in interfaces {
        if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
          let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
          return ssid
        }
      }
    }
    return nil
  }
}

extension SwiftWifiManagerPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let id = arguments as? Int,
           observableDic.keys.contains(id) {
            disposableDic[id] = observableDic.removeValue(forKey: id)?
                .subscribe({ (event) in
                    switch event {
                    case .next(let value):
                        events(value)
                    case .error(let error):
                        events(FlutterError(code: String(describing: error), message: error.localizedDescription, details: nil))
                    default:
                        break
                    }
                })
            return nil
        } else {
            return FlutterError(code: "IllegalArgument", message: nil, details: nil)
        }
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let id = arguments as? Int {
            disposableDic.removeValue(forKey: id)?.dispose()
            return nil
        } else {
            return FlutterError(code: "IllegalArgument", message: nil, details: nil)
        }
    }
}
