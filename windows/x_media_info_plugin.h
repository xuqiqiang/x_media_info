#ifndef FLUTTER_PLUGIN_X_MEDIA_INFO_PLUGIN_H_
#define FLUTTER_PLUGIN_X_MEDIA_INFO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace x_media_info {

class XMediaInfoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  XMediaInfoPlugin();

  virtual ~XMediaInfoPlugin();

  // Disallow copy and assign.
  XMediaInfoPlugin(const XMediaInfoPlugin&) = delete;
  XMediaInfoPlugin& operator=(const XMediaInfoPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace x_media_info

struct TParam {
    char* uri;
    char* id;
    bool detail;
};

#endif  // FLUTTER_PLUGIN_X_MEDIA_INFO_PLUGIN_H_
