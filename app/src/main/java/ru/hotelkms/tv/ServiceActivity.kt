package ru.hotelkms.tv

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast

/** Служебное меню персонала (вход по PIN). */
class ServiceActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var editRoom: EditText
    private lateinit var editHotel: EditText
    private lateinit var editGuest: EditText
    private lateinit var editReportUrl: EditText
    private lateinit var editDownloadUrl: EditText
    private lateinit var editUploadUrl: EditText
    private lateinit var editPingUrl: EditText
    private lateinit var editPin: EditText
    private lateinit var deviceInfo: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_service)
        prefs = Prefs(this)

        editRoom = findViewById(R.id.editRoom)
        editHotel = findViewById(R.id.editHotel)
        editGuest = findViewById(R.id.editGuest)
        editReportUrl = findViewById(R.id.editReportUrl)
        editDownloadUrl = findViewById(R.id.editDownloadUrl)
        editUploadUrl = findViewById(R.id.editUploadUrl)
        editPingUrl = findViewById(R.id.editPingUrl)
        editPin = findViewById(R.id.editPin)
        deviceInfo = findViewById(R.id.deviceInfo)

        editRoom.setText(prefs.room)
        editHotel.setText(prefs.hotelName)
        editGuest.setText(prefs.guestName)
        editReportUrl.setText(prefs.reportUrl)
        editDownloadUrl.setText(prefs.downloadUrl)
        editUploadUrl.setText(prefs.uploadUrl)
        editPingUrl.setText(prefs.pingUrl)

        val buttons = listOf<Button>(
            findViewById(R.id.btnSave), findViewById(R.id.btnClose), findViewById(R.id.btnFullTest),
            findViewById(R.id.btnAutoNow), findViewById(R.id.btnSettings),
        )
        buttons.forEach { it.focusZoom(1.04f) }

        findViewById<Button>(R.id.btnSave).setOnClickListener { save() }
        findViewById<Button>(R.id.btnClose).setOnClickListener { finish() }
        findViewById<Button>(R.id.btnFullTest).setOnClickListener {
            startActivity(Intent(this, SpeedTestActivity::class.java).putExtra(SpeedTestActivity.EXTRA_STAFF, true))
        }
        findViewById<Button>(R.id.btnAutoNow).setOnClickListener {
            Toast.makeText(this, "Проверка запущена, ждите 10–20 секунд…", Toast.LENGTH_SHORT).show()
            AutoChecker.runNow(this) { line ->
                if (!isFinishing && !isDestroyed) {
                    refreshInfo()
                    Toast.makeText(this, line, Toast.LENGTH_LONG).show()
                }
            }
        }
        findViewById<Button>(R.id.btnSettings).setOnClickListener {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (e: Exception) {
                Toast.makeText(this, "Не удалось открыть настройки", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        refreshInfo()
    }

    private fun save() {
        val newPin = editPin.text.toString().trim()
        if (newPin.isNotEmpty() && !newPin.matches(Regex("\\d{4}"))) {
            Toast.makeText(this, "PIN должен состоять из 4 цифр", Toast.LENGTH_LONG).show()
            editPin.requestFocus()
            return
        }
        prefs.room = editRoom.text.toString().trim()
        prefs.hotelName = editHotel.text.toString().trim()
        prefs.guestName = editGuest.text.toString().trim()
        prefs.reportUrl = editReportUrl.text.toString().trim()
        prefs.downloadUrl = editDownloadUrl.text.toString().trim()
        prefs.uploadUrl = editUploadUrl.text.toString().trim()
        prefs.pingUrl = editPingUrl.text.toString().trim()
        if (newPin.isNotEmpty()) {
            prefs.pin = newPin
            editPin.setText("")
        }
        // показать значения по умолчанию, если поле очистили
        editHotel.setText(prefs.hotelName)
        editDownloadUrl.setText(prefs.downloadUrl)
        editUploadUrl.setText(prefs.uploadUrl)
        editPingUrl.setText(prefs.pingUrl)
        Toast.makeText(this, if (newPin.isNotEmpty()) "Сохранено. PIN изменён." else "Сохранено", Toast.LENGTH_SHORT).show()
        refreshInfo()
    }

    private fun isDefaultHome(): Boolean = try {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        packageManager.resolveActivity(i, PackageManager.MATCH_DEFAULT_ONLY)?.activityInfo?.packageName == packageName
    } catch (e: Exception) {
        false
    }

    private fun refreshInfo() {
        val ssid = NetInfo.wifiSsid(this)
        val rssi = NetInfo.wifiRssi(this)
        val lines = listOf(
            "Модель: ${NetInfo.deviceModel()}",
            "Система: ${NetInfo.androidVersion()}",
            "Свободно в памяти: ${NetInfo.freeStorage()}",
            "IP-адрес: ${NetInfo.ipAddress() ?: "нет"}",
            "Подключение: ${NetInfo.connectionType(this)}",
            "Wi‑Fi сеть: ${ssid ?: "не видно (Android скрывает имя без доступа к геолокации)"}",
            "Сигнал Wi‑Fi: ${rssi?.let { "$it dBm" } ?: "—"}",
            "Версия приложения: ${BuildConfig.VERSION_NAME}",
            "Главный экран по умолчанию: ${if (isDefaultHome()) "да" else "нет"}",
            "Отчётов в очереди: ${Reporter.pendingCount(this)}",
            "Последняя автопроверка: ${prefs.lastAutoCheck.ifBlank { "ещё не было" }}",
        )
        deviceInfo.text = lines.joinToString("\n")
    }
}
