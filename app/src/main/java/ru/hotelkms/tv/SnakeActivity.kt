package ru.hotelkms.tv

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.View
import kotlin.random.Random

/** Змейка: управление стрелками пульта, ОК — старт/рестарт, «Назад» — к списку игр. */
class SnakeActivity : Activity() {

    private lateinit var view: SnakeView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        view = SnakeView(this)
        setContentView(view)
        view.requestFocus()
    }

    override fun onResume() {
        super.onResume()
        view.requestFocus()
    }

    override fun onPause() {
        super.onPause()
        view.pause()
    }

    private class SnakeView(ctx: Context) : View(ctx) {
        private val cols = 32
        private val rows = 18
        private val prefs = ctx.getSharedPreferences("games", Context.MODE_PRIVATE)
        private val handler = Handler(Looper.getMainLooper())

        private enum class State { READY, RUNNING, OVER }

        private var state = State.READY
        private val body = ArrayList<Int>() // x + y*cols, голова — последняя
        private var dx = 1
        private var dy = 0
        private var pendDx = 1
        private var pendDy = 0
        private var food = 0
        private var score = 0
        private var best = prefs.getInt("snake_best", 0)

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val rect = RectF()

        private val tick = object : Runnable {
            override fun run() {
                if (state != State.RUNNING) return
                step()
                invalidate()
                if (state == State.RUNNING) handler.postDelayed(this, delay())
            }
        }

        init {
            isFocusable = true
            isFocusableInTouchMode = true
            requestFocus()
            reset()
        }

        private fun delay(): Long = maxOf(70L, 170L - score * 3L)

        private fun reset() {
            body.clear()
            val y = rows / 2
            for (x in 3..5) body.add(x + y * cols)
            dx = 1; dy = 0; pendDx = 1; pendDy = 0
            score = 0
            placeFood()
        }

        private fun placeFood() {
            if (body.size >= cols * rows) return
            var c: Int
            do { c = Random.nextInt(cols * rows) } while (body.contains(c))
            food = c
        }

        private fun start() {
            handler.removeCallbacks(tick)
            reset()
            state = State.RUNNING
            handler.postDelayed(tick, delay())
            invalidate()
        }

        fun pause() {
            handler.removeCallbacks(tick)
            if (state == State.RUNNING) state = State.READY
            invalidate()
        }

        private fun step() {
            dx = pendDx; dy = pendDy
            val head = body.last()
            val nx = head % cols + dx
            val ny = head / cols + dy
            if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) { gameOver(); return }
            val n = nx + ny * cols
            val eat = n == food
            // хвост освободится, если не едим
            val limit = if (eat) body.size else body.size - 1
            for (i in 0 until limit) if (body[i] == n) { gameOver(); return }
            body.add(n)
            if (eat) {
                score++
                placeFood()
            } else {
                body.removeAt(0)
            }
        }

        private fun gameOver() {
            state = State.OVER
            if (score > best) {
                best = score
                prefs.edit().putInt("snake_best", best).apply()
            }
        }

        override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
            when (keyCode) {
                KeyEvent.KEYCODE_DPAD_UP -> turn(0, -1)
                KeyEvent.KEYCODE_DPAD_DOWN -> turn(0, 1)
                KeyEvent.KEYCODE_DPAD_LEFT -> turn(-1, 0)
                KeyEvent.KEYCODE_DPAD_RIGHT -> turn(1, 0)
                KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_BUTTON_A -> {
                    if (event.repeatCount == 0 && state != State.RUNNING) start()
                }
                else -> return super.onKeyDown(keyCode, event) // BACK и др. — как обычно
            }
            return true
        }

        override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean = when (keyCode) {
            KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN, KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_RIGHT, KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_BUTTON_A -> true
            else -> super.onKeyUp(keyCode, event)
        }

        private fun turn(ndx: Int, ndy: Int) {
            if (state != State.RUNNING) return
            // нельзя развернуться на 180° относительно последнего сделанного шага
            if (ndx == -dx && ndy == -dy) return
            pendDx = ndx; pendDy = ndy
        }

        override fun onDetachedFromWindow() {
            handler.removeCallbacks(tick)
            super.onDetachedFromWindow()
        }

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawColor(0xFF0B1A33.toInt())
            val cell = minOf(w / cols, h / rows)
            val ox = (w - cell * cols) / 2f
            val oy = (h - cell * rows) / 2f

            paint.style = Paint.Style.FILL
            paint.color = 0xFF10264A.toInt()
            canvas.drawRect(ox, oy, ox + cell * cols, oy + cell * rows, paint)

            // еда
            paint.color = 0xFFF2A93B.toInt()
            cellRect(food, ox, oy, cell, 0.15f)
            canvas.drawOval(rect, paint)

            // змейка
            for ((i, c) in body.withIndex()) {
                paint.color = if (i == body.size - 1) 0xFF7CF29A.toInt() else 0xFF3FBF6A.toInt()
                cellRect(c, ox, oy, cell, 0.06f)
                canvas.drawRoundRect(rect, cell * 0.2f, cell * 0.2f, paint)
            }

            // шапка
            paint.color = 0xFFFFFFFF.toInt()
            paint.textSize = cell * 0.9f
            paint.textAlign = Paint.Align.LEFT
            canvas.drawText("Счёт: $score", ox + cell * 0.5f, oy + cell * 1.2f, paint)
            paint.textAlign = Paint.Align.RIGHT
            canvas.drawText("Рекорд: $best", ox + cell * cols - cell * 0.5f, oy + cell * 1.2f, paint)

            if (state != State.RUNNING) {
                paint.color = 0xB0000000.toInt()
                val bh = cell * 5f
                canvas.drawRect(ox, h / 2f - bh / 2f, ox + cell * cols, h / 2f + bh / 2f, paint)
                paint.color = 0xFFFFFFFF.toInt()
                paint.textAlign = Paint.Align.CENTER
                paint.textSize = cell * 1.6f
                val title = if (state == State.OVER) "Игра окончена" else "Змейка"
                canvas.drawText(title, w / 2f, h / 2f - cell * 0.4f, paint)
                paint.textSize = cell * 1.0f
                paint.color = 0xFFB8C7E0.toInt()
                canvas.drawText("Нажмите ОК, чтобы начать", w / 2f, h / 2f + cell * 1.4f, paint)
            }
        }

        private fun cellRect(c: Int, ox: Float, oy: Float, cell: Float, inset: Float) {
            val x = ox + (c % cols) * cell
            val y = oy + (c / cols) * cell
            rect.set(x + cell * inset, y + cell * inset, x + cell * (1 - inset), y + cell * (1 - inset))
        }
    }
}
