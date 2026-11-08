package ru.hotelkms.tv

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * 07.11.2026: постоянная служба, чтобы Android не выгружал процесс приложения, пока гость в другом приложении
 * или на тюнере (v108: на половине ТВ процесс был выгружен — сторож тюнера не работал бы).
 */
class TunerGuardService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            if (Build.VERSION.SDK_INT < 26) { TunerGuard.start(this); return }
            val nm = getSystemService(NotificationManager::class.java)
            nm?.createNotificationChannel(NotificationChannel(CH, "Служба экрана", NotificationManager.IMPORTANCE_MIN))
            val n = Notification.Builder(this, CH).setSmallIcon(android.R.drawable.ic_menu_info_details)
                .setContentTitle("Hotel TV").setOngoing(true).build()
            if (Build.VERSION.SDK_INT >= 34) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            else startForeground(1, n)
        } catch (t: Throwable) { Log.w("HotelTV", "TunerGuardService foreground: $t") }
        TunerGuard.start(this)
        NetTime.start(this)
        GuestCheck.start(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    companion object {
        private const val CH = "guard"
        fun start(ctx: Context) {
            if (Build.VERSION.SDK_INT < 26) { TunerGuard.start(ctx); return }
            try { ctx.startForegroundService(Intent(ctx, TunerGuardService::class.java)) }
            catch (t: Throwable) { Log.w("HotelTV", "TunerGuardService start: $t"); TunerGuard.start(ctx) }
        }
    }
}
