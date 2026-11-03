package ru.hotelkms.tv

import org.json.JSONObject
import kotlin.math.roundToInt

/** Погода из Open-Meteo (без ключа). Блокирующий вызов; при ошибке — null. */
object Weather {
    fun fetch(): String? = openMeteo() ?: metNo() ?: wttr()

    private fun fmt(t: Int, desc: String): String {
        val sign = if (t > 0) "+" else ""
        return if (desc.isEmpty()) "$sign$t°" else "$sign$t°, $desc"
    }

    private fun openMeteo(): String? = try {
        val cur = JSONObject(Http.getText(Config.WEATHER_URL)).getJSONObject("current")
        fmt(cur.getDouble("temperature_2m").roundToInt(), describe(cur.optInt("weather_code", -1)))
    } catch (e: Exception) { null }

    /** Норвежский метеоинститут (yr.no). */
    private fun metNo(): String? = try {
        val ts = JSONObject(Http.getText(Config.WEATHER_URL_METNO))
            .getJSONObject("properties").getJSONArray("timeseries").getJSONObject(0).getJSONObject("data")
        val t = ts.getJSONObject("instant").getJSONObject("details").getDouble("air_temperature").roundToInt()
        val sym = ts.optJSONObject("next_1_hours")?.optJSONObject("summary")?.optString("symbol_code") ?: ""
        fmt(t, describeSymbol(sym))
    } catch (e: Exception) { null }

    private fun wttr(): String? = try {
        val cur = JSONObject(Http.getText(Config.WEATHER_URL_WTTR)).getJSONArray("current_condition").getJSONObject(0)
        fmt(cur.getString("temp_C").toInt(), "")
    } catch (e: Exception) { null }

    private fun describeSymbol(s: String): String = when {
        s.startsWith("clearsky") -> "ясно"
        s.startsWith("fair") -> "преимущественно ясно"
        s.startsWith("partlycloudy") -> "переменная облачность"
        s.startsWith("cloudy") -> "пасмурно"
        s.startsWith("fog") -> "туман"
        s.contains("thunder") -> "гроза"
        s.contains("sleet") -> "мокрый снег"
        s.contains("heavysnow") -> "сильный снег"
        s.contains("lightsnow") -> "небольшой снег"
        s.contains("snow") -> "снег"
        s.contains("heavyrain") -> "сильный дождь"
        s.contains("lightrain") -> "небольшой дождь"
        s.contains("rain") -> "дождь"
        else -> ""
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
