//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <x_media_info/x_media_info_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) x_media_info_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "XMediaInfoPlugin");
  x_media_info_plugin_register_with_registrar(x_media_info_registrar);
}
