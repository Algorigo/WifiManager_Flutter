#include "include/wifi_manager_plugin/wifi_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wifi_manager_plugin.h"

void WifiManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wifi_manager_plugin::WifiManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
