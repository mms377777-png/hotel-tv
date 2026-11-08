package ru.hotelkms.tv

import android.content.Context
import android.os.SystemClock
import android.util.Log

/**
 * 08.11.2026: точное время из сети (Сити 12 показывал «четверг, 29 октября, 03:59» — часы ТВ сбились, а приложение брало системные).
 * Берём время из заголовка Date ответа сервера (по http: при сбитых часах https может не открыться из-за сертификата),
 * дальше считаем от монотонных часов ТВ. Пока сети не было ни разу с запуска — now() = null, и экран время/дату не показывает.
 */
object NetTime {
    private const val TAG = "HotelTV"
    private val URLS = listOf("http://www.google.com/generate_204", "http://ya.ru/", "http://connectivitycheck.gstatic.com/generate_204")
    private const val REFRESH_MS = 30L * 60 * 1000
    private const val RETRY_MS = 60_000L
    private const val DRIFT_REPORT_MS = 5L * 60 * 1000

    @Volatile private var base = 0L
    @Volatile private var baseElapsed = 0L
    @Volatile private var started = false
    @Volatile private var reported = false
    private lateinit var appCtx: Context

    /** Точное время (мс) или null, если с запуска приложения время из сети ещё не получено. */
    fun now(): Long? = if (baseElapsed == 0L) null else base + (SystemClock.elapsedRealtime() - baseElapsed)

    fun start(ctx: Context) {
        if (started) return
        started = true
        appCtx = ctx.applicationContext
        schedule(0)
    }

    /** Экран включили — время уже есть, но если давно не сверялись (ТВ спал), сверимся сразу. */
    fun refreshIfOld() {
        if (!started) return
        if (baseElapsed == 0L || SystemClock.elapsedRealtime() - baseElapsed > REFRESH_MS) schedule(0)
    }

    private fun schedule(delay: Long) {
        Bg.main.postDelayed({ Bg.io.execute { schedule(if (sync()) REFRESH_MS else RETRY_MS) } }, delay)
    }

    private fun sync(): Boolean {
        for (u in URLS) {
            try {
                val t0 = SystemClock.elapsedRealtime()
                val c = Http.open(u, 5000, 5000)
                c.instanceFollowRedirects = false
                try {
                    c.responseCode
                    val d = c.date
                    if (d <= 0L) continue
                    val t1 = SystemClock.elapsedRealtime()
                    // заголовок Date — с точностью до секунды; берём середину запроса
                    base = d + 500
                    baseElapsed = (t0 + t1) / 2
                    val drift = System.currentTimeMillis() - (base + (SystemClock.elapsedRealtime() - baseElapsed))
                    Log.i(TAG, "NetTime: ok $u drift=${drift / 1000}s")
                    if (!reported && Math.abs(drift) > DRIFT_REPORT_MS) {
                        reported = true
                        val tvTime = java.text.SimpleDateFormat("dd.MM HH:mm", java.util.Locale("ru")).apply {
                            timeZone = java.util.TimeZone.getTimeZone(Config.TIMEZONE)
                        }.format(java.util.Date())
                        Journal.send(appCtx, "chasy", "chasy TV sbity na ${drift / 60000} min (TV schitaet $tvTime) - na ekrane vremya iz seti")
                    }
                    return true
                } finally { c.disconnect() }
            } catch (t: Throwable) { Log.w(TAG, "NetTime $u: $t") }
        }
        return false
    }
}
