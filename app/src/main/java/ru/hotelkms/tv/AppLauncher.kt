package ru.hotelkms.tv

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Drawable
import android.media.tv.TvContract
import android.net.Uri
import android.provider.Settings
import android.util.Log
import android.widget.Toast

/** Запуск приложений по имени пакета с запасными вариантами. */
object AppLauncher {

    private fun launchIntent(ctx: Context, pkg: String): Intent? {
        val pm = ctx.packageManager
        return try {
            pm.getLeanbackLaunchIntentForPackage(pkg) ?: pm.getLaunchIntentForPackage(pkg)
        } catch (e: Exception) {
            null
        }
    }

    /** Первый установленный пакет из списка плитки. */
    fun installedPackage(ctx: Context, tile: AppTile): String? =
        tile.packages.firstOrNull { launchIntent(ctx, it) != null }

    /** Баннер или иконка установленного приложения (для плитки). */
    fun icon(ctx: Context, tile: AppTile): Drawable? {
        val pkg = installedPackage(ctx, tile) ?: return null
        return try {
            val pm = ctx.packageManager
            pm.getApplicationBanner(pkg) ?: pm.getApplicationIcon(pkg)
        } catch (e: Exception) {
            null
        }
    }

    fun launch(ctx: Context, tile: AppTile) {
        for (pkg in tile.packages) {
            val i = launchIntent(ctx, pkg) ?: continue
            if (tryStart(ctx, i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))) return
        }

        if (tile.isTvChannels) {
            val tv = Intent(Intent.ACTION_VIEW, TvContract.Channels.CONTENT_URI)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (tryStart(ctx, tv)) return
            if (tryStart(ctx, Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))) return
        } else {
            val first = tile.packages.firstOrNull()
            if (first != null) {
                val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$first"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (tryStart(ctx, market)) {
                    Toast.makeText(ctx, "«${tile.title}» не установлено — откроем Google Play", Toast.LENGTH_LONG).show()
                    return
                }
            }
        }
        Toast.makeText(ctx, "Приложение «${tile.title}» не установлено. Обратитесь на ресепшен.", Toast.LENGTH_LONG).show()
    }

    private fun tryStart(ctx: Context, i: Intent): Boolean = try {
        ctx.startActivity(i)
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: SecurityException) {
        Log.w(SpeedTest.TAG, "launch denied: ${e.message}")
        false
    }
}
