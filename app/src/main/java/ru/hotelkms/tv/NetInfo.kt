package ru.hotelkms.tv

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.Locale

/** Сведения о сети и устройстве. Ничего не требует сверх ACCESS_WIFI_STATE / ACCESS_NETWORK_STATE. */
object NetInfo {

    @Suppress("DEPRECATION")
    private fun wifiInfo(ctx: Context): android.net.wifi.WifiInfo? = try {
        val wm = ctx.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        wm?.connectionInfo
    } catch (e: Exception) {
        null
    }

    /**
     * Имя Wi‑Fi сети. На Android 8.1+ без разрешения на геолокацию система
     * обычно отдаёт "<unknown ssid>" — тогда возвращаем null.
     */
    fun wifiSsid(ctx: Context): String? {
        if (!isWifi(ctx)) return null
        val raw = wifiInfo(ctx)?.ssid ?: return null
        val s = raw.trim().removePrefix("\"").removeSuffix("\"")
        if (s.isBlank() || s.equals("<unknown ssid>", ignoreCase = true) || s == "0x") return null
        return s
    }

    /** Уровень сигнала Wi‑Fi в dBm или null, если не по Wi‑Fi. */
    fun wifiRssi(ctx: Context): Int? {
        if (!isWifi(ctx)) return null
        val rssi = wifiInfo(ctx)?.rssi ?: return null
        return if (rssi <= -127 || rssi >= 0) null else rssi
    }

    private fun caps(ctx: Context): NetworkCapabilities? = try {
        val cm = ctx.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        cm.getNetworkCapabilities(cm.activeNetwork)
    } catch (e: Exception) {
        null
    }

    fun isWifi(ctx: Context): Boolean = caps(ctx)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

    fun connectionType(ctx: Context): String {
        val c = caps(ctx) ?: return "нет сети"
        return when {
            c.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi‑Fi"
            c.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "кабель (Ethernet)"
            else -> "другое"
        }
    }

    fun ipAddress(): String? = try {
        NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
            .filter { it.isUp && !it.isLoopback }
            .flatMap { it.inetAddresses.toList() }
            .firstOrNull { it is Inet4Address && !it.isLoopbackAddress }
            ?.hostAddress
    } catch (e: Exception) {
        null
    }

    fun freeStorage(): String = try {
        val st = StatFs(Environment.getDataDirectory().path)
        "${formatBytes(st.availableBytes)} из ${formatBytes(st.totalBytes)}"
    } catch (e: Exception) {
        "неизвестно"
    }

    private fun formatBytes(b: Long): String {
        val gb = b / 1_073_741_824.0
        return if (gb >= 1) String.format(Locale.US, "%.1f ГБ", gb)
        else String.format(Locale.US, "%.0f МБ", b / 1_048_576.0)
    }

    fun deviceModel(): String = "${Build.MANUFACTURER} ${Build.MODEL}".trim()

    fun androidVersion(): String = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

    /** Короткая строка для экрана проверки. */
    fun shortLine(ctx: Context): String {
        val parts = mutableListOf("Подключение: ${connectionType(ctx)}")
        wifiSsid(ctx)?.let { parts += "сеть «$it»" }
        wifiRssi(ctx)?.let { parts += "сигнал $it dBm" }
        return parts.joinToString(", ")
    }
}
