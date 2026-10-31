package ru.hotelkms.tv

import android.os.SystemClock
import android.util.Log
import java.util.Locale

data class SpeedResult(
    val pingMs: Long? = null,
    val downMbps: Double? = null,
    val upMbps: Double? = null,
) {
    fun summary(): String = String.format(
        Locale.US, "пинг %s мс, загрузка %s, отдача %s Мбит/с",
        pingMs?.toString() ?: "—", fmt(downMbps), fmt(upMbps),
    )

    companion object {
        fun fmt(v: Double?): String = when {
            v == null -> "—"
            v >= 10 -> String.format(Locale.US, "%.0f", v)
            else -> String.format(Locale.US, "%.1f", v)
        }
    }
}

/** Простая проверка скорости на HttpURLConnection. Все методы — блокирующие, вызывать в фоне. */
class SpeedTest(private val prefs: Prefs) {

    /** Медиана времени нескольких маленьких HTTP-запросов, мс. */
    fun ping(count: Int = Config.PING_COUNT): Long? {
        val times = mutableListOf<Long>()
        repeat(count) {
            try {
                val c = Http.open(Http.noCache(prefs.pingUrl), 5000, 5000)
                try {
                    val t0 = SystemClock.elapsedRealtime()
                    val code = c.responseCode
                    if (code in 200..399) {
                        c.inputStream.use { s -> while (s.read() >= 0) { /* пусто */ } }
                        times += SystemClock.elapsedRealtime() - t0
                    }
                } finally {
                    c.disconnect()
                }
            } catch (e: Exception) {
                Log.w(TAG, "ping: ${e.message}")
            }
        }
        if (times.isEmpty()) return null
        times.sort()
        return times[times.size / 2]
    }

    /** Скорость загрузки, Мбит/с. Читает до maxBytes байт или до maxMs миллисекунд. */
    fun download(maxBytes: Long, maxMs: Long): Double? {
        var total = 0L
        var elapsed = 0L
        try {
            val c = Http.open(Http.noCache(prefs.downloadUrl), 7000, 10000)
            try {
                if (c.responseCode !in 200..299) return null
                val t0 = SystemClock.elapsedRealtime()
                c.inputStream.use { s ->
                    val buf = ByteArray(64 * 1024)
                    while (true) {
                        val n = s.read(buf)
                        if (n < 0) break
                        total += n
                        elapsed = SystemClock.elapsedRealtime() - t0
                        if (total >= maxBytes || elapsed >= maxMs) break
                    }
                }
                elapsed = SystemClock.elapsedRealtime() - t0
            } finally {
                c.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "download: ${e.message}")
        }
        return mbps(total, elapsed)
    }

    /** Скорость отдачи, Мбит/с. Отправляет до [bytes] байт POST-запросом, не дольше maxMs. */
    fun upload(bytes: Long, maxMs: Long): Double? {
        var sent = 0L
        var elapsed = 0L
        try {
            val c = Http.open(Http.noCache(prefs.uploadUrl), 7000, 15000)
            try {
                c.requestMethod = "POST"
                c.doOutput = true
                c.setFixedLengthStreamingMode(bytes)
                c.setRequestProperty("Content-Type", "application/octet-stream")
                val buf = ByteArray(64 * 1024)
                val t0 = SystemClock.elapsedRealtime()
                val out = c.outputStream
                var stoppedEarly = false
                while (sent < bytes) {
                    val n = minOf(buf.size.toLong(), bytes - sent).toInt()
                    out.write(buf, 0, n)
                    sent += n
                    if (SystemClock.elapsedRealtime() - t0 >= maxMs) {
                        stoppedEarly = true
                        break
                    }
                }
                if (!stoppedEarly) {
                    out.close()
                    c.responseCode // ждём, пока сервер примет всё
                }
                elapsed = SystemClock.elapsedRealtime() - t0
            } finally {
                c.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "upload: ${e.message}")
        }
        return mbps(sent, elapsed)
    }

    private fun mbps(bytes: Long, ms: Long): Double? {
        if (bytes < 50_000 || ms <= 0) return null
        return bytes * 8.0 / (ms / 1000.0) / 1_000_000.0
    }

    /** Лёгкая автопроверка: пинг + ≈3 МБ загрузки. */
    fun light(): SpeedResult = SpeedResult(
        pingMs = ping(4),
        downMbps = download(Config.LIGHT_DOWNLOAD_MAX_BYTES, Config.LIGHT_DOWNLOAD_MAX_MS),
    )

    companion object {
        const val TAG = "HotelTV"
    }
}

enum class Verdict(val color: Int, val text: String) {
    GOOD(0xFF2E9E4F.toInt(), "Интернет работает хорошо"),
    SLOW(0xFFD9A21B.toInt(), "Интернет работает, но медленно"),
    BAD(0xFFD23C3C.toInt(), "Интернет работает плохо"),
    NONE(0xFFD23C3C.toInt(), "Нет подключения к интернету");

    companion object {
        fun of(r: SpeedResult): Verdict {
            val d = r.downMbps ?: return if (r.pingMs == null) NONE else BAD
            return when {
                d >= Config.GOOD_MBPS -> GOOD
                d >= Config.OK_MBPS -> SLOW
                else -> BAD
            }
        }
    }
}
