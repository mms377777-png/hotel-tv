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
import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import java.util.Calendar
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
    private lateinit var greeting: TextView
    private lateinit var wifiBlock: View
    private lateinit var wifiSsidText: TextView
    private lateinit var wifiPassText: TextView
    private lateinit var wifiQr: ImageView
    private var wifiQrKey: String? = null
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
        greeting = findViewById(R.id.greeting)
        wifiBlock = findViewById(R.id.wifiBlock)
        wifiSsidText = findViewById(R.id.wifiSsidText)
        wifiPassText = findViewById(R.id.wifiPassText)
        wifiQr = findViewById(R.id.wifiQr)
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
        Config.TILES.chunked(4).forEach { rowTiles ->
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            container.addView(row, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            rowTiles.forEach { tile ->
                val v = makeTile(tile)
                val lp = LinearLayout.LayoutParams(0, dp(104), 1f)
                lp.setMargins(dp(8), dp(6), dp(8), dp(6))
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
        box.setOnClickListener {
            if (tile.isGames) startActivity(Intent(this, GamesActivity::class.java))
            else AppLauncher.launch(this, tile)
        }
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
        // имя гостя показываем в приветствии, отдельная строка не нужна
        guestName.visibility = View.GONE
        guestName.text = guest
        updateGreeting()
        refreshWifi()
        val room = prefs.room.trim()
        roomLabel.text = if (room.isEmpty()) "" else "Номер $room"
    }

    private fun updateClock() {
        val now = Date()
        clock.text = timeFmt.format(now)
        date.text = dateFmt.format(now).replaceFirstChar { it.titlecase(ru) }
        updateGreeting()
    }

    private fun updateGreeting() {
        val hour = Calendar.getInstance(tz).get(Calendar.HOUR_OF_DAY)
        val hello = when (hour) {
            in 5..11 -> "Доброе утро"
            in 12..17 -> "Добрый день"
            in 18..22 -> "Добрый вечер"
            else -> "Доброй ночи"
        }
        val guest = prefs.guestName.trim()
        greeting.text = if (guest.isEmpty()) "$hello!" else "$hello, $guest!"
    }

    private fun refreshWifi() {
        val ssid = prefs.wifiSsid.trim()
        if (ssid.isEmpty()) {
            wifiBlock.visibility = View.GONE
            wifiQrKey = null
            return
        }
        val pass = prefs.wifiPass
        wifiSsidText.text = "Wi‑Fi: $ssid"
        wifiPassText.text = "Пароль: $pass"
        wifiPassText.visibility = if (pass.isEmpty()) View.GONE else View.VISIBLE
        val payload = wifiPayload(ssid, pass)
        if (payload != wifiQrKey) {
            wifiQrKey = payload
            wifiQr.setImageBitmap(makeQr(payload, 400))
        }
        wifiBlock.visibility = View.VISIBLE
    }

    private fun wifiEscape(s: String): String {
        val sb = StringBuilder()
        for (c in s) {
            if (c == '\\' || c == ';' || c == ',' || c == ':' || c == '"') sb.append('\\')
            sb.append(c)
        }
        return sb.toString()
    }

    private fun wifiPayload(ssid: String, pass: String): String =
        if (pass.isEmpty()) "WIFI:T:nopass;S:${wifiEscape(ssid)};;"
        else "WIFI:T:WPA;S:${wifiEscape(ssid)};P:${wifiEscape(pass)};;"

    private fun makeQr(text: String, size: Int): Bitmap? = try {
        val hints = mapOf(EncodeHintType.MARGIN to 2, EncodeHintType.CHARACTER_SET to "UTF-8")
        val m = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, hints)
        val px = IntArray(m.width * m.height)
        for (y in 0 until m.height) for (x in 0 until m.width) {
            px[y * m.width + x] = if (m.get(x, y)) Color.BLACK else Color.WHITE
        }
        Bitmap.createBitmap(px, m.width, m.height, Bitmap.Config.ARGB_8888)
    } catch (e: Exception) {
        null
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
        AutoChecker.onWake(this)
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
