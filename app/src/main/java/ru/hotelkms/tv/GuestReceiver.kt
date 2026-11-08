package ru.hotelkms.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Base64

/**
 * Имя гостя из 1С:Отель. Стойка гостиницы присылает по adb (текст в UTF-8, base64):
 *  • весь список гостиницы: am broadcast -n ru.hotelkms.tv/.GuestReceiver --es map <base64 строк «номер<TAB>Имя Отчество»>
 *    ТВ сам выбирает строку своего номера (номер задан в служебном меню);
 *  • одно имя напрямую:     am broadcast -n ru.hotelkms.tv/.GuestReceiver --es b64 <base64 имени>  («-» — очистить).
 * Ответ (result data): «OUT» — прежний гость выехал или сменился (стойке пора чистить учётки), «OK» — без смены выезда,
 * «NOROOM» — на ТВ не задан номер. Приветствие на экране обновится само (читается при каждом тике часов).
 */
class GuestReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        intent ?: return
        val prefs = Prefs(context)
        val name: String = when {
            intent.hasExtra("map") -> {
                val room = norm(prefs.room)
                if (room.isEmpty()) { resultData = "NOROOM"; return }
                val text = decode(intent.getStringExtra("map")) ?: return
                text.lineSequence()
                    .map { it.split('\t', limit = 2) }
                    .firstOrNull { it.size == 2 && norm(it[0]) == room }
                    ?.get(1)?.trim() ?: ""
            }
            intent.hasExtra("b64") -> {
                val b = intent.getStringExtra("b64") ?: return
                if (b == "-") "" else decode(b)?.trim() ?: return
            }
            else -> return
        }.take(60)
        // 08.11.2026: имя могло уже снять само приложение (GuestCheck) — для ответа стойке берём его
        val old = prefs.guestName.trim().ifEmpty { prefs.guestCleared.trim() }
        prefs.guestCleared = ""
        prefs.guestName = name
        resultData = if (old.isNotEmpty() && old != name) "OUT" else "OK"
    }

    private fun decode(b64: String?): String? {
        if (b64 == null) return null
        return try {
            String(Base64.decode(b64, Base64.DEFAULT), Charsets.UTF_8)
        } catch (e: Exception) { null }
    }

    /** «№ 305», «305 », «0305» → «305»; нецифровые названия сравниваем как есть без регистра. */
    private fun norm(s: String): String {
        val t = s.trim()
        val d = t.filter { it.isDigit() }.trimStart('0')
        return if (d.isNotEmpty()) d else t.lowercase()
    }
}
