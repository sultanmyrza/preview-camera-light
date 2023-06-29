package xyz.wodeapp.plugins.previewcameralight

import android.util.Log

class PreviewCameraLight {
    fun echo(value: String?): String? {
        Log.i("Echo", value!!)
        return value
    }
}