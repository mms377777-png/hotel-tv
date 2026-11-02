package ru.hotelkms.tv

import android.app.Application

class HotelApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AdbKeeper.ensure(this)
        AutoChecker.start(this)
    }
}
