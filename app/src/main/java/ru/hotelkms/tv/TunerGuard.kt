package ru.hotelkms.tv

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.media.tv.TvContract
import android.media.tv.TvInputInfo
import android.media.tv.TvInputManager
import android.os.Build
import android.util.Log

/**
 * 07.11.2026 (Михаил): гость попал на встроенный тюнер MediaTek, а каналов в нём нет — чёрный экран «Нет каналов,
 * выполните сканирование», дальше тюнер просит PIN 18+ (Пушкин 305). Сторож тюнера: если на экране тюнер
 * дольше [STAY_MS], каналов 0 и по HDMI/AV ничего не подключено — возвращаем экран приложения.
 * Если по HDMI что-то подключено (приставка, ноутбук) — не трогаем. Если гость сам вернулся на тюнер
 * в течение [FIGHT_MS] после нашего возврата — оставляем его в покое на [BACKOFF_MS].
 *
 * Нужен доступ к истории экранов (стойка: appops set ru.hotelkms.tv GET_USAGE_STATS allow) и право
 * открыть экран из фона (appops set ru.hotelkms.tv SYSTEM_ALERT_WINDOW allow). Без доступа сторож молчит.
 */
object TunerGuard {
    private const val TAG = "HotelTV"
    private const val TUNER_PKG = "com.mediatek.wwtv.tvcenter"
    private const val TUNER_MAIN = "TurnkeyUiMainActivity"
    private const val TICK_MS = 10_000L
    private const val STAY_MS = 15_000L
    private const val FIGHT_MS = 3L * 60 * 1000
    private const val BACKOFF_MS = 60L * 60 * 1000

    private var started = false
    private lateinit var appCtx: Context
    private var lastEventTs = 0L
    private var fgPkg = ""
    private var fgClass = ""
    private var fgSince = 0L
    private var lastReturn = 0L
    private var backoffUntil = 0L

    private val loop = object : Runnable {
        override fun run() {
            try { tick() } catch (t: Throwable) { Log.w(TAG, "TunerGuard: $t") }
            Bg.main.postDelayed(this, TICK_MS)
        }
    }

    fun start(ctx: Context) {
        if (started) return
        started = true
        appCtx = ctx.applicationContext
        Bg.main.postDelayed(loop, TICK_MS)
        // через 90 с: дождаться, пока стойка выдаст разрешения после обновления
        Bg.main.postDelayed({ Bg.io.execute { try { reportStateOnce() } catch (t: Throwable) { Log.w(TAG, "TunerGuard state: $t") } } }, 90_000)
    }

    private fun usm(): UsageStatsManager? = appCtx.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    /** Обновить, какой экран сейчас на переднем плане (по событиям ACTIVITY_RESUMED). */
    private fun updateForeground(): Boolean {
        val u = usm() ?: return false
        val now = System.currentTimeMillis()
        val from = if (lastEventTs == 0L) now - 6L * 3600 * 1000 else lastEventTs
        val ev = u.queryEvents(from, now) ?: return false
        val e = UsageEvents.Event()
        var any = false
        while (ev.hasNextEvent()) {
            ev.getNextEvent(e)
            any = true
            if (e.timeStamp > lastEventTs) lastEventTs = e.timeStamp
            if (e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                val p = e.packageName ?: ""
                val c = e.className ?: ""
                if (p != fgPkg || c != fgClass) { fgPkg = p; fgClass = c; fgSince = e.timeStamp }
            }
        }
        return any || lastEventTs > 0L
    }

