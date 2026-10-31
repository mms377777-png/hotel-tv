package ru.hotelkms.tv

import java.net.HttpURLConnection
import java.net.URL

object Http {
    private val UA = "HotelTV/" + BuildConfig.VERSION_NAME

    fun open(url: String, connectTimeoutMs: Int = 7000, readTimeoutMs: Int = 10000): HttpURLConnection {
        val c = URL(url).openConnection() as HttpURLConnection
        c.connectTimeout = connectTimeoutMs
        c.readTimeout = readTimeoutMs
        c.useCaches = false
        c.setRequestProperty("User-Agent", UA)
        return c
    }

    /** GET, возвращает тело ответа как строку. Бросает исключение при ошибке. */
    fun getText(url: String): String {
        val c = open(url)
        try {
            val code = c.responseCode
            if (code !in 200..299) throw java.io.IOException("HTTP $code")
            return c.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
        } finally {
            c.disconnect()
        }
    }

    /**
     * POST JSON. Возвращает true, если сервер принял запрос (2xx/3xx).
     * Google Apps Script отвечает 302 на POST — данные при этом уже записаны,
     * поэтому редирект не проходим и считаем его успехом.
     */
    fun postJson(url: String, json: String): Boolean {
        val c = open(url)
        try {
            c.instanceFollowRedirects = false
            c.requestMethod = "POST"
            c.doOutput = true
            val bytes = json.toByteArray(Charsets.UTF_8)
            c.setFixedLengthStreamingMode(bytes.size)
            c.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            c.outputStream.use { it.write(bytes) }
            val code = c.responseCode
            return code in 200..399
        } finally {
            c.disconnect()
        }
    }

    /** Добавляет параметр против кэширования. */
    fun noCache(url: String): String {
        val sep = if (url.contains('?')) '&' else '?'
        return "$url${sep}r=${System.nanoTime()}"
    }
}
