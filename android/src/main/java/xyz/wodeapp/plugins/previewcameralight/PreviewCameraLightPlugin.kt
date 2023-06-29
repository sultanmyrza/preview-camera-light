package xyz.wodeapp.plugins.previewcameralight

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "PreviewCameraLight")
class PreviewCameraLightPlugin : Plugin() {
    private val implementation = PreviewCameraLight()
    @PluginMethod
    fun echo(call: PluginCall) {
        val value = call.getString("value")
        val ret = JSObject()
        ret.put("value", implementation.echo(value))
        call.resolve(ret)
    }
}