package com.gameshield.manager.core

import android.content.Context
import java.io.File

/**
 * Game Shield 模块桥接：所有功能都通过调用模块的 gs.sh 实现。
 * 本 App 不直接操作系统，只负责调用模块脚本并展示结果。
 */
object ModuleBridge {
    private const val GS = "/data/adb/modules/gs_guard/bin/gs.sh"
    private const val MODULE_DIR = "/data/adb/modules/gs_guard"
    private const val CONF = "/data/adb/gs_guard/config"
    const val ZIP_ASSET = "gs_guard-v1.0.0.zip"
    const val ZIP_NAME = "gs_guard-v1.0.0.zip"

    fun installed(): Boolean =
        SuExecutor.run("test -d $MODULE_DIR && test -f $GS && echo yes", 8000).output.contains("yes")

    private fun gs(vararg args: String): String {
        val r = SuExecutor.run("sh $GS ${args.joinToString(" ")}")
        return if (r.ok) r.output else "命令失败（退出码 ${r.exit}）\n${r.output}"
    }

    fun envRaw(): List<String> = SuExecutor.run("sh $GS env --raw").output.lines()

    fun gameOn(): String = gs("game", "on")
    fun gameOff(): String = gs("game", "off")
    fun gameStatus(): String = gs("game", "status")
    fun gamePreview(): String = gs("game", "preview")
    fun diagStart(): String = gs("diag", "start")
    fun diagStop(): String = gs("diag", "stop")
    fun diagStatus(): String = gs("diag", "status")
    fun diagReport(): String = gs("diag", "report")
    fun selfTest(): String = gs("self-test")
    fun log(n: Int = 100): String = gs("log", n.toString())
    fun findPkg(kw: String = "tencent"): String = gs("find-pkg", kw)

    fun loadConfig(): String {
        val r = SuExecutor.run("cat $CONF 2>/dev/null")
        return if (r.ok) r.output else "（读取失败: ${r.output}）"
    }

    fun saveConfig(content: String): String {
        val r = SuExecutor.runWithStdin("cat > $CONF && echo SAVED", content + "\n")
        return if (r.ok && r.output.contains("SAVED")) "配置已保存" else "保存失败: ${r.output}"
    }

    /**
     * 一键部署：把内置模块 zip 拷到下载目录，并尝试用 ksud 安装。
     * ksud 不可用时提示手动安装路径（KernelSU Manager）。
     */
    fun deployModule(context: Context): String {
        val cache = File(context.cacheDir, ZIP_NAME)
        return try {
            context.assets.open(ZIP_ASSET).use { input ->
                cache.outputStream().use { input.copyTo(it) }
            }
            val cp = SuExecutor.run(
                "mkdir -p /sdcard/Download && cp '${cache.absolutePath}' /sdcard/Download/$ZIP_NAME && " +
                    "chmod 664 /sdcard/Download/$ZIP_NAME && echo COPIED"
            )
            if (!cp.output.contains("COPIED")) return "拷贝到下载目录失败: ${cp.output}"
            val ksud = SuExecutor.run("ksud module install /sdcard/Download/$ZIP_NAME 2>&1", 60_000)
            if (ksud.ok) {
                "✓ 模块安装命令执行成功，请重启设备生效\n\n${ksud.output}"
            } else {
                "✓ 模块包已放入 /sdcard/Download/$ZIP_NAME\n\n" +
                    "ksud 自动安装不可用或失败，请手动安装：\n" +
                    "KernelSU Manager → 模块 → 从本地安装 → 选择该 zip\n\n" +
                    "（详细信息）${ksud.output}"
            }
        } catch (e: Exception) {
            "部署失败: ${e.message}"
        }
    }
}
