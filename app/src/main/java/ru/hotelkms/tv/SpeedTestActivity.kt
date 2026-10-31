package ru.hotelkms.tv

import android.app.Activity
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView

/** Экран проверки интернета: гостевой режим и служебный (полная проверка без автоотчёта). */
class SpeedTestActivity : Activity() {

    companion object {
        const val EXTRA_STAFF = "staff"
    }

    private var staff = false
    private var running = false
    private var complaintSent = false
    private var last: SpeedResult? = null

    private lateinit var titleView: TextView
    private lateinit var status: TextView
    private lateinit var down: TextView
    private lateinit var up: TextView
    private lateinit var ping: TextView
    private lateinit var verdict: TextView
    private lateinit var netInfo: TextView
    private lateinit var btnReport: Button
    private lateinit var btnAgain: Button
    private lateinit var btnBack: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_speedtest)
        staff = intent.getBooleanExtra(EXTRA_STAFF, false)

        titleView = findViewById(R.id.title)
        status = findViewById(R.id.status)
        down = findViewById(R.id.down)
        up = findViewById(R.id.up)
        ping = findViewById(R.id.ping)
        verdict = findViewById(R.id.verdict)
        netInfo = findViewById(R.id.netInfo)
        btnReport = findViewById(R.id.btnReport)
        btnAgain = findViewById(R.id.btnAgain)
        btnBack = findViewById(R.id.btnBack)

        if (staff) {
            titleView.text = "Полная проверка интернета"
            btnReport.visibility = View.GONE
        }
        listOf(btnReport, btnAgain, btnBack).forEach { it.focusZoom() }
        btnReport.isEnabled = false
        btnReport.setOnClickListener { sendComplaint() }
        btnAgain.setOnClickListener { startTest() }
        btnBack.setOnClickListener { finish() }

        startTest()
    }

    private fun ui(block: () -> Unit) = Bg.ui { if (!isFinishing && !isDestroyed) block() }

    private fun startTest() {
        if (running) return
        running = true
        down.text = "—"; up.text = "—"; ping.text = "—"
        verdict.visibility = View.INVISIBLE
        status.text = "Идёт проверка… Это займёт до 30 секунд."
        netInfo.text = NetInfo.shortLine(this)
        btnAgain.isEnabled = false
        btnReport.isEnabled = false
        btnBack.requestFocus()

        val app = applicationContext
        val prefs = Prefs(app)
        Bg.tests.execute {
            val st = SpeedTest(prefs)
            ui { status.text = "Измеряем пинг…" }
            val p = st.ping()
            ui { ping.text = p?.toString() ?: "—"; status.text = "Измеряем скорость загрузки…" }
            val d = st.download(Config.FULL_DOWNLOAD_MAX_BYTES, Config.FULL_DOWNLOAD_MAX_MS)
            ui { down.text = SpeedResult.fmt(d); status.text = "Измеряем скорость отдачи…" }
            val u = st.upload(Config.FULL_UPLOAD_BYTES, Config.FULL_UPLOAD_MAX_MS)
            val r = SpeedResult(p, d, u)
            Bg.ui { last = r; running = false }
            ui { showResult(r) }
            if (!staff) Reporter.send(app, Reporter.build(app, Reporter.TYPE_GUEST, r))
        }
    }

    private fun showResult(r: SpeedResult) {
        up.text = SpeedResult.fmt(r.upMbps)
        val v = Verdict.of(r)
        verdict.text = v.text
        verdict.background = roundedColor(this, v.color)
        verdict.visibility = View.VISIBLE
        status.text = "Проверка завершена"
        netInfo.text = NetInfo.shortLine(this)
        btnAgain.isEnabled = true
        if (!staff && !complaintSent) {
            btnReport.isEnabled = true
            btnReport.requestFocus()
        } else {
            btnAgain.requestFocus()
        }
    }

    private fun sendComplaint() {
        if (complaintSent) return
        complaintSent = true
        btnReport.isEnabled = false
        btnAgain.requestFocus()
        status.text = "Отправляем сообщение…"
        val app = applicationContext
        val r = last ?: SpeedResult()
        Bg.io.execute {
            val ok = Reporter.send(app, Reporter.build(app, Reporter.TYPE_COMPLAINT, r))
            val noUrl = Prefs(app).reportUrl.isBlank()
            ui {
                status.text = when {
                    ok -> "Сообщение отправлено администратору. Спасибо!"
                    noUrl -> "Сообщение записано. Пожалуйста, сообщите также на ресепшен."
                    else -> "Сейчас отправить не удалось — сообщение уйдёт автоматически, " +
                        "когда появится интернет. Можно также позвонить на ресепшен."
                }
            }
        }
    }
}
