package ru.hotelkms.tv

import android.app.Activity
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.LayerDrawable
import java.io.File

/**
 * Фон главного экрана — фото с сайта гостиницы (набережная Амура), затемнённое для читаемости.
 * Картинка скачивается один раз и хранится в памяти приложения; без интернета — прежний синий фон.
 */
object Backdrop {
    private fun file(a: Activity) = File(a.filesDir, "backdrop.img")

    fun apply(a: Activity) {
        val f = file(a)
        if (f.length() > 10_000) show(a, f)
        if (f.length() > 10_000 && System.currentTimeMillis() - f.lastModified() < 7L * 24 * 3600 * 1000) return
        Bg.io.execute {
            try {
                val c = Http.open(Config.BACKDROP_URL, 8000, 30000)
                try {
                    if (c.responseCode !in 200..299) return@execute
                    val tmp = File(a.filesDir, "backdrop.tmp")
                    c.inputStream.use { inp -> tmp.outputStream().use { inp.copyTo(it) } }
                    if (tmp.length() > 10_000 && tmp.renameTo(f)) Bg.ui { if (!a.isFinishing) show(a, f) }
                } finally { c.disconnect() }
            } catch (e: Exception) { /* остаётся прежний фон */ }
        }
    }

    private fun show(a: Activity, f: File) {
        val opts = BitmapFactory.Options().apply { inSampleSize = 1 }
        val bmp = BitmapFactory.decodeFile(f.path, opts) ?: return
        val photo = BitmapDrawable(a.resources, bmp).apply { setFilterBitmap(true) }
        val dim: Drawable = ColorDrawable(Color.argb(150, 8, 18, 40))
        a.window.setBackgroundDrawable(CenterCrop(photo, dim))
    }

    /** Фото «по размеру экрана с обрезкой» + затемнение поверх. */
    private class CenterCrop(private val photo: BitmapDrawable, dim: Drawable) : LayerDrawable(arrayOf(photo, dim)) {
        override fun onBoundsChange(b: android.graphics.Rect) {
            val bw = photo.bitmap.width.toFloat(); val bh = photo.bitmap.height.toFloat()
            val s = maxOf(b.width() / bw, b.height() / bh)
            val w = (bw * s).toInt(); val h = (bh * s).toInt()
            val l = b.left + (b.width() - w) / 2; val t = b.top + (b.height() - h) / 2
            photo.setBounds(l, t, l + w, t + h)
            getDrawable(1).bounds = b
        }
    }
}
