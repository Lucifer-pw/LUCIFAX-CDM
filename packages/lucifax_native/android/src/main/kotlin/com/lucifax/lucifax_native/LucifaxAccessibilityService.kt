package com.lucifax.lucifax_native

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Path
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import java.io.File
import java.io.FileOutputStream

class LucifaxAccessibilityService : AccessibilityService() {

    companion object {
        private var instance: LucifaxAccessibilityService? = null

        fun isRunning(): Boolean = instance != null

        fun getInstance(): LucifaxAccessibilityService? = instance
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used - we only need gesture dispatch and screenshot capabilities
    }

    override fun onInterrupt() {
        // Not used
    }

    fun takeScreenshotSilently(callback: (String?) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            takeScreenshot(
                android.view.Display.DEFAULT_DISPLAY,
                mainExecutor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(screenshot: ScreenshotResult) {
                        try {
                            val hardwareBitmap = Bitmap.wrapHardwareBuffer(
                                screenshot.hardwareBuffer,
                                screenshot.colorSpace
                            )
                            if (hardwareBitmap != null) {
                                val softBitmap = hardwareBitmap.copy(Bitmap.Config.ARGB_8888, false)
                                hardwareBitmap.recycle()

                                val file = File(cacheDir, "screen_capture.jpg")
                                FileOutputStream(file).use { fos ->
                                    softBitmap.compress(Bitmap.CompressFormat.JPEG, 30, fos)
                                }
                                softBitmap.recycle()
                                callback(file.absolutePath)
                            } else {
                                callback(null)
                            }
                        } catch (e: Exception) {
                            callback(null)
                        } finally {
                            try {
                                screenshot.hardwareBuffer.close()
                            } catch (ex: Exception) {
                                // ignore
                            }
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        callback(null)
                    }
                }
            )
        } else {
            callback(null)
        }
    }

    fun performClick(x: Float, y: Float): Boolean {
        val path = Path()
        path.moveTo(x, y)

        val gestureBuilder = GestureDescription.Builder()
        gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, 100))

        return dispatchGesture(gestureBuilder.build(), null, null)
    }

    fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float, durationMs: Long): Boolean {
        val path = Path()
        path.moveTo(startX, startY)
        path.lineTo(endX, endY)

        val gestureBuilder = GestureDescription.Builder()
        gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))

        return dispatchGesture(gestureBuilder.build(), null, null)
    }
}
