package ru.hotelkms.tv

/** Плитка на главном экране: название и список возможных пакетов (пробуются по порядку). */
data class AppTile(
    val title: String,
    val packages: List<String>,
    val isTvChannels: Boolean = false,
)

/**
 * Все настройки «по умолчанию» в одном месте.
 * Значения, которые меняет персонал (номер, гостиница, адреса), хранятся в [Prefs].
 */
object Config {
    const val DEFAULT_HOTEL_NAME = "Сити Центр"
    const val DEFAULT_GUEST_NAME = ""
    const val DEFAULT_PIN = "0000"

    /** Адрес для отчётов (Google Apps Script). Пусто — отчёты только пишутся в журнал (logcat). */
    const val DEFAULT_REPORT_URL = ""

    // Город: Комсомольск-на-Амуре
    const val CITY_LAT = 50.55
    const val CITY_LON = 137.01
    const val TIMEZONE = "Asia/Vladivostok"

    const val WEATHER_URL =
        "https://api.open-meteo.com/v1/forecast?latitude=$CITY_LAT&longitude=$CITY_LON" +
            "&current=temperature_2m,weather_code&timezone=Asia%2FVladivostok"
    const val WEATHER_REFRESH_MS = 30L * 60 * 1000

    // Проверка скорости
    const val DEFAULT_DOWNLOAD_URL = "https://speed.cloudflare.com/__down?bytes=25000000"
    const val DEFAULT_UPLOAD_URL = "https://speed.cloudflare.com/__up"
    const val DEFAULT_PING_URL = "https://speed.cloudflare.com/__down?bytes=0"

    const val PING_COUNT = 6
    const val FULL_DOWNLOAD_MAX_BYTES = 25_000_000L
    const val FULL_DOWNLOAD_MAX_MS = 10_000L
    const val FULL_UPLOAD_BYTES = 4_000_000L
    const val FULL_UPLOAD_MAX_MS = 10_000L
    const val LIGHT_DOWNLOAD_MAX_BYTES = 3_000_000L
    const val LIGHT_DOWNLOAD_MAX_MS = 8_000L

    /** Пороги вердикта по скорости загрузки, Мбит/с: зелёный ≥ GOOD, жёлтый ≥ OK, иначе красный. */
    const val GOOD_MBPS = 20.0
    const val OK_MBPS = 5.0

    // Автопроверка
    const val AUTO_CHECK_INTERVAL_MS = 15L * 60 * 1000
    const val AUTO_CHECK_FIRST_DELAY_MS = 2L * 60 * 1000

    /** Неотправленные отчёты копятся (на случай пропажи интернета), не больше этого числа. */
    const val MAX_PENDING_REPORTS = 50

    /**
     * Плитки приложений. Пакеты НУЖНО ПРОВЕРИТЬ на реальном телевизоре.
     * При изменении списка — обновить блок <queries> в AndroidManifest.xml.
     */
    val TILES = listOf(
        AppTile("ВК Видео", listOf("com.vk.vkvideo", "com.vk.tv")),
        AppTile("Rutube", listOf("ru.rutube.app")),
        AppTile("YouTube", listOf("com.google.android.youtube.tv")),
        AppTile("Кинопоиск", listOf("ru.kinopoisk", "ru.kinopoisk.tv")),
        AppTile("Wink", listOf("ru.rt.video.app.tv", "ru.rt.video.app.mobile")),
        AppTile("ТВ-каналы", listOf("com.google.android.tv", "com.android.tv"), isTvChannels = true),
    )
}
