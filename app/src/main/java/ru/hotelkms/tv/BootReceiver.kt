package ru.hotelkms.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** После включения ТВ запускает процесс приложения, а с ним — автопроверку интернета. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        AutoChecker.start(context)
    }
}
