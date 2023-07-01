package xyz.wodeapp.plugins.previewcameralight

import android.Manifest
import android.content.ContentValues
import android.database.Cursor
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.core.content.PermissionChecker
import androidx.lifecycle.LifecycleOwner
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

@CapacitorPlugin(
    name = "PreviewCameraLight",
    permissions = [
        Permission(
            strings = [Manifest.permission.CAMERA],
            alias = PreviewCameraLightPlugin.CAMERA_PERMISSION_ALIAS
        ),
        Permission(
            strings = [Manifest.permission.RECORD_AUDIO],
            alias = PreviewCameraLightPlugin.RECORD_AUDIO_PERMISSION_ALIAS
        )
    ]
)
class PreviewCameraLightPlugin : Plugin() {

    private var imageCapture: ImageCapture? = null

    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null

//    private lateinit var cameraExecutor: ExecutorService

    private val implementation = PreviewCameraLight()

//    override fun load() {
//        super.load()
//
//        // TODO: ask ionic community should we call cameraExecutor.shutdown()?
//        cameraExecutor = Executors.newSingleThreadExecutor()
//    }

    @PluginMethod
    fun echo(call: PluginCall) {
        val value = call.getString("value")
        val ret = JSObject()
        ret.put("value", implementation.echo(value))
        call.resolve(ret)
    }

