package ru.hotelkms.tv

import android.content.Context

/** Строка в журнал ТВ (Google Форма): «Гостиница;тип;номер;текст». */
object Journal {
    fun send(ctx: Context, type: String, text: String): Boolean {
        val p = Prefs(ctx)
        val h = p.hotelName
        val hotel = when {
            h.contains("Пушкин", true) -> "Pushkin"
            h.contains("Сити", true) || h.contains("City", true) -> "Siti"
            h.contains("Завод", true) -> "Zavodskaya"
            else -> h
        }
        return try { Http.postForm(Config.FORM_URL, mapOf(Config.FORM_ENTRY to "$hotel;$type;${p.room};$text")) } catch (t: Throwable) { false }
    }
}