    private fun tick() {
        if (!updateForeground()) return // нет доступа к истории экранов — ничего не делаем
        val now = System.currentTimeMillis()
        if (fgPkg != TUNER_PKG || !fgClass.endsWith(TUNER_MAIN)) return
        if (now - fgSince < STAY_MS || now < backoffUntil) return
        if (lastReturn > 0 && fgSince - lastReturn in 0..FIGHT_MS) {
            // гость сам вернулся на тюнер сразу после нашего возврата — значит, ему это нужно
            backoffUntil = now + BACKOFF_MS
            log("tyuner;gost vernulsya na tyuner sam - ne trogaem 60 min")
            return
        }
        val ch = channelCount()
        if (ch > 0) return
        val ext = connectedExternalInputs()
        if (ext.isNotEmpty()) return
        lastReturn = now
        val i = Intent(appCtx, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        appCtx.startActivity(i)
        log("tyuner;pustoy tyuner (kanalov ${if (ch < 0) "?" else ch}, HDMI ne podklyuchen) ${(now - fgSince) / 1000} s - vernul ekran prilozheniya")
    }

    /** Сколько каналов в тюнере: -1 — прочитать нельзя (нет права), считаем как 0: антенны в номерах нет. */
    private fun channelCount(): Int = try {
        appCtx.contentResolver.query(TvContract.Channels.CONTENT_URI, arrayOf(android.provider.BaseColumns._ID), null, null, null)
            ?.use { it.count } ?: -1
    } catch (t: Throwable) { -1 }

    /** Подключённые внешние входы (HDMI, AV, компонентный): состояние «подключено» или «подключено, спит». */
    private fun connectedExternalInputs(): List<String> {
        val tim = appCtx.getSystemService(Context.TV_INPUT_SERVICE) as? TvInputManager ?: return emptyList()
        val out = ArrayList<String>()
        for (info in tim.tvInputList) {
            if (info.type == TvInputInfo.TYPE_TUNER || info.type == TvInputInfo.TYPE_OTHER) continue
            val st = try { tim.getInputState(info.id) } catch (t: Throwable) { TvInputManager.INPUT_STATE_CONNECTED }
            if (st != TvInputManager.INPUT_STATE_DISCONNECTED) out.add(typeName(info.type) + ":" + st)
        }
        return out
    }

    private fun typeName(t: Int) = when (t) {
        TvInputInfo.TYPE_HDMI -> "HDMI"; TvInputInfo.TYPE_COMPOSITE -> "AV"; TvInputInfo.TYPE_COMPONENT -> "YPbPr"
        TvInputInfo.TYPE_VGA -> "VGA"; TvInputInfo.TYPE_SCART -> "SCART"; TvInputInfo.TYPE_SVIDEO -> "SVIDEO"
        TvInputInfo.TYPE_DVI -> "DVI"; TvInputInfo.TYPE_DISPLAY_PORT -> "DP"; else -> "T$t"
    }

    /** Один раз на версию — в журнал: есть ли доступ, сколько каналов, какие входы и в каком состоянии (для проверки). */
    private fun reportStateOnce() {
        val ver = try {
            val pi = appCtx.packageManager.getPackageInfo(appCtx.packageName, 0)
            if (Build.VERSION.SDK_INT >= 28) pi.longVersionCode.toString() else @Suppress("DEPRECATION") pi.versionCode.toString()
        } catch (t: Throwable) { "?" }
        val sp = appCtx.getSharedPreferences("tuner_guard", Context.MODE_PRIVATE)
        if (sp.getString("reported", "") == ver) return
        val access = try { updateForeground() } catch (t: Throwable) { false }
        val tim = appCtx.getSystemService(Context.TV_INPUT_SERVICE) as? TvInputManager
        val inputs = tim?.tvInputList?.joinToString(" ") { typeName(it.type) + "=" + (try { tim.getInputState(it.id) } catch (t: Throwable) { -1 }) } ?: "?"
        val ok = send("tyuner;sostoyanie v$ver: dostup=${if (access) "da" else "net"} kanalov=${channelCount()} vhody: $inputs")
        if (ok) sp.edit().putString("reported", ver).apply()
    }

    private fun log(text: String) { Log.i(TAG, "TunerGuard: $text"); Bg.io.execute { send(text) } }

    private fun send(text: String): Boolean {
        val p = Prefs(appCtx)
        val h = p.hotelName
        val hotel = when {
            h.contains("Пушкин", true) -> "Pushkin"
            h.contains("Сити", true) || h.contains("City", true) -> "Siti"
            h.contains("Завод", true) -> "Zavodskaya"
            else -> h
        }
        val parts = text.split(";", limit = 2)
        val line = "$hotel;${parts[0]};${p.room};${parts.getOrElse(1) { "" }}"
        return try { Http.postForm(Config.FORM_URL, mapOf(Config.FORM_ENTRY to line)) } catch (t: Throwable) { false }
    }
}
