package com.lucifax.lucifax_cdm

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.BatteryManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lucifax.cdm/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockDevice" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val componentName = ComponentName(this, LucifaxDeviceAdminReceiver::class.java)
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
                }
                "wipeDevice" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val componentName = ComponentName(this, LucifaxDeviceAdminReceiver::class.java)
                    if (dpm.isAdminActive(componentName)) {
                        try {
                            // Wipes device storage (Factory Reset)
                            dpm.wipeData(0)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WIPE_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "isDeviceAdmin" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val componentName = ComponentName(this, LucifaxDeviceAdminReceiver::class.java)
                    result.success(dpm.isAdminActive(componentName))
                }
                "requestDeviceAdmin" -> {
                    val componentName = ComponentName(this, LucifaxDeviceAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Lucifax CDM membutuhkan akses admin untuk mengunci perangkat Anda jika hilang.")
                    }
                    startActivity(intent)
                    result.success(null)
                }
                "capturePhoto" -> {
                    val cameraService = CameraService(this)
                    cameraService.captureSilentPhoto(object : CameraService.CameraCallback {
                        override fun onPhotoCaptured(path: String) {
                            runOnUiThread { result.success(path) }
                        }

                        override fun onError(error: String) {
                            runOnUiThread { result.error("CAMERA_ERROR", error, null) }
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
                    
                    val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    info["battery"] = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    
                    result.success(info)
                }
                "setMaxVolume" -> {
                    val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    try {
                        // Maximize alarm stream volume
                        val maxAlarmVol = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                        am.setStreamVolume(AudioManager.STREAM_ALARM, maxAlarmVol, AudioManager.FLAG_PLAY_SOUND)

                        // Maximize music stream volume
                        val maxMusicVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMusicVol, AudioManager.FLAG_PLAY_SOUND)

                        // Maximize ring stream volume
                        val maxRingVol = am.getStreamMaxVolume(AudioManager.STREAM_RING)
                        am.setStreamVolume(AudioManager.STREAM_RING, maxRingVol, AudioManager.FLAG_PLAY_SOUND)
                        
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("VOLUME_ERROR", e.message, null)
                    }
                }
                "startForegroundService" -> {
                    try {
                        val intent = Intent(this, LucifaxForegroundService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopForegroundService" -> {
                    try {
                        val intent = Intent(this, LucifaxForegroundService::class.java)
                        stopService(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_FAILED", e.message, null)
                    }
                }
                "getSimInfo" -> {
                    val info = mutableMapOf<String, Any>()
                    val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    try {
                        info["simState"] = tm.simState
                        info["operatorName"] = tm.simOperatorName
                        info["operator"] = tm.simOperator
                        info["country"] = tm.simCountryIso
                    } catch (e: Exception) {
                        info["error"] = e.message ?: "Unknown telephony error"
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
                                        this@MainActivity,
                                        "com.Lucifax_MCD.fileprovider",
                                        file
                                    )
                                } else {
                                    android.net.Uri.fromFile(file)
                                }
                                setDataAndType(apkUri, "application/vnd.android.package-archive")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
