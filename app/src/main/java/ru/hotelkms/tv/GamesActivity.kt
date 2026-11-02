package ru.hotelkms.tv

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/** Список встроенных игр (управление пультом). */
class GamesActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(48), dp(48), dp(48), dp(32))
        }
        root.addView(TextView(this).apply {
            text = "Игры"
            textSize = 34f
            setTextColor(0xFFFFFFFF.toInt())
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })
        root.addView(TextView(this).apply {
            text = "Выберите игру и нажмите ОК. «Назад» — вернуться."
            textSize = 18f
            setTextColor(0xFFB8C7E0.toInt())
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = dp(24)
        })

        var first: View? = null
        val games = listOf(
            "Змейка" to SnakeActivity::class.java,
            "Тетрис" to TetrisActivity::class.java,
            "2048" to Game2048Activity::class.java
        )
        for ((name, cls) in games) {
            val b = Button(this).apply {
                text = name
                setBackgroundResource(R.drawable.tile_bg)
                setTextColor(0xFFFFFFFF.toInt())
                textSize = 26f
                isAllCaps = false
                isFocusable = true
                stateListAnimator = null
                setOnClickListener { startActivity(Intent(this@GamesActivity, cls)) }
                focusZoom()
            }
            root.addView(b, LinearLayout.LayoutParams(dp(360), dp(80)).apply { topMargin = dp(8) })
            if (first == null) first = b
        }
        setContentView(root)
        first?.requestFocus()
    }
}
