package com.gameshield.manager.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gameshield.manager.core.ModuleBridge
import com.gameshield.manager.core.SuExecutor
import com.gameshield.manager.data.model.EnvItem
import com.gameshield.manager.data.model.EnvParser
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class AppViewModel : ViewModel() {

    var suOk by mutableStateOf<Boolean?>(null); private set
    var moduleInstalled by mutableStateOf<Boolean?>(null); private set

    var envItems by mutableStateOf<List<EnvItem>>(emptyList()); private set
    var envLoading by mutableStateOf(false); private set

    var gameStatus by mutableStateOf(""); private set
    var gameOutput by mutableStateOf(""); private set
    var diagStatus by mutableStateOf(""); private set
    var diagOutput by mutableStateOf(""); private set

    var configText by mutableStateOf(""); private set
    var configSaved by mutableStateOf(false); private set

    var busy by mutableStateOf(false); private set
    var deployOutput by mutableStateOf(""); private set

    init {
        checkEnvironment()
    }

    fun checkEnvironment() {
        viewModelScope.launch(Dispatchers.IO) {
            suOk = SuExecutor.suAvailable()
            moduleInstalled = ModuleBridge.installed()
            if (moduleInstalled == true) {
                refreshEnv()
                refreshGameStatus()
                refreshDiagStatus()
                loadConfig()
            }
        }
    }

    fun refreshEnv() {
        viewModelScope.launch(Dispatchers.IO) {
            envLoading = true
            envItems = EnvParser.parse(ModuleBridge.envRaw())
            envLoading = false
        }
    }

    fun refreshGameStatus() {
        viewModelScope.launch(Dispatchers.IO) { gameStatus = ModuleBridge.gameStatus() }
    }

    fun refreshDiagStatus() {
        viewModelScope.launch(Dispatchers.IO) { diagStatus = ModuleBridge.diagStatus() }
    }

    fun loadConfig() {
        viewModelScope.launch(Dispatchers.IO) {
            val c = ModuleBridge.loadConfig()
            if (!c.startsWith("（读取失败")) configText = c
        }
    }

    private fun runIo(label: String, block: () -> String) {
        viewModelScope.launch(Dispatchers.IO) {
            busy = true
            gameOutput = "[$label]\n" + block()
            busy = false
        }
    }

    fun gameOn() = runIo("开启游戏兼容模式") { ModuleBridge.gameOn().also { refreshGameStatus() } }
    fun gameOff() = runIo("关闭并恢复") { ModuleBridge.gameOff().also { refreshGameStatus() } }
    fun gamePreview() = runIo("管理范围预览") { ModuleBridge.gamePreview() }
    fun diagStart() = runIo("开始诊断") { ModuleBridge.diagStart().also { refreshDiagStatus() } }
    fun diagStop() = runIo("停止诊断") { ModuleBridge.diagStop().also { refreshDiagStatus() } }
    fun diagReport() = runIo("诊断报告") { ModuleBridge.diagReport() }
    fun selfTest() = runIo("模块自检") { ModuleBridge.selfTest() }
    fun findPkg() = runIo("查找游戏包名") { ModuleBridge.findPkg("tencent") }
    fun viewLog() = runIo("最近日志") { ModuleBridge.log(120) }

    fun saveConfig() {
        viewModelScope.launch(Dispatchers.IO) {
            busy = true
            configSaved = false
            gameOutput = ModuleBridge.saveConfig(configText)
            configSaved = gameOutput?.contains("已保存") == true
            busy = false
        }
    }

    fun deployModule(context: android.content.Context) {
        viewModelScope.launch(Dispatchers.IO) {
            busy = true
            deployOutput = ModuleBridge.deployModule(context)
            checkEnvironment()
            busy = false
        }
    }

    fun updateConfigText(t: String) { configText = t }
}
