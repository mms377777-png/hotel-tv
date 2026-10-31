package ru.hotelkms.tv

import android.content.Context
import android.content.SharedPreferences

/** Настройки, которые меняет персонал в служебном меню. */
class Prefs(context: Context) {
    private val sp: SharedPreferences =
        context.applicationContext.getSharedPreferences("hotel_tv", Context.MODE_PRIVATE)

    private fun str(key: String, def: String): String = sp.getString(key, def) ?: def
    private fun put(key: String, value: String) = sp.edit().putString(key, value).apply()

    var room: String
        get() = str("room", "")
        set(v) = put("room", v)

    var hotelName: String
        get() = str("hotel_name", Config.DEFAULT_HOTEL_NAME).ifBlank { Config.DEFAULT_HOTEL_NAME }
        set(v) = put("hotel_name", v)

    var guestName: String
        get() = str("guest_name", Config.DEFAULT_GUEST_NAME)
        set(v) = put("guest_name", v)

    var reportUrl: String
        get() = str("report_url", Config.DEFAULT_REPORT_URL)
        set(v) = put("report_url", v)

    var downloadUrl: String
        get() = str("download_url", Config.DEFAULT_DOWNLOAD_URL).ifBlank { Config.DEFAULT_DOWNLOAD_URL }
        set(v) = put("download_url", v)

    var uploadUrl: String
        get() = str("upload_url", Config.DEFAULT_UPLOAD_URL).ifBlank { Config.DEFAULT_UPLOAD_URL }
        set(v) = put("upload_url", v)

    var pingUrl: String
        get() = str("ping_url", Config.DEFAULT_PING_URL).ifBlank { Config.DEFAULT_PING_URL }
        set(v) = put("ping_url", v)

    var pin: String
        get() = str("pin", Config.DEFAULT_PIN).ifBlank { Config.DEFAULT_PIN }
        set(v) = put("pin", v)

    var lastAutoCheck: String
        get() = str("last_auto", "")
        set(v) = put("last_auto", v)

    var pendingReports: String
        get() = str("pending_reports", "[]")
        set(v) = put("pending_reports", v)
}
