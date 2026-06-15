package com.lucifax.lucifax_native

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.media.AudioManager
import android.os.Build
import android.os.BatteryManager
import android.telephony.TelephonyManager

class LucifaxNativePlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.lucifax.cdm/native")
        channel.setMethodCallHandler { call, result ->
            val ctx = context
            if (ctx == null) {
                result.error("NO_CONTEXT", "Application context is null", null)
                return@setMethodCallHandler
            }
            
            when (call.method) {
                "lockDevice" -> {
                    val dpm = ctx.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                    if (dpm != null) {
                        val componentName = ComponentName(ctx, LucifaxDeviceAdminReceiver::class.java)
                        if (dpm.isAdminActive(componentName)) {
                            try {
                                dpm.lockNow()
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("LOCK_FAILED", e.message, null)
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("DPM_NULL", "DevicePolicyManager is not available", null)
                    }
                }
                "wipeDevice" -> {
                    val dpm = ctx.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                    if (dpm != null) {
                        val componentName = ComponentName(ctx, LucifaxDeviceAdminReceiver::class.java)
                        if (dpm.isAdminActive(componentName)) {
                            try {
                                dpm.wipeData(0)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("WIPE_FAILED", e.message, null)
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("DPM_NULL", "DevicePolicyManager is not available", null)
                    }
                }
                "isDeviceAdmin" -> {
                    val dpm = ctx.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                    if (dpm != null) {
                        val componentName = ComponentName(ctx, LucifaxDeviceAdminReceiver::class.java)
                        result.success(dpm.isAdminActive(componentName))
                    } else {
                        result.success(false)
                    }
                }
                "requestDeviceAdmin" -> {
                    val componentName = ComponentName(ctx, LucifaxDeviceAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Lucifax CDM membutuhkan akses admin untuk mengunci perangkat Anda jika hilang.")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    ctx.startActivity(intent)
                    result.success(null)
                }
                "capturePhoto" -> {
                    val cameraService = CameraService(ctx)
                    cameraService.captureSilentPhoto(object : CameraService.CameraCallback {
                        override fun onPhotoCaptured(path: String) {
                            result.success(path)
                        }

                        override fun onError(error: String) {
                            result.error("CAMERA_ERROR", error, null)
                        }
                    })
                }
                "getDeviceInfo" -> {
                    val info = mutableMapOf<String, Any>()
                    info["brand"] = Build.BRAND
                    info["model"] = Build.MODEL
                    info["manufacturer"] = Build.MANUFACTURER
                    info["androidVersion"] = Build.VERSION.RELEASE
                    info["sdkVersion"] = Build.VERSION.SDK_INT
                    
                    val bm = ctx.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
                    info["battery"] = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
                    
                    result.success(info)
                }
                "setMaxVolume" -> {
                    val am = ctx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                    if (am != null) {
                        try {
                            val maxAlarmVol = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                            am.setStreamVolume(AudioManager.STREAM_ALARM, maxAlarmVol, AudioManager.FLAG_PLAY_SOUND)

                            val maxMusicVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMusicVol, AudioManager.FLAG_PLAY_SOUND)

                            val maxRingVol = am.getStreamMaxVolume(AudioManager.STREAM_RING)
                            am.setStreamVolume(AudioManager.STREAM_RING, maxRingVol, AudioManager.FLAG_PLAY_SOUND)
                            
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    } else {
                        result.error("AUDIO_SERVICE_NULL", "Audio service is not available", null)
                    }
                }
                "startForegroundService" -> {
                    try {
                        val intent = Intent(ctx, LucifaxForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ctx.startForegroundService(intent)
                        } else {
                            ctx.startService(intent)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val intent = Intent(ctx, LucifaxForegroundService::class.java)
                        ctx.stopService(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_FAILED", e.message, null)
                    }
                }
                "getSimInfo" -> {
                    val info = mutableMapOf<String, Any>()
                    val tm = ctx.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                    if (tm != null) {
                        try {
                            info["simState"] = tm.simState
                            info["operatorName"] = tm.simOperatorName
                            info["operator"] = tm.simOperator
                            info["country"] = tm.simCountryIso
                        } catch (e: Exception) {
                            info["error"] = e.message ?: "Unknown telephony error"
                        }
                    } else {
                        info["error"] = "Telephony service not available"
                    }
                    result.success(info)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val file = java.io.File(path)
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                val apkUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    androidx.core.content.FileProvider.getUriForFile(
                                        ctx,
                                        "com.Lucifax_MCD.fileprovider",
                                        file
                                    )
                                } else {
                                    android.net.Uri.fromFile(file)
                                }
                                setDataAndType(apkUri, "application/vnd.android.package-archive")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            ctx.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(LucifaxAccessibilityService.isRunning())
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        ctx.startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "takeAccessibilityScreenshot" -> {
                    val service = LucifaxAccessibilityService.getInstance()
                    if (service != null) {
                        service.takeScreenshotSilently { path ->
                            if (path != null) {
                                result.success(path)
                            } else {
                                result.error("SCREENSHOT_FAILED", "Failed to take screenshot", null)
                            }
                        }
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not running", null)
                    }
                }
                "dispatchRemoteGesture" -> {
                    val service = LucifaxAccessibilityService.getInstance()
                    if (service != null) {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val gestureType = call.argument<String>("type") ?: "click"
                        
                        val displayMetrics = ctx.resources.displayMetrics
                        val screenWidth = displayMetrics.widthPixels.toFloat()
                        val screenHeight = displayMetrics.heightPixels.toFloat()
                        
                        val finalX = if (x in 0f..1f) x * screenWidth else x
                        val finalY = if (y in 0f..1f) y * screenHeight else y
                        
                        when (gestureType) {
                            "click" -> {
                                val success = service.performClick(finalX, finalY)
                                result.success(success)
                            }
                            "swipe" -> {
                                val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                                val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                                val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                                
                                val finalEndX = if (endX in 0f..1f) endX * screenWidth else endX
                                val finalEndY = if (endY in 0f..1f) endY * screenHeight else endY
                                
                                val success = service.performSwipe(finalX, finalY, finalEndX, finalEndY, duration)
                                result.success(success)
                            }
                            else -> result.error("UNKNOWN_GESTURE", "Unknown gesture type: $gestureType", null)
                        }
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not running", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}
