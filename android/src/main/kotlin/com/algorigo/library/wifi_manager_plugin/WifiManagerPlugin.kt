package com.algorigo.library.wifi_manager_plugin

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import androidx.annotation.NonNull
import com.algorigo.library.rx.RxWifiManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.core.Observable
import io.reactivex.rxjava3.disposables.Disposable

/** WifiManagerPlugin */
class WifiManagerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var connectWifiEventChannel: EventChannel
  private val observableMap = mutableMapOf<Long, Observable<String>>()
  private val disposableMap = mutableMapOf<Long, Disposable>()
  private lateinit var context : Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
    channel.setMethodCallHandler(this)

    connectWifiEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, CONNECT_WIFI_EVENT_CHANNEL_NAME)
    connectWifiEventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "getConnectedWifiApName" -> getConnectedWifiApName(result)
      "scanWifi" -> scanWifi(call, result)
      "connectWifi" -> connectWifi(call, result)
      else -> result.notImplemented()
    }
  }

  private fun getConnectedWifiApName(result: Result) {
    val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    val ssid = wifiManager?.connectionInfo?.ssid
    if (ssid != null) {
      result.success(ssid)
    } else {
      result.error(UnsupportedOperationException::class.java.simpleName, null, null)
    }
  }

  private fun scanWifi(call: MethodCall, result: Result) {
    val only24GHz = call.arguments as? Boolean
    RxWifiManager.scan(context, only24GHz ?: false)
            .map {
              it.map { it.SSID }
            }
            .subscribe({
              result.success(it);
            }, {
              result.error(it.javaClass.simpleName, it.message, it.stackTraceToString())
            })
  }

  private fun connectWifi(call: MethodCall, result: Result) {
    val ssid = call.argument<String>("ssid")
    val password = call.argument<String>("password")
    if (ssid != null && password != null) {
      val id = (Math.random() * Long.MAX_VALUE).toLong()
      val observable = RxWifiManager.connectWifi(context, ssid, password).map { it.name }
      observableMap[id] = observable
      result.success(id)
    } else {
      result.error(IllegalArgumentException::class.java.simpleName, null, null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    val id = arguments as? Long
    if (id != null && observableMap.containsKey(id)) {
      disposableMap[id] = observableMap.remove(id)!!
              .doFinally {
                disposableMap[id]?.dispose()
              }
              .observeOn(AndroidSchedulers.mainThread())
              .subscribe({
                events?.success(it)
              }, {
                events?.error(it.javaClass.simpleName, it.message, it.stackTraceToString())
              }, {
                events?.endOfStream()
              })
    } else {
      events?.error(IllegalArgumentException::class.java.simpleName, null, null)
    }
  }

  override fun onCancel(arguments: Any?) {
    val id = arguments as? Long
    disposableMap.remove(id)?.dispose()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    context = binding.activity.applicationContext
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.i(LOG_TAG, "onDetachedFromActivityForConfigChanges")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    Log.i(LOG_TAG, "onReattachedToActivityForConfigChanges:${binding.activity}")
  }

  override fun onDetachedFromActivity() {
    Log.i(LOG_TAG, "onDetachedFromActivity")
  }

  companion object {

    private val LOG_TAG = WifiManagerPlugin::class.java.simpleName
    private const val METHOD_CHANNEL_NAME = "wifi_manager_plugin"
    private const val CONNECT_WIFI_EVENT_CHANNEL_NAME = "wifi_manager_connect_wifi"
  }
}
