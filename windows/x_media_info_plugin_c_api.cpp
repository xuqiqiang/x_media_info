#include "include/x_media_info/x_media_info_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "x_media_info_plugin.h"

void XMediaInfoPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  x_media_info::XMediaInfoPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
