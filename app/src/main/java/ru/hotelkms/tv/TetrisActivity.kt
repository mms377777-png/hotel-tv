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

/** Тетрис: ←/→ — сдвиг, ↑ — поворот, ↓ — ускорить, ОК — старт / мгновенное падение, «Назад» — к списку игр. */
class TetrisActivity : Activity() {

    private lateinit var view: TetrisView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        view = TetrisView(this)
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

    private class TetrisView(ctx: Context) : View(ctx) {
        private val cols = 10
        private val rows = 20
        private val prefs = ctx.getSharedPreferences("games", Context.MODE_PRIVATE)
        private val handler = Handler(Looper.getMainLooper())

        private enum class State { READY, RUNNING, OVER }

        // Фигуры: пары (x, y) в квадрате n x n; индекс цвета = номер + 1
        private val shapeSize = intArrayOf(4, 2, 3, 3, 3, 3, 3)
        private val shapes = arrayOf(
            intArrayOf(0, 1, 1, 1, 2, 1, 3, 1), // I
            intArrayOf(0, 0, 1, 0, 0, 1, 1, 1), // O
            intArrayOf(1, 0, 0, 1, 1, 1, 2, 1), // T
            intArrayOf(1, 0, 2, 0, 0, 1, 1, 1), // S
            intArrayOf(0, 0, 1, 0, 1, 1, 2, 1), // Z
            intArrayOf(0, 0, 0, 1, 1, 1, 2, 1), // J
            intArrayOf(2, 0, 0, 1, 1, 1, 2, 1)  // L
        )
        private val colors = intArrayOf(
            0xFF000000.toInt(),
            0xFF35D0E8.toInt(), 0xFFF2D13B.toInt(), 0xFFB36BE8.toInt(), 0xFF5BD66F.toInt(),
            0xFFE85B5B.toInt(), 0xFF4F7BE8.toInt(), 0xFFF2A93B.toInt()
        )

        private val board = IntArray(cols * rows)
        private var state = State.READY
        private var curType = 0
        private var cur = IntArray(8)
        private var px = 0
        private var py = 0
        private var nextType = Random.nextInt(7)
        private var score = 0
        private var lines = 0
        private var level = 1
        private var best = prefs.getInt("tetris_best", 0)

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val rect = RectF()

        private val tick = object : Runnable {
            override fun run() {
                if (state != State.RUNNING) return
                stepDown()
                invalidate()
                if (state == State.RUNNING) handler.postDelayed(this, delay())
            }
        }

        init {
            isFocusable = true
            isFocusableInTouchMode = true
            requestFocus()
        }

        private fun delay(): Long = maxOf(80L, 700L - (level - 1) * 60L)

        private fun start() {
            handler.removeCallbacks(tick)
            board.fill(0)
            score = 0; lines = 0; level = 1
            nextType = Random.nextInt(7)
            state = State.RUNNING
            spawn()
            if (state == State.RUNNING) handler.postDelayed(tick, delay())
            invalidate()
        }

        fun pause() {
            handler.removeCallbacks(tick)
            if (state == State.RUNNING) state = State.READY
            invalidate()
        }

        private fun spawn() {
            curType = nextType
            nextType = Random.nextInt(7)
            cur = shapes[curType].copyOf()
            px = (cols - shapeSize[curType]) / 2
            py = 0
            if (collides(cur, px, py)) gameOver()
        }

        private fun collides(c: IntArray, ax: Int, ay: Int): Boolean {
            var i = 0
            while (i < 8) {
                val x = c[i] + ax
                val y = c[i + 1] + ay
                if (x < 0 || x >= cols || y >= rows) return true
                if (y >= 0 && board[x + y * cols] != 0) return true
                i += 2
            }
            return false
        }

        private fun stepDown() {
            if (!collides(cur, px, py + 1)) py++ else lockPiece()
        }

        private fun lockPiece() {
            var i = 0
            while (i < 8) {
                val x = cur[i] + px
                val y = cur[i + 1] + py
                if (y >= 0) board[x + y * cols] = curType + 1
                i += 2
            }
            clearLines()
            if (state == State.RUNNING) spawn()
        }

        private fun clearLines() {
            var cleared = 0
            var y = rows - 1
            while (y >= 0) {
                var full = true
                for (x in 0 until cols) if (board[x + y * cols] == 0) { full = false; break }
                if (full) {
                    for (yy in y downTo 1) {
                        for (x in 0 until cols) board[x + yy * cols] = board[x + (yy - 1) * cols]
                    }
                    for (x in 0 until cols) board[x] = 0
                    cleared++
                } else {
                    y--
                }
            }
            if (cleared > 0) {
                val pts = when (cleared) { 1 -> 100; 2 -> 300; 3 -> 500; else -> 800 }
                score += pts * level
                lines += cleared
                level = lines / 10 + 1
                saveBest()
            }
        }

        private fun saveBest() {
            if (score > best) {
                best = score
                prefs.edit().putInt("tetris_best", best).apply()
            }
        }

        private fun gameOver() {
            state = State.OVER
            handler.removeCallbacks(tick)
            saveBest()
        }

        private fun move(d: Int) {
            if (state != State.RUNNING) return
            if (!collides(cur, px + d, py)) px += d
        }

        private fun rotate() {
            if (state != State.RUNNING || curType == 1) return
            val n = shapeSize[curType]
            val r = IntArray(8)
            var i = 0
            while (i < 8) {
                r[i] = n - 1 - cur[i + 1]
                r[i + 1] = cur[i]
                i += 2
            }
            for (kick in intArrayOf(0, -1, 1, -2, 2)) {
                if (!collides(r, px + kick, py)) {
                    cur = r
                    px += kick
                    return
                }
            }
        }

