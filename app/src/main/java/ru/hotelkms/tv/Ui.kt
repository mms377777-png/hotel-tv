package ru.hotelkms.tv

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.view.View

fun Context.dp(v: Int): Int = (v * resources.displayMetrics.density + 0.5f).toInt()

/** Лёгкое увеличение элемента в фокусе — хорошо видно, куда «смотрит» пульт. */
fun View.focusZoom(scale: Float = 1.06f) {
    setOnFocusChangeListener { v, has ->
        val s = if (has) scale else 1f
        v.animate().scaleX(s).scaleY(s).setDuration(120).start()
    }
}

fun roundedColor(ctx: Context, color: Int, radiusDp: Int = 16): GradientDrawable =
    GradientDrawable().apply {
        setColor(color)
        cornerRadius = ctx.dp(radiusDp).toFloat()
    }
