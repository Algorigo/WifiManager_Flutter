//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <wifi_manager_plugin/wifi_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) wifi_manager_plugin_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WifiManagerPlugin");
  wifi_manager_plugin_register_with_registrar(wifi_manager_plugin_registrar);
}
