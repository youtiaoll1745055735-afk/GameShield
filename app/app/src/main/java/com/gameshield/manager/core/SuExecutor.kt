package com.gameshield.manager.core

import java.util.concurrent.TimeUnit

data class SuResult(val exit: Int, val output: String) {
    val ok: Boolean get() = exit == 0
}

/**
 * 通过 KernelSU/Magisk 的 su 执行 root 命令。
 * 无第三方依赖，ProcessBuilder 直连 su -c。
 */
object SuExecutor {
    private const val TIMEOUT_MS = 30_000L

    fun run(cmd: String, timeoutMs: Long = TIMEOUT_MS): SuResult {
        return try {
            val p = ProcessBuilder("su", "-c", cmd)
                .redirectErrorStream(true)
                .start()
            val done = p.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!done) {
                p.destroyForcibly()
                return SuResult(-1, "命令超时（${timeoutMs / 1000}s），已强制结束")
            }
            val out = p.inputStream.bufferedReader().readText().trim()
            SuResult(p.exitValue(), out)
        } catch (e: Exception) {
            SuResult(-1, "su 执行失败: ${e.message}\n未检测到 Root / KernelSU？请确认已授权本应用。")
        }
    }

    /** 带 stdin 写入的命令（用于写配置文件） */
    fun runWithStdin(cmd: String, input: String, timeoutMs: Long = TIMEOUT_MS): SuResult {
        return try {
            val p = ProcessBuilder("su", "-c", cmd)
                .redirectErrorStream(true)
                .start()
            p.outputStream.bufferedWriter().use {
                it.write(input)
                it.flush()
            }
            val done = p.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!done) {
                p.destroyForcibly()
                return SuResult(-1, "命令超时（${timeoutMs / 1000}s）")
            }
            SuResult(p.exitValue(), p.inputStream.bufferedReader().readText().trim())
        } catch (e: Exception) {
            SuResult(-1, "su 执行失败: ${e.message}")
        }
    }

    /** 检测 su 是否可用且当前为 root */
    fun suAvailable(): Boolean {
        val r = run("id -u", 8000)
        return r.ok && r.output == "0"
    }
}
