package ru.hotelkms.tv

import android.os.Handler
import android.os.Looper
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Фоновые потоки без сторонних библиотек. */
object Bg {
    /** Проверки скорости идут строго по одной, чтобы не мешать друг другу. */
    val tests: ExecutorService = Executors.newSingleThreadExecutor()

    /** Погода, отправка отчётов и прочие короткие запросы. */
    val io: ExecutorService = Executors.newFixedThreadPool(2)

    val main = Handler(Looper.getMainLooper())

    fun ui(block: () -> Unit) {
        main.post(block)
    }
}
