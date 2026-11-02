package ru.hotelkms.tv

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import kotlin.random.Random

/** 2048: стрелки пульта сдвигают плитки, ОК — продолжить/начать заново, «Назад» — к списку игр. */
class Game2048Activity : Activity() {

    private lateinit var view: Game2048View

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        view = Game2048View(this)
        setContentView(view)
        view.requestFocus()
    }

    override fun onResume() {
        super.onResume()
        view.requestFocus()
    }

    private class Game2048View(ctx: Context) : View(ctx) {
        private val n = 4
        private val prefs = ctx.getSharedPreferences("games", Context.MODE_PRIVATE)

        private enum class State { PLAYING, WON, OVER }

        private val grid = IntArray(n * n)
        private var state = State.PLAYING
        private var keepPlaying = false
        private var score = 0
        private var best = prefs.getInt("g2048_best", 0)

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val rect = RectF()

        init {
            isFocusable = true
            isFocusableInTouchMode = true
            requestFocus()
            restart()
        }

        private fun restart() {
            grid.fill(0)
            score = 0
            state = State.PLAYING
            keepPlaying = false
            addTile()
            addTile()
            invalidate()
        }

        private fun addTile() {
            val empty = ArrayList<Int>()
            for (i in grid.indices) if (grid[i] == 0) empty.add(i)
            if (empty.isEmpty()) return
            grid[empty[Random.nextInt(empty.size)]] = if (Random.nextInt(10) == 0) 4 else 2
        }

        /** dir: 0 влево, 1 вверх, 2 вправо, 3 вниз. */
        private fun slide(dir: Int) {
            if (state != State.PLAYING) return
            var moved = false
            var reached = false
            for (k in 0 until n) {
                val idx = IntArray(n) { t ->
                    when (dir) {
                        0 -> k * n + t
                        1 -> t * n + k
                        2 -> k * n + (n - 1 - t)
                        else -> (n - 1 - t) * n + k
                    }
                }
                val vals = ArrayList<Int>()
                for (t in 0 until n) if (grid[idx[t]] != 0) vals.add(grid[idx[t]])
                val out = ArrayList<Int>()
                var i = 0
                while (i < vals.size) {
                    if (i + 1 < vals.size && vals[i] == vals[i + 1]) {
                        val m = vals[i] * 2
                        out.add(m)
                        score += m
                        if (m == 2048) reached = true
                        i += 2
                    } else {
                        out.add(vals[i])
                        i++
                    }
                }
                for (t in 0 until n) {
                    val v = if (t < out.size) out[t] else 0
                    if (grid[idx[t]] != v) { grid[idx[t]] = v; moved = true }
                }
            }
            if (!moved) return
            addTile()
            if (score > best) {
                best = score
                prefs.edit().putInt("g2048_best", best).apply()
            }
            if (reached && !keepPlaying) state = State.WON
            else if (!canMove()) state = State.OVER
        }

        private fun canMove(): Boolean {
            for (y in 0 until n) for (x in 0 until n) {
                val v = grid[x + y * n]
                if (v == 0) return true
                if (x + 1 < n && grid[x + 1 + y * n] == v) return true
                if (y + 1 < n && grid[x + (y + 1) * n] == v) return true
            }
            return false
        }

        override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
            when (keyCode) {
                KeyEvent.KEYCODE_DPAD_LEFT -> slide(0)
                KeyEvent.KEYCODE_DPAD_UP -> slide(1)
                KeyEvent.KEYCODE_DPAD_RIGHT -> slide(2)
                KeyEvent.KEYCODE_DPAD_DOWN -> slide(3)
                KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_BUTTON_A -> {
                    if (event.repeatCount == 0) {
                        when (state) {
                            State.WON -> {
                                keepPlaying = true
                                state = if (canMove()) State.PLAYING else State.OVER
                            }
                            State.OVER -> restart()
                            State.PLAYING -> {}
                        }
                    }
                }
                else -> return super.onKeyDown(keyCode, event) // BACK и др. — как обычно
            }
            invalidate()
            return true
        }

        override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean = when (keyCode) {
            KeyEvent.KEYCODE_DPAD_UP, KeyEvent.KEYCODE_DPAD_DOWN, KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_RIGHT, KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_BUTTON_A -> true
            else -> super.onKeyUp(keyCode, event)
        }

        private fun tileColor(v: Int): Int = when (v) {
            0 -> 0xFF1B3560.toInt()
            2 -> 0xFFEEE4DA.toInt()
            4 -> 0xFFEDE0C8.toInt()
            8 -> 0xFFF2B179.toInt()
            16 -> 0xFFF59563.toInt()
            32 -> 0xFFF67C5F.toInt()
            64 -> 0xFFF65E3B.toInt()
            128 -> 0xFFEDCF72.toInt()
            256 -> 0xFFEDCC61.toInt()
            512 -> 0xFFEDC850.toInt()
            1024 -> 0xFFEDC53F.toInt()
            else -> 0xFFEDC22E.toInt()
        }

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawColor(0xFF0B1A33.toInt())
            val side = h * 0.84f
            val ox = (w - side) / 2f
            val oy = h * 0.12f + (h * 0.84f - side) / 2f
            val gap = side * 0.025f
            val cell = (side - gap * (n + 1)) / n

            // шапка
            paint.style = Paint.Style.FILL
            paint.color = 0xFFFFFFFF.toInt()
            paint.textSize = h * 0.07f
            paint.textAlign = Paint.Align.LEFT
            canvas.drawText("Счёт: $score", ox, h * 0.09f, paint)
            paint.textAlign = Paint.Align.RIGHT
            canvas.drawText("Рекорд: $best", ox + side, h * 0.09f, paint)

            paint.color = 0xFF10264A.toInt()
            rect.set(ox, oy, ox + side, oy + side)
            canvas.drawRoundRect(rect, gap * 2, gap * 2, paint)

            paint.textAlign = Paint.Align.CENTER
            for (y in 0 until n) for (x in 0 until n) {
                val v = grid[x + y * n]
                val left = ox + gap + x * (cell + gap)
                val top = oy + gap + y * (cell + gap)
                paint.color = tileColor(v)
                rect.set(left, top, left + cell, top + cell)
                canvas.drawRoundRect(rect, gap, gap, paint)
                if (v != 0) {
                    paint.color = if (v <= 4) 0xFF776E65.toInt() else 0xFFFFFFFF.toInt()
                    val s = v.toString()
                    paint.textSize = cell * when (s.length) { 1, 2 -> 0.5f; 3 -> 0.42f; else -> 0.34f }
                    val ty = top + cell / 2f - (paint.descent() + paint.ascent()) / 2f
                    canvas.drawText(s, left + cell / 2f, ty, paint)
                }
            }

            if (state != State.PLAYING) {
                paint.color = 0xD0000000.toInt()
                val bh = h * 0.3f
                canvas.drawRect(0f, h / 2f - bh / 2f, w, h / 2f + bh / 2f, paint)
                paint.color = 0xFFFFFFFF.toInt()
                paint.textAlign = Paint.Align.CENTER
                paint.textSize = h * 0.09f
                val title = if (state == State.WON) "Победа! (2048)" else "Игра окончена"
                canvas.drawText(title, w / 2f, h / 2f - h * 0.01f, paint)
                paint.textSize = h * 0.045f
                paint.color = 0xFFB8C7E0.toInt()
                val sub = if (state == State.WON) "Нажмите ОК, чтобы продолжить" else "Нажмите ОК, чтобы сыграть снова"
                canvas.drawText(sub, w / 2f, h / 2f + h * 0.08f, paint)
            }
        }
    }
}
