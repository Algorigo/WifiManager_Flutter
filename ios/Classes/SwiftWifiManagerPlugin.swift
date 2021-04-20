import Flutter
import UIKit
import CoreLocation
import SystemConfiguration.CaptiveNetwork

public class SwiftWifiManagerPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "wifi_manager_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftWifiManagerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
    case "getConnectedWifiApName":
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    result(ssid)
                    return
                }
            }
        }
        result(FlutterError(code: "Unsupported", message: nil, details: nil))
    case "connectWifi":
        result(FlutterError(code: "Unsupported", message: nil, details: nil))
    case "scanWifi":
        result(FlutterError(code: "Unsupported", message: nil, details: nil))
    default:
        result(FlutterMethodNotImplemented)
    }
  }
}
