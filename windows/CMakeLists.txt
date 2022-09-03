# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "x_media_info")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "x_media_info_plugin")

link_directories("third_party/ffmpeg/bin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "x_media_info_plugin.cpp"
  "x_media_info_plugin.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/x_media_info/x_media_info_plugin_c_api.h"
  "x_media_info_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})


target_compile_definitions(${PLUGIN_NAME} PRIVATE "WIN32")
target_compile_definitions(${PLUGIN_NAME} PRIVATE "HAVE_STRUCT_TIMESPEC")
target_compile_definitions(${PLUGIN_NAME} PRIVATE "__STDC_LIMIT_MACROS")

target_compile_options(${PLUGIN_NAME} PRIVATE /W4 /Wv:18 /WX- /wd"4100")

include_directories("third_party/ffmpeg/include")


# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(x_media_info_bundled_libraries
  ""
  PARENT_SCOPE
)


################################################################################

set(TARGET_DEBUG_DIR "${FLUTTER_MANAGED_DIR}/../../build/windows/runner/Debug/")
set(TARGET_RELEASE_DIR "${FLUTTER_MANAGED_DIR}/../../build/windows/runner/Release/")

execute_process(COMMAND ${CMAKE_COMMAND} -E
make_directory ${TARGET_DEBUG_DIR}
make_directory ${TARGET_RELEASE_DIR}
)

list(APPEND DLL_LIST
  msvcp140.dll
  vcruntime140.dll
  vcruntime140_1.dll
  avcodec-57.dll
  avdevice-57.dll
  avfilter-6.dll
  avformat-57.dll
  avutil-55.dll
  swresample-2.dll
  swscale-4.dll
  ffmpeg.exe
  libiconv-2.dll
  libwinpthread-1.dll
  zlib1.dll
)

foreach(dll ${DLL_LIST})
  execute_process(COMMAND ${CMAKE_COMMAND} -E
    copy "${CMAKE_CURRENT_SOURCE_DIR}/third_party/ffmpeg/bin/${dll}" ${TARGET_DEBUG_DIR}
  )
  execute_process(COMMAND ${CMAKE_COMMAND} -E
    copy "${CMAKE_CURRENT_SOURCE_DIR}/third_party/ffmpeg/bin/${dll}" ${TARGET_RELEASE_DIR}
  )
endforeach(dll)