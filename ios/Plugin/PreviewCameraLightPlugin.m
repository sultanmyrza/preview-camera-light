#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(PreviewCameraLightPlugin, "PreviewCameraLight",
           CAP_PLUGIN_METHOD(echo, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(startPreview, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stopPreview, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(takePhoto, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(startRecord, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stopRecord, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(checkPermissions, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(requestPermissions, CAPPluginReturnPromise);
)
