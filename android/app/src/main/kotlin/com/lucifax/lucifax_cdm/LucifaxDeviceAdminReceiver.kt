package com.lucifax.lucifax_cdm

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class LucifaxDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Lucifax CDM: Administrator Perangkat Aktif", Toast.LENGTH_SHORT).show()
        
        val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("device_admin_active", true).apply()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Lucifax CDM: Administrator Perangkat Dinonaktifkan", Toast.LENGTH_SHORT).show()

        val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("device_admin_active", false).apply()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Show alert message to deter users or thieves from deactivating admin
        return "PERINGATAN: Menonaktifkan admin akan mematikan perlindungan anti-maling Lucifax CDM!"
    }
}
