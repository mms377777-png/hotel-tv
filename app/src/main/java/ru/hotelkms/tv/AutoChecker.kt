package ru.hotelkms.tv

import android.content.Context
import android.util.Log

/** Лёгкая проверка интернета каждые 15 минут, пока приложение запущено (и после загрузки ТВ). */
object AutoChecker {
    private var started = false
    private lateinit var appCtx: Context

    private val loop = object : Runnable {
        override fun run() {
            runNow(appCtx, null)
            Bg.main.postDelayed(this, Config.AUTO_CHECK_INTERVAL_MS)
        }
    }

    fun start(ctx: Context) {
        if (started) return
        started = true
        appCtx = ctx.applicationContext
        Bg.main.postDelayed(loop, Config.AUTO_CHECK_FIRST_DELAY_MS)
        Log.i(SpeedTest.TAG, "auto check scheduled")
    }

    /** Запустить проверку сейчас; onDone вызывается в UI-потоке с текстом результата. */
    fun runNow(ctx: Context, onDone: ((String) -> Unit)?) {
        val c = ctx.applicationContext
        Bg.tests.execute {
            val prefs = Prefs(c)
            val r = SpeedTest(prefs).light()
            val sent = Reporter.send(c, Reporter.build(c, Reporter.TYPE_AUTO, r))
            val line = "${Reporter.timestamp()}: ${r.summary()}" +
                if (prefs.reportUrl.isBlank()) " (REPORT_URL не задан)"
                else if (sent) " (отчёт отправлен)" else " (отчёт в очереди)"
            prefs.lastAutoCheck = line
            if (onDone != null) Bg.ui { onDone(line) }
        }
    }
}
