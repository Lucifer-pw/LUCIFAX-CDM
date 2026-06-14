package com.lucifax.lucifax_cdm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class SIMChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.intent.action.SIM_STATE_CHANGED") {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val state = tm.simState
            Log.d("SIMChangeReceiver", "SIM State changed: $state")

            if (state == TelephonyManager.SIM_STATE_READY) {
                // Read subscription metadata or operator details
                val operatorName = tm.simOperatorName
                val operatorCode = tm.simOperator
                val country = tm.simCountryIso

                val prefs = context.getSharedPreferences("lucifax_prefs", Context.MODE_PRIVATE)
                val lastOperator = prefs.getString("last_sim_operator", null)

                if (lastOperator != null && lastOperator != operatorCode) {
                    Log.w("SIMChangeReceiver", "SIM Swap Detected! Old: $lastOperator, New: $operatorCode")
                    // Store warning flag
                    prefs.edit().putBoolean("sim_swap_alert", true).apply()
                    prefs.edit().putString("new_sim_operator_name", operatorName).apply()
                }

                // Update stored sim profile
                prefs.edit().putString("last_sim_operator", operatorCode).apply()
                prefs.edit().putString("last_sim_operator_name", operatorName).apply()
            }
        }
    }
}
