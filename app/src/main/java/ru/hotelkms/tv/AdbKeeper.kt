package ru.hotelkms.tv

import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import java.io.File

/**
 * Держит включённой отладку по Wi-Fi (для удалённого обслуживания ТВ стойкой).
 * Работает только если выдано разрешение:
 * adb shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
 *
 * 06.11.2026: телевизоры «пропадали» со стойки — ТВ в сети, adb_wifi_enabled=1, но mDNS-объявление
 * отладки по Wi-Fi не идёт, стойка подключиться не может (Сити 3). Лечится только выключить/включить
 * отладку на самом ТВ. Теперь ТВ делает это сам: стойка при каждом обходе (tvinfo.sh, раз в 5 минут)
 * отмечается файлом files/stand_seen; если стойки не было дольше STAND_SILENT_MS — переключаем
 * отладку по Wi-Fi 0 → 1 (не чаще раза в RETOGGLE_MIN_MS), чтобы служба и mDNS поднялись заново.
 */
object AdbKeeper {
    private const val TAG = "HotelTV"
    private const val STAND_SEEN = "stand_seen"
    private const val STAND_SILENT_MS = 20L * 60 * 1000
    private const val RETOGGLE_MIN_MS = 30L * 60 * 1000
    private var lastToggle = 0L
    private val started = System.currentTimeMillis()

    fun ensure(ctx: Context) {
        try {
            val c = ctx.applicationContext ?: ctx
            if (c.checkSelfPermission("android.permission.WRITE_SECURE_SETTINGS") != PackageManager.PERMISSION_GRANTED) return
            val cr = c.contentResolver
            Settings.Global.putInt(cr, Settings.Global.ADB_ENABLED, 1)
            if (standSilent(c) && System.currentTimeMillis() - lastToggle > RETOGGLE_MIN_MS) {
                lastToggle = System.currentTimeMillis()
                Log.i(TAG, "AdbKeeper: stand not seen for a while — restarting wireless debugging")
                Settings.Global.putInt(cr, "adb_wifi_enabled", 0)
                Bg.main.postDelayed({
                    try { Settings.Global.putInt(cr, "adb_wifi_enabled", 1) } catch (t: Throwable) { Log.w(TAG, "AdbKeeper re-enable failed: $t") }
                }, 3_000)
            } else {
                Settings.Global.putInt(cr, "adb_wifi_enabled", 1)
            }
            Log.i(TAG, "AdbKeeper: adb and wireless debugging enabled")
        } catch (t: Throwable) {
            Log.w(TAG, "AdbKeeper failed: $t")
        }
    }

    /** Стойка не заходила на ТВ дольше STAND_SILENT_MS (файл files/stand_seen ставит tvinfo.sh через run-as). */
    private fun standSilent(c: Context): Boolean {
        val f = File(c.filesDir, STAND_SEEN)
        val last = if (f.exists()) f.lastModified() else started
        return System.currentTimeMillis() - last > STAND_SILENT_MS
    }
}