        private fun softDrop() {
            if (state != State.RUNNING) return
            handler.removeCallbacks(tick)
            if (!collides(cur, px, py + 1)) {
                py++
                score += 1
                saveBest()
            } else {
                lockPiece()
            }
            if (state == State.RUNNING) handler.postDelayed(tick, delay())
        }

        private fun hardDrop() {
            if (state != State.RUNNING) return
            handler.removeCallbacks(tick)
            var d = 0
            while (!collides(cur, px, py + 1)) { py++; d++ }
            score += d * 2
            lockPiece()
            saveBest()
            if (state == State.RUNNING) handler.postDelayed(tick, delay())
        }

        override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
            when (keyCode) {
                KeyEvent.KEYCODE_DPAD_LEFT -> move(-1)
                KeyEvent.KEYCODE_DPAD_RIGHT -> move(1)
                KeyEvent.KEYCODE_DPAD_UP -> rotate()
                KeyEvent.KEYCODE_DPAD_DOWN -> softDrop()
                KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_BUTTON_A -> {
                    if (event.repeatCount == 0) {
                        if (state == State.RUNNING) hardDrop() else start()
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

        override fun onDetachedFromWindow() {
            handler.removeCallbacks(tick)
            super.onDetachedFromWindow()
        }

        private fun drawCell(canvas: Canvas, x: Float, y: Float, cell: Float, color: Int) {
            paint.style = Paint.Style.FILL
            paint.color = color
            rect.set(x + cell * 0.05f, y + cell * 0.05f, x + cell * 0.95f, y + cell * 0.95f)
            canvas.drawRoundRect(rect, cell * 0.15f, cell * 0.15f, paint)
        }

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawColor(0xFF0B1A33.toInt())
            val cell = h * 0.92f / rows
            val bw = cell * cols
            val ox = (w - bw) / 2f
            val oy = (h - cell * rows) / 2f

            paint.style = Paint.Style.FILL
            paint.color = 0xFF10264A.toInt()
            canvas.drawRect(ox, oy, ox + bw, oy + cell * rows, paint)
            paint.color = 0xFF1B3560.toInt()
            for (x in 0..cols) canvas.drawRect(ox + x * cell - 1f, oy, ox + x * cell + 1f, oy + cell * rows, paint)
            for (y in 0..rows) canvas.drawRect(ox, oy + y * cell - 1f, ox + bw, oy + y * cell + 1f, paint)

            for (y in 0 until rows) for (x in 0 until cols) {
                val v = board[x + y * cols]
                if (v != 0) drawCell(canvas, ox + x * cell, oy + y * cell, cell, colors[v])
            }
            if (state == State.RUNNING) {
                var i = 0
                while (i < 8) {
                    val y = cur[i + 1] + py
                    if (y >= 0) drawCell(canvas, ox + (cur[i] + px) * cell, oy + y * cell, cell, colors[curType + 1])
                    i += 2
                }
            }

            // левая колонка: счёт
            val lx = ox - cell * 0.8f
            paint.textAlign = Paint.Align.RIGHT
            paint.color = 0xFFB8C7E0.toInt()
            paint.textSize = cell * 0.8f
            canvas.drawText("Счёт", lx, oy + cell * 1.5f, paint)
            canvas.drawText("Рекорд", lx, oy + cell * 5.0f, paint)
            canvas.drawText("Линии", lx, oy + cell * 8.5f, paint)
            canvas.drawText("Уровень", lx, oy + cell * 12.0f, paint)
            paint.color = 0xFFFFFFFF.toInt()
            paint.textSize = cell * 1.2f
            canvas.drawText("$score", lx, oy + cell * 2.9f, paint)
            canvas.drawText("$best", lx, oy + cell * 6.4f, paint)
            canvas.drawText("$lines", lx, oy + cell * 9.9f, paint)
            canvas.drawText("$level", lx, oy + cell * 13.4f, paint)

            // правая колонка: следующая фигура
            val rx = ox + bw + cell * 0.8f
            paint.textAlign = Paint.Align.LEFT
            paint.color = 0xFFB8C7E0.toInt()
            paint.textSize = cell * 0.8f
            canvas.drawText("Далее", rx, oy + cell * 1.5f, paint)
            val ns = shapes[nextType]
            var j = 0
            while (j < 8) {
                drawCell(canvas, rx + ns[j] * cell, oy + cell * 2.5f + ns[j + 1] * cell, cell, colors[nextType + 1])
                j += 2
            }
            paint.textSize = cell * 0.62f
            canvas.drawText("↑ поворот", rx, oy + cell * 15.5f, paint)
            canvas.drawText("↓ ускорить", rx, oy + cell * 16.5f, paint)
            canvas.drawText("ОК — сбросить", rx, oy + cell * 17.5f, paint)

            if (state != State.RUNNING) {
                paint.color = 0xC0000000.toInt()
                val bh = cell * 5f
                canvas.drawRect(ox, h / 2f - bh / 2f, ox + bw, h / 2f + bh / 2f, paint)
                paint.color = 0xFFFFFFFF.toInt()
                paint.textAlign = Paint.Align.CENTER
                paint.textSize = cell * 1.3f
                val title = if (state == State.OVER) "Игра окончена" else "Тетрис"
                canvas.drawText(title, w / 2f, h / 2f - cell * 0.3f, paint)
                paint.textSize = cell * 0.8f
                paint.color = 0xFFB8C7E0.toInt()
                val sub = if (state == State.OVER) "Нажмите ОК, чтобы сыграть снова" else "Нажмите ОК, чтобы начать"
                canvas.drawText(sub, w / 2f, h / 2f + cell * 1.4f, paint)
            }
        }
    }
}
