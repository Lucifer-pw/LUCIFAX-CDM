package com.lucifax.lucifax_native

import android.Manifest
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
                Log.d("BootReceiver", "Device reboot completed. Checking Lucifax requirements...")
                val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
                val protectionActive = prefs.getBoolean("protection_active", false)
                
                if (protectionActive) {
                    // 1. Check if Device Admin is active
                    val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                    val componentName = ComponentName(context, LucifaxDeviceAdminReceiver::class.java)
                    val isAdminActive = dpm?.isAdminActive(componentName) ?: false
                    
                    // 2. Check location and camera permissions
                    val hasLocation = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val hasCamera = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    
                    if (!isAdminActive || !hasLocation || !hasCamera) {
                        Log.w("BootReceiver", "Cannot start services on boot: missing requirements (admin=$isAdminActive, location=$hasLocation, camera=$hasCamera)")
                        return
                    }

                    try {
                        // Start foreground protection service safely
                        val serviceIntent = Intent(context, LucifaxForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    } catch (e: Exception) {
                        Log.e("BootReceiver", "Failed to start native service on boot: ${e.message}")
                    }

                    try {
                        // Start flutter background service safely
                        val flutterServiceIntent = Intent().setClassName(
                            context.packageName,
                            "id.flutter.flutter_background_service.BackgroundService"
                        )
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(flutterServiceIntent)
                        } else {
                            context.startService(flutterServiceIntent)
                        }
                    } catch (e: Exception) {
                        Log.e("BootReceiver", "Failed to start Flutter background service on boot: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error in BootReceiver onReceive: ${e.message}")
        }
    }
}
