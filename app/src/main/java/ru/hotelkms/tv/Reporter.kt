package ru.hotelkms.tv

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Отчёты о скорости: POST JSON на REPORT_URL (Google Apps Script).
 * В приложении нет никаких токенов — уведомления в Telegram делает принимающая сторона.
 * Если отправить не удалось, отчёт ставится в очередь и уходит вместе со следующим.
 */
object Reporter {
    const val TYPE_AUTO = "auto"
    const val TYPE_GUEST = "guest"
    const val TYPE_COMPLAINT = "guest_complaint"

    private val lock = Any()

    fun timestamp(): String {
        val f = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US)
        f.timeZone = TimeZone.getTimeZone(Config.TIMEZONE)
        return f.format(Date())
    }

    fun build(ctx: Context, type: String, r: SpeedResult): JSONObject {
        val p = Prefs(ctx)
        fun n(v: Any?): Any = v ?: JSONObject.NULL
        return JSONObject().apply {
            put("hotel", p.hotelName)
            put("room", p.room)
            put("type", type)
            put("ping_ms", n(r.pingMs))
            put("down_mbps", n(r.downMbps?.let { round1(it) }))
            put("up_mbps", n(r.upMbps?.let { round1(it) }))
            put("wifi_ssid", n(NetInfo.wifiSsid(ctx)))
            put("wifi_rssi", n(NetInfo.wifiRssi(ctx)))
            put("app_version", BuildConfig.VERSION_NAME)
            put("timestamp", timestamp())
        }
    }

    private fun round1(v: Double): Double = Math.round(v * 10) / 10.0

    /**
     * Отправить отчёт (блокирующий вызов — только из фонового потока).
     * Возвращает true, если этот отчёт доставлен.
     */
    fun send(ctx: Context, report: JSONObject): Boolean {
        synchronized(lock) { return sendLocked(ctx, report) }
    }

    private fun sendLocked(ctx: Context, report: JSONObject): Boolean {
        Log.i(SpeedTest.TAG, "report: $report")
        val p = Prefs(ctx)
        val url = p.reportUrl.trim().ifEmpty { Config.FORM_URL }

        val queue = try { JSONArray(p.pendingReports) } catch (e: Exception) { JSONArray() }
        queue.put(report)
        val left = JSONArray()
        var delivered = false
        var networkOk = true
        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            val ok = networkOk && try {
                if (url.contains("/formResponse")) Http.postForm(url, mapOf(Config.FORM_ENTRY to formLine(item)))
                else Http.postJson(url, item.toString())
            } catch (e: Exception) {
                Log.w(SpeedTest.TAG, "report send failed: ${e.message}")
                false
            }
            if (ok) {
                if (item === report) delivered = true
            } else {
                networkOk = false // остальные даже не пробуем, отправим в следующий раз
                left.put(item)
            }
        }
        // храним не больше MAX_PENDING_REPORTS последних
        val trimmed = JSONArray()
        val from = maxOf(0, left.length() - Config.MAX_PENDING_REPORTS)
        for (i in from until left.length()) trimmed.put(left.get(i))
        p.pendingReports = trimmed.toString()
        return delivered
    }

    /**
     * Строка для журнала (Google Форма → таблица «Гостиницы — интернет в номерах и телефоны»):
     * гостиница;интернет;номер;загрузка;отдача;пинг;сигнал;оценка;кто
     */
    private fun formLine(r: JSONObject): String {
        val h = r.optString("hotel")
        val hotel = when {
            h.contains("Пушкин", true) -> "Пушкин"
            h.contains("Сити", true) || h.contains("City", true) -> "Сити"
            else -> h
        }
        fun num(k: String): String = if (r.isNull(k)) "" else r.opt(k).toString().replace('.', ',')
        val down = if (r.isNull("down_mbps")) null else r.optDouble("down_mbps")
        val grade = when {
            down == null -> "нет связи"
            down >= 20 -> "хорошо"
            down >= 5 -> "средне"
            else -> "плохо"
        }
        val rssi = if (r.isNull("wifi_rssi")) "" else "${r.optInt("wifi_rssi")} dBm"
        val who = when (r.optString("type")) {
            TYPE_AUTO -> "авто"
            TYPE_COMPLAINT -> "гость (жалоба)"
            else -> "гость"
        }
        return listOf(hotel, "интернет", r.optString("room"), num("down_mbps"), num("up_mbps"),
            num("ping_ms"), rssi, grade, who).joinToString(";") { it.replace(";", ",") }
    }

    fun pendingCount(ctx: Context): Int =
        try { JSONArray(Prefs(ctx).pendingReports).length() } catch (e: Exception) { 0 }
}
