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

public class WifiManagerPlugin: NSObject {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wifi_manager_plugin", binaryMessenger: registrar.messenger())
        let instance = WifiManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let connectWifiEventChannel = FlutterEventChannel(name: "wifi_manager_connect_wifi", binaryMessenger: registrar.messenger())
        connectWifiEventChannel.setStreamHandler(instance)
    }

    private var observableDic: [Int: Observable<String>] = [:]
    private var disposableDic: [Int: Disposable] = [:]
}

extension WifiManagerPlugin: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "getConnectedWifiApName":
            WifiManagerPlugin.getConnectedWifiApName()
                .subscribe { event in
                    if case .success(let ssid) = event {
                        result(ssid)
                    } else {
                        result(FlutterError(code: "Unsupported", message: nil, details: nil))
                    }
                }
        case "connectWifi":
            if let arguments = call.arguments as? [String: Any],
               let ssid = arguments["ssid"] as? String,
               let password = arguments["password"] as? String {
                let id = Int.random(in: Int.min...Int.max)
                let observable: Observable<String>
                if #available(iOS 11.0, *) {
                    observable = WifiManagerPlugin.connectWifi(ssid: ssid, password: password)
                        .andThen(WifiManagerPlugin.getConnectedWifiApName())
                        .map({ connectedWifi in
                            if ssid != connectedWifi {
                                throw WifiManagerError.wifiNotConnected
                            }
                            return "Connected"
                        })
                        .asObservable()
                        .concat(PublishSubject<String>())
                        .do(onDispose: {
                            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
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
    
    fileprivate static func connectWifi(ssid: String, password: String) -> Completable {
        if #available(iOS 11.0, *) {
            return Completable.deferred {//polyworks1
                let subject = PublishSubject<Any>()
                let configuation = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
                NEHotspotConfigurationManager.shared.apply(configuation) { (error) in
                    if let error = error {
                        print("connect error:\(error)")
                        subject.onError(error)
                    } else {
                        subject.onCompleted()
                    }
                }
                return subject.ignoreElements()
                    .asCompletable()
            }
        } else {
            return Completable.error(WifiManagerError.notSupportedOsVersion(version: ProcessInfo().operatingSystemVersionString))
        }
    }

    fileprivate static func getConnectedWifiApName() -> Single<String?> {
        if #available(iOS 14.0, *) {
            return Single.deferred {
                let subject = ReplaySubject<String?>.create(bufferSize: 1)
                NEHotspotNetwork.fetchCurrent { network in
                    if let ssid = network?.ssid, !ssid.isEmpty {
                        subject.onNext(ssid)
                    } else {
                        subject.onNext(nil)
                    }
                }
                return subject.first().map { $0.flatMap { $0 } }
            }
        } else {
            if let interfaces = CNCopySupportedInterfaces() as NSArray? {
                for interface in interfaces {
                    if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                        let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                        return Single.just(ssid)
                    }
                }
            }
            return Single.just(nil)
        }
    }
}

extension WifiManagerPlugin: FlutterStreamHandler {
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
