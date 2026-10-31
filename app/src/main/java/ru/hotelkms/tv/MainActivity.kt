package ru.hotelkms.tv

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.SystemClock
import android.text.Editable
import android.text.InputFilter
import android.text.InputType
import android.text.TextWatcher
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Главный экран (может быть домашним экраном по умолчанию). */
class MainActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var clock: TextView
    private lateinit var date: TextView
    private lateinit var weather: TextView
    private lateinit var guestName: TextView
    private lateinit var hotelName: TextView
    private lateinit var roomLabel: TextView
    private val tileIcons = mutableListOf<Pair<AppTile, ImageView>>()
    private var firstTile: View? = null

    private val ru = Locale("ru", "RU")
    private val tz: TimeZone = TimeZone.getTimeZone(Config.TIMEZONE)
    private val timeFmt = SimpleDateFormat("HH:mm", ru).apply { timeZone = tz }
    private val dateFmt = SimpleDateFormat("EEEE, d MMMM", ru).apply { timeZone = tz }

    private var resumed = false
    private var weatherLoaded = false
    private var lastWeatherAt = 0L

    private val clockTick = object : Runnable {
        override fun run() {
            updateClock()
            Bg.main.postDelayed(this, 5_000)
        }
    }

    private val weatherTick = Runnable { refreshWeather() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        prefs = Prefs(this)

        clock = findViewById(R.id.clock)
        date = findViewById(R.id.date)
        weather = findViewById(R.id.weather)
        guestName = findViewById(R.id.guestName)
        hotelName = findViewById(R.id.hotelName)
        roomLabel = findViewById(R.id.roomLabel)

        hotelName.setOnLongClickListener { askPin(); true }

        val speedBtn = findViewById<View>(R.id.btnSpeedTest)
        speedBtn.focusZoom()
        speedBtn.setOnClickListener { startActivity(Intent(this, SpeedTestActivity::class.java)) }

        buildTiles(findViewById(R.id.tiles))
        firstTile?.requestFocus()
        AutoChecker.start(this)
    }

    private fun buildTiles(container: LinearLayout) {
        Config.TILES.chunked(3).forEach { rowTiles ->
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            container.addView(row, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            rowTiles.forEach { tile ->
                val v = makeTile(tile)
                val lp = LinearLayout.LayoutParams(0, dp(116), 1f)
                lp.setMargins(dp(10), dp(8), dp(10), dp(8))
                row.addView(v, lp)
                if (firstTile == null) firstTile = v
            }
        }
    }

    private fun makeTile(tile: AppTile): View {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundResource(R.drawable.tile_bg)
            isFocusable = true
            isClickable = true
            setPadding(dp(12), dp(8), dp(12), dp(8))
            contentDescription = tile.title
        }
        val icon = ImageView(this).apply {
            adjustViewBounds = true
            maxHeight = dp(52)
            maxWidth = dp(150)
            scaleType = ImageView.ScaleType.FIT_CENTER
            visibility = View.GONE
        }
        val title = TextView(this).apply {
            text = tile.title
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }
        box.addView(icon, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = dp(4)
        })
        box.addView(title, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        box.setOnClickListener { AppLauncher.launch(this, tile) }
        box.focusZoom()
        tileIcons += tile to icon
        return box
    }

    private fun refreshTileIcons() {
        for ((tile, iv) in tileIcons) {
            val d = AppLauncher.icon(this, tile)
            if (d != null) {
                iv.setImageDrawable(d)
                iv.visibility = View.VISIBLE
            } else {
                iv.setImageDrawable(null)
                iv.visibility = View.GONE
            }
        }
    }

    private fun refreshLabels() {
        hotelName.text = "Гостиница «${prefs.hotelName}»"
        val guest = prefs.guestName.trim()
        guestName.visibility = if (guest.isEmpty()) View.GONE else View.VISIBLE
        guestName.text = guest
        val room = prefs.room.trim()
        roomLabel.text = if (room.isEmpty()) "" else "Номер $room"
    }

    private fun updateClock() {
        val now = Date()
        clock.text = timeFmt.format(now)
        date.text = dateFmt.format(now).replaceFirstChar { it.titlecase(ru) }
    }

    private fun refreshWeather() {
        lastWeatherAt = SystemClock.elapsedRealtime()
        Bg.io.execute {
            val w = Weather.fetch()
            Bg.ui {
                if (isFinishing || isDestroyed) return@ui
                if (w != null) {
                    weather.text = w
                    weatherLoaded = true
                }
                Bg.main.removeCallbacks(weatherTick)
                if (resumed) {
                    // при ошибке — повтор через 2 минуты, иначе раз в 30 минут
                    Bg.main.postDelayed(weatherTick, if (w != null) Config.WEATHER_REFRESH_MS else 120_000L)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        resumed = true
        refreshLabels()
        refreshTileIcons()
        Bg.main.removeCallbacks(clockTick)
        clockTick.run()

        Bg.main.removeCallbacks(weatherTick)
        val since = SystemClock.elapsedRealtime() - lastWeatherAt
        val period = if (weatherLoaded) Config.WEATHER_REFRESH_MS else 120_000L
        if (lastWeatherAt == 0L || since >= period) refreshWeather()
        else Bg.main.postDelayed(weatherTick, period - since)
    }

    override fun onPause() {
        super.onPause()
        resumed = false
        Bg.main.removeCallbacks(clockTick)
        Bg.main.removeCallbacks(weatherTick)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_MENU) {
            askPin()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Будучи домашним экраном, «Назад» ничего не делает.
        if (!isDefaultHome()) {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    private fun isDefaultHome(): Boolean = try {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val ri = packageManager.resolveActivity(i, PackageManager.MATCH_DEFAULT_ONLY)
        ri?.activityInfo?.packageName == packageName
    } catch (e: Exception) {
        false
    }

    private fun askPin() {
        val input = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_VARIATION_PASSWORD
            filters = arrayOf(InputFilter.LengthFilter(4))
            hint = "PIN"
            gravity = Gravity.CENTER
            textSize = 28f
        }
        var handled = false
        val dlg = AlertDialog.Builder(this)
            .setTitle("Служебное меню")
            .setMessage("Введите PIN-код (4 цифры)")
            .setView(input)
            .setPositiveButton("Войти") { _, _ ->
                if (!handled) { handled = true; checkPin(input.text.toString()) }
            }
            .setNegativeButton("Отмена", null)
            .create()
        input.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                if (s != null && s.length == 4 && !handled) {
                    handled = true
                    dlg.dismiss()
                    checkPin(s.toString())
                }
            }
        })
        dlg.show()
        input.requestFocus()
    }

    private fun checkPin(pin: String) {
        if (pin == prefs.pin) {
            startActivity(Intent(this, ServiceActivity::class.java))
        } else {
            Toast.makeText(this, "Неверный PIN", Toast.LENGTH_SHORT).show()
        }
    }
}
