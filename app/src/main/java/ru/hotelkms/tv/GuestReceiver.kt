package ru.hotelkms.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Base64

/**
 * Имя гостя из 1С:Отель. Стойка гостиницы присылает по adb:
 * am broadcast -n ru.hotelkms.tv/.GuestReceiver --es b64 <имя в UTF-8, base64>   («-» — гостя нет)
 * Приветствие на экране обновится само (читается при каждом тике часов).
 */
class GuestReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val b64 = intent?.getStringExtra("b64") ?: return
        val name = if (b64 == "-") "" else try {
            String(Base64.decode(b64, Base64.DEFAULT), Charsets.UTF_8).trim()
        } catch (e: Exception) {
            return
        }
        Prefs(context).guestName = name.take(60)
        resultData = "ok"
    }
}
