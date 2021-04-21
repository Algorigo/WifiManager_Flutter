package com.algorigo.library.wifi_manager_plugin

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import androidx.annotation.NonNull
import com.algorigo.library.rx.RxWifiManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** WifiManagerPlugin */
class WifiManagerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "getConnectedWifiApName" -> getConnectedWifiApName(result)
      "connectWifi" -> connectWifi(call, result)
      "scanWifi" -> scanWifi(call, result)
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

  private fun connectWifi(call: MethodCall, result: Result) {
    val apName = call.argument<String>("apName")
    val apPassword = call.argument<String>("apPassword")
    if (apName != null && apPassword != null) {
      RxWifiManager.connect(context, apName, apPassword)
              .subscribe({
                result.success(null)
              }, {
                result.error(it.javaClass.simpleName, it.message, it.stackTraceToString())
              })
    } else {
      result.error(IllegalArgumentException::class.java.simpleName, null, null)
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

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
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
  }
}
