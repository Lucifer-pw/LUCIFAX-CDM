package com.lucifax.lucifax_native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device reboot completed. Starting Lucifax services...")
            val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
            val protectionActive = prefs.getBoolean("protection_active", false)
            
            if (protectionActive) {
                try {
                    // Start foreground protection service
                    val serviceIntent = Intent(context, LucifaxForegroundService::class.java)
                    context.startForegroundService(serviceIntent)
                } catch (e: Exception) {
                    Log.e("BootReceiver", "Failed to start service on boot: ${e.message}")
                }
            }
        }
    }
}
