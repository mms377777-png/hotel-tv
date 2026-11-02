package ru.hotelkms.tv

import android.content.Context
import android.util.Log

/** Лёгкая проверка интернета каждые 15 минут, пока приложение запущено (и после загрузки ТВ). */
object AutoChecker {
    private var started = false
    private lateinit var appCtx: Context

    private val loop = object : Runnable {
        override fun run() {
            AdbKeeper.ensure(appCtx)
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

    private var lastWakeCheck = 0L
    private val wakeRun = Runnable { runNow(appCtx, null) }

    /** Телевизор включили (экран снова на переднем плане) — проверить интернет через минуту, не чаще раза в 5 минут. */
    fun onWake(ctx: Context) {
        appCtx = ctx.applicationContext
        val now = System.currentTimeMillis()
        if (now - lastWakeCheck < 5L * 60 * 1000) return
        lastWakeCheck = now
        Bg.main.removeCallbacks(wakeRun)
        Bg.main.postDelayed(wakeRun, 60L * 1000)
    }

    /** Запустить проверку сейчас; onDone вызывается в UI-потоке с текстом результата. */
    fun runNow(ctx: Context, onDone: ((String) -> Unit)?) {
        val c = ctx.applicationContext
        Bg.tests.execute {
            val prefs = Prefs(c)
            val r = SpeedTest(prefs).light()
            val sent = Reporter.send(c, Reporter.build(c, Reporter.TYPE_AUTO, r))
            val line = "${Reporter.timestamp()}: ${r.summary()}" +
                if (false) ""
                else if (sent) " (отчёт отправлен)" else " (отчёт в очереди)"
            prefs.lastAutoCheck = line
            if (onDone != null) Bg.ui { onDone(line) }
        }
    }
}
