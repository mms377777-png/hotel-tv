package ru.hotelkms.tv

import android.app.Application

class HotelApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AutoChecker.start(this)
    }
}
