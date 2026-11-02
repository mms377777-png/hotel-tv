package ru.hotelkms.tv

import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log

/**
 * Держит включённой отладку по Wi-Fi (для удалённого обслуживания ТВ владельцем).
 * Работает только если выдано разрешение:
 * adb shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
 */
object AdbKeeper {
    private const val TAG = "HotelTV"

    fun ensure(ctx: Context) {
        try {
            val c = ctx.applicationContext ?: ctx
            if (c.checkSelfPermission("android.permission.WRITE_SECURE_SETTINGS") != PackageManager.PERMISSION_GRANTED) return
            val cr = c.contentResolver
            Settings.Global.putInt(cr, Settings.Global.ADB_ENABLED, 1)
            Settings.Global.putInt(cr, "adb_wifi_enabled", 1)
            Log.i(TAG, "AdbKeeper: adb and wireless debugging enabled")
        } catch (t: Throwable) {
            Log.w(TAG, "AdbKeeper failed: $t")
        }
    }
}
