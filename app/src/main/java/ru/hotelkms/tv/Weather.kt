package ru.hotelkms.tv

import org.json.JSONObject
import kotlin.math.roundToInt

/** Погода из Open-Meteo (без ключа). Блокирующий вызов; при ошибке — null. */
object Weather {
    fun fetch(): String? = openMeteo() ?: metNo() ?: wttr()

    private fun deg(t: Int): String = when {
        t > 0 -> "+$t°"
        t < 0 -> "\u2212${-t}°"
        else -> "0°"
    }

    /** «−7°, переменная облачность» и второй строкой «сегодня от −12° до −3°». */
    private fun fmt(t: Int, desc: String, min: Int? = null, max: Int? = null): String {
        val now = if (desc.isEmpty()) deg(t) else "${deg(t)}, $desc"
        return if (min != null && max != null) "$now\nсегодня от ${deg(min)} до ${deg(max)}" else now
    }

    private fun openMeteo(): String? = try {
        val json = JSONObject(Http.getText(Config.WEATHER_URL))
        val cur = json.getJSONObject("current")
        val daily = json.optJSONObject("daily")
        val min = daily?.optJSONArray("temperature_2m_min")?.optDouble(0)?.takeIf { !it.isNaN() }?.roundToInt()
        val max = daily?.optJSONArray("temperature_2m_max")?.optDouble(0)?.takeIf { !it.isNaN() }?.roundToInt()
        fmt(cur.getDouble("temperature_2m").roundToInt(), describe(cur.optInt("weather_code", -1)), min, max)
    } catch (e: Exception) { null }

    /** Норвежский метеоинститут (yr.no). */
    private fun metNo(): String? = try {
        val arr = JSONObject(Http.getText(Config.WEATHER_URL_METNO))
            .getJSONObject("properties").getJSONArray("timeseries")
        val ts = arr.getJSONObject(0).getJSONObject("data")
        val t = ts.getJSONObject("instant").getJSONObject("details").getDouble("air_temperature").roundToInt()
        val sym = ts.optJSONObject("next_1_hours")?.optJSONObject("summary")?.optString("symbol_code") ?: ""
        val next24 = (0 until minOf(24, arr.length())).map {
            arr.getJSONObject(it).getJSONObject("data").getJSONObject("instant").getJSONObject("details").getDouble("air_temperature")
        }
        fmt(t, describeSymbol(sym), next24.minOrNull()?.roundToInt(), next24.maxOrNull()?.roundToInt())
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
