package com.lucifax.lucifax_native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
                Log.d("BootReceiver", "Device reboot completed. Starting Lucifax services...")
                val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
                val protectionActive = prefs.getBoolean("protection_active", false)
                
                if (protectionActive) {
                    try {
                        // Start foreground protection service safely
                        val serviceIntent = Intent(context, LucifaxForegroundService::class.java)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
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
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
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