    @PluginMethod
    fun startPreview(call: PluginCall) {
        // Used to bind the lifecycle of cameras to the lifecycle owner. This eliminates the task
        // of opening and closing the camera since CameraX is lifecycle-aware.
        val cameraProviderFuture = ProcessCameraProvider.getInstance(bridge.context)

        // This returns an Executor that runs on the main thread.
        cameraProviderFuture.addListener({
            try {
                // Used to bind the lifecycle of our camera to the LifecycleOwner within the
                // application's process
                val cameraProvider = cameraProviderFuture.get()

                // Used as a parent container for previewView
                val previewViewParent = FrameLayout(bridge.context).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                    tag = previewViewParentTagId
                }

                // Used as surface provider for camera x preview use case
                val previewView = PreviewView(bridge.context).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                }

                previewViewParent.addView(previewView)

                ((bridge.webView.parent) as ViewGroup).addView(previewViewParent)

                // Preview Use Case
                val previewUseCase = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

                // Image Capture Use Case
                imageCapture = ImageCapture.Builder().build()

                // Video Capture use case
                videoCapture = VideoCapture.withOutput(
                    Recorder.Builder()
                        .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                        .build()
                )

                // Select back camera as a default
                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                // Unbind use cases before rebinding
                cameraProvider.unbindAll()

                // Bind use cases to camera
                cameraProvider.bindToLifecycle(
                    bridge.activity as LifecycleOwner,
                    cameraSelector,
                    previewUseCase,
                    imageCapture,
                    videoCapture
                )

                // Bring the WebView to the front and make its background transparent (capacitor thing).
                bridge.webView.bringToFront()
                bridge.webView.setBackgroundColor(Color.TRANSPARENT)

                call.resolve()
            } catch (exc: Exception) {
                val msg = "Error starting camera preview"
                Log.e(TAG, msg, exc)
                call.reject(msg, exc)
            }
        }, ContextCompat.getMainExecutor(bridge.activity))
    }


    @PluginMethod
    fun stopPreview(call: PluginCall) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val cameraProviderFuture = ProcessCameraProvider.getInstance(bridge.context)

                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    // Unbind all camera use cases to stop the preview
                    cameraProvider.unbindAll()

                    val viewToRemove: View? =
                        ((bridge.webView.parent) as ViewGroup).findViewWithTag(
                            previewViewParentTagId
                        )
                    if (viewToRemove != null) {
                        ((bridge.webView.parent) as ViewGroup).removeView(viewToRemove)
                    }

                    call.resolve()
                }, ContextCompat.getMainExecutor(bridge.activity))
            } catch (exc: Exception) {
                val msg = "Error stopping camera preview"
                Log.d(TAG, msg, exc)
                call.reject(msg, exc)
            }
        }
    }


    @PluginMethod
    fun takePhoto(call: PluginCall) {
        // Get a stable reference of the modifiable image capture use case
        val imageCapture = imageCapture ?: run {
            val msg = "Cannot take photo, ImageCapture is not initialized."
            Log.d(TAG, msg)
            call.reject(msg)
            return
        }

        // Create time stamped name and MediaStore entry.
        val name = SimpleDateFormat(FILENAME_FORMAT, Locale.US)
            .format(System.currentTimeMillis())
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CameraX-Image")
            }
        }

        // Create output options object which contains file + metadata
        val outputOptions = ImageCapture.OutputFileOptions
            .Builder(
                bridge.activity.contentResolver,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentValues
            )
            .build()

        // Set up image capture listener, which is triggered after photo has
        // been taken
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(bridge.activity),
            object : ImageCapture.OnImageSavedCallback {

                override fun onError(exc: ImageCaptureException) {
                    val msg = "Photo capture failed: ${exc.message}"
                    Log.e(TAG, msg, exc)
                    call.reject(msg, exc)
                }

                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    Log.d(TAG, "Photo capture succeeded: ${output.savedUri}")
                    // First, release the plugin call to notify the Ionic side that the photo was
                    // taken successfully.
                    call.resolve()

                    // Second the CaptureResultSuccess data to send to the Ionic side.
                    // This allows listeners on the Ionic side to receive and work with the captured image.
                    // We use notifyListeners to be consistent with video capture process
                    val result = JSObject().apply {
                        put("name", name)
                        put("mimeType", "image/jpeg")
                        put("path", output.savedUri.toString())
                        put("size", getFileSize(output.savedUri))
                    }
                    notifyListeners("captureSuccessResult", result)
                }
            }
        )
    }

    @PluginMethod
    fun startRecord(call: PluginCall) {
        val videoCapture = this.videoCapture ?: run {
            val msg = "Cannot start video recording, VideoCapture is not initialized."
            Log.d(TAG, msg)
            call.reject(msg)
            return
        }

        val curRecording = recording
        if (curRecording != null) {
            call.reject("Recording is already in progress, please stop record first")
            return
        }

        // create and start a new recording session
        val name = SimpleDateFormat(FILENAME_FORMAT, Locale.US)
            .format(System.currentTimeMillis())
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P) {
                put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/CameraX-Video")
            }
        }

        val mediaStoreOutputOptions = MediaStoreOutputOptions
            .Builder(bridge.activity.contentResolver, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
            .setContentValues(contentValues)
            .build()

        recording = videoCapture.output
            .prepareRecording(bridge.context, mediaStoreOutputOptions)
            .apply {
                val recordAudioPermission = PermissionChecker.checkSelfPermission(
                    bridge.context,
                    Manifest.permission.RECORD_AUDIO
                )
                if (recordAudioPermission == PermissionChecker.PERMISSION_GRANTED) {
                    withAudioEnabled()
                }
            }.start(ContextCompat.getMainExecutor(bridge.activity)) { recordEvent ->
                when (recordEvent) {
                    is VideoRecordEvent.Start -> {
                        Log.d(TAG, "Video capture started")
                        // We immediately release the plugin call to notify the Ionic side that
                        // the video was capture started successfully.
                        call.resolve()
                    }

                    is VideoRecordEvent.Finalize -> {
                        if (!recordEvent.hasError()) {
                            val msg = "Video captured: ${recordEvent.outputResults.outputUri}"
                            Log.d(TAG, msg)

                            // First, release the plugin call to notify the Ionic side that the video was
                            // captured successfully.
                            call.resolve()

                            // Second the CaptureResultSuccess data to send to the Ionic side.
                            // This allows listeners on the Ionic side to receive and work with the captured image.
                            val result = JSObject().apply {
                                put("name", name)
                                put("mimeType", "image/jpeg")
                                put("path", recordEvent.outputResults.outputUri.toString())
                                put("size", getFileSize(recordEvent.outputResults.outputUri))
                            }
                            notifyListeners("captureSuccessResult", result)
                        } else {
                            recording?.close()
                            recording = null
                            val msg = "Video capture ends with error: ${recordEvent.error}"
                            Log.e(TAG, msg)
                            call.reject(msg)
                        }
                    }
                }
            }
    }

    @PluginMethod
    fun stopRecord(call: PluginCall) {
        val curRecording = recording
        if (curRecording != null) {
            // Stop the current recording session.
            curRecording.stop()
            recording = null
            call.resolve()
        } else {
            call.reject("No active recording session")
        }

    }

    @PluginMethod
    override fun requestPermissions(call: PluginCall) {
        requestAllPermissions(call, "requestAllPermissionsCallback")
    }

    @PermissionCallback
    fun requestAllPermissionsCallback(call: PluginCall) {
        val cameraPermissionState = getPermissionState(CAMERA_PERMISSION_ALIAS)
        val microphonePermissionState = getPermissionState(RECORD_AUDIO_PERMISSION_ALIAS)

        val result = JSObject()
        result.put("camera", cameraPermissionState)
        result.put("microphone", microphonePermissionState)
        call.resolve(result)
    }


    private fun getFileSize(uri: Uri?): Long {
        if (uri == null) {
            return -1L
        }

        var fileSize = -1L
        var cursor: Cursor? = null



        try {
            cursor = bridge.context.contentResolver.query(uri, null, null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                fileSize = cursor.getLong(sizeIndex)
            }
        } finally {
            cursor?.close()
        }

        return fileSize
    }

    companion object {
        private const val TAG = "PreviewCameraLight"
        private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"
        private const val previewViewParentTagId = "PreviewViewParentTagId"

        const val CAMERA_PERMISSION_ALIAS = "cameraPermissionAlias"
        const val RECORD_AUDIO_PERMISSION_ALIAS = "recordAudioPermissionAlias"
    }
}