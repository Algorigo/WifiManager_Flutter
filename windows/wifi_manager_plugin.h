#ifndef FLUTTER_PLUGIN_WIFI_MANAGER_PLUGIN_H_
#define FLUTTER_PLUGIN_WIFI_MANAGER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace wifi_manager_plugin {

class WifiManagerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WifiManagerPlugin();

  virtual ~WifiManagerPlugin();

  // Disallow copy and assign.
  WifiManagerPlugin(const WifiManagerPlugin&) = delete;
  WifiManagerPlugin& operator=(const WifiManagerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace wifi_manager_plugin

#endif  // FLUTTER_PLUGIN_WIFI_MANAGER_PLUGIN_H_
