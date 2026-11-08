package ru.hotelkms.tv

import android.content.Context
import android.util.Log
import java.net.URLEncoder
import java.security.MessageDigest

/**
 * 08.11.2026: имя гостя снимается с экрана само, даже если стойка до ТВ ещё не достучалась
 * (Сити 13: гость выехал в 8:50, ТВ был выключен; включили — на экране «Доброе утро, Павел Сергеевич», пока стойка не подключилась).
 * Раз в 2 минуты и сразу при включении экрана ТВ спрашивает бота (?a=tvguest): кто по 1С живёт в его номере.
 * Бот отдаёт не имя, а отпечаток (12 знаков SHA-256): номер свободен или гость другой — имя снимаем. Новое имя по-прежнему ставит стойка.
 */
object GuestCheck {
    private const val TAG = "HotelTV"
    private const val URL = "https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec"
    private const val PERIOD_MS = 2L * 60 * 1000

    @Volatile private var started = false
    @Volatile private var lastRun = 0L
    private lateinit var appCtx: Context

    private val loop = object : Runnable {
        override fun run() {
            runNow()
            Bg.main.postDelayed(this, PERIOD_MS)
        }
    }

    fun start(ctx: Context) {
        if (started) return
        started = true
        appCtx = ctx.applicationContext
        Bg.main.postDelayed(loop, 15_000)
    }

    /** Экран включили / вернулись на главный экран — проверить сразу (не чаще раза в 20 секунд). */
    fun runNow() {
        if (!started) return
        val now = android.os.SystemClock.elapsedRealtime()
        if (now - lastRun < 20_000) return
        lastRun = now
        Bg.io.execute { try { check() } catch (t: Throwable) { Log.w(TAG, "GuestCheck: $t") } }
    }

    private fun hotelCode(name: String): String? = when {
        name.contains("Пушкин", true) -> "pushkin"
        name.contains("Сити", true) || name.contains("City", true) -> "city"
        else -> null
    }

    fun fingerprint(name: String): String {
        val d = MessageDigest.getInstance("SHA-256").digest(name.trim().toByteArray(Charsets.UTF_8))
        return d.take(6).joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }

    private fun check() {
        val p = Prefs(appCtx)
        val name = p.guestName.trim()
        if (name.isEmpty()) return
        val h = hotelCode(p.hotelName) ?: return
        val room = p.room.trim()
        if (room.isEmpty()) return
        val ans = Http.getText("$URL?a=tvguest&h=$h&k=hk1&r=" + URLEncoder.encode(room, "UTF-8")).trim()
        if (ans == "?" || ans.isEmpty() || ans.length > 20) return // список из 1С устарел / ответ не тот — ничего не трогаем
        val fp = fingerprint(name)
        if (ans != "-" && ans == fp) return
        // защита от круга: стойка снова прислала то же имя при том же ответе бота — значит, расхождение в записи имени, а не выезд
        val pair = "$fp/$ans"
        if (p.guestClearedPair == pair) return
        // номер свободен или гость сменился: снимаем имя (экран обновится сам за 5 с); стойке при следующей отправке списка ответим OUT
        if (p.guestName.trim() != name) return
        p.guestCleared = name
        p.guestClearedPair = pair
        p.guestName = ""
        Log.i(TAG, "GuestCheck: imya snyato ($ans)")
        Journal.send(appCtx, "gost", if (ans == "-") "nomer svoboden po 1S - imya snyato s ekrana" else "v nomere drugoy gost po 1S - staroe imya snyato")
    }
}
