package ru.hotelkms.tv

import org.json.JSONObject
import kotlin.math.roundToInt

/** Погода из Open-Meteo (без ключа). Блокирующий вызов; при ошибке — null. */
object Weather {
    fun fetch(): String? = try {
        val json = JSONObject(Http.getText(Config.WEATHER_URL))
        val cur = json.getJSONObject("current")
        val t = cur.getDouble("temperature_2m").roundToInt()
        val code = cur.optInt("weather_code", -1)
        val sign = if (t > 0) "+" else ""
        val desc = describe(code)
        if (desc.isEmpty()) "$sign$t°" else "$sign$t°, $desc"
    } catch (e: Exception) {
        null
    }

    /** Коды погоды WMO → короткое описание по-русски. */
    fun describe(code: Int): String = when (code) {
        0 -> "ясно"
        1 -> "преимущественно ясно"
        2 -> "переменная облачность"
        3 -> "пасмурно"
        45, 48 -> "туман"
        51, 53, 55 -> "морось"
        56, 57 -> "ледяная морось"
        61 -> "небольшой дождь"
        63 -> "дождь"
        65 -> "сильный дождь"
        66, 67 -> "ледяной дождь"
        71 -> "небольшой снег"
        73 -> "снег"
        75 -> "сильный снег"
        77 -> "снежная крупа"
        80, 81 -> "ливень"
        82 -> "сильный ливень"
        85 -> "снегопад"
        86 -> "сильный снегопад"
        95 -> "гроза"
        96, 99 -> "гроза с градом"
        else -> ""
    }
}
