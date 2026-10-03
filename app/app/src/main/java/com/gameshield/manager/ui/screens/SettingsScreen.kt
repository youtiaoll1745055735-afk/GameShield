package com.gameshield.manager.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.FileDownload
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gameshield.manager.ui.AppViewModel
import com.gameshield.manager.ui.theme.StudioColors

@Composable
fun SettingsScreen(vm: AppViewModel) {
    val context = LocalContext.current
    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("设置与部署", color = StudioColors.TextPrimary, fontSize = 16.sp)
        }
        // 环境状态卡片
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    StatusRow("Root / KernelSU", vm.suOk)
                    StatusRow("Game Shield 模块", vm.moduleInstalled)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Button(
                            onClick = { vm.checkEnvironment() },
                            colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Surface2),
                        ) { Text("重新检查", color = StudioColors.Accent, fontSize = 13.sp) }
                    }
                }
            }
        }
        // 一键部署
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text("一键部署模块", color = StudioColors.Accent, fontSize = 13.sp)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "把内置模块包（gs_guard-v1.0.0.zip）拷贝到下载目录，并尝试 ksud 自动安装。装完需重启。",
                        color = StudioColors.TextSecondary,
                        fontSize = 12.sp,
                    )
                    Spacer(Modifier.height(8.dp))
                    Button(
                        onClick = { vm.deployModule(context) },
                        colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Accent),
                        enabled = !vm.busy,
                    ) {
                        Icon(Icons.Default.FileDownload, null, Modifier.size(18.dp), tint = StudioColors.BgDark)
                        Text("  部署模块", color = StudioColors.BgDark, fontSize = 13.sp)
                    }
                    if (vm.deployOutput.isNotEmpty()) {
                        Spacer(Modifier.height(8.dp))
                        Text(
                            vm.deployOutput,
                            color = StudioColors.TextPrimary,
                            fontSize = 11.5.sp,
                            fontFamily = FontFamily.Monospace,
                            modifier = Modifier
                                .background(StudioColors.BgDark, RoundedCornerShape(8.dp))
                                .padding(10.dp),
                        )
                    }
                }
            }
        }
        // 配置编辑
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text("模块配置（/data/adb/gs_guard/config）", color = StudioColors.Accent, fontSize = 13.sp)
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = vm.configText,
                        onValueChange = { vm.updateConfigText(it) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(260.dp),
                        textStyle = androidx.compose.ui.text.TextStyle(
                            fontSize = 11.5.sp,
                            fontFamily = FontFamily.Monospace,
                            color = StudioColors.TextPrimary,
                        ),
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Button(
                            onClick = { vm.loadConfig() },
                            colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Surface2),
                        ) { Text("重新读取", color = StudioColors.Accent, fontSize = 13.sp) }
                        Button(
                            onClick = { vm.saveConfig() },
                            colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Accent),
                        ) { Text("保存配置", color = StudioColors.BgDark, fontSize = 13.sp) }
                    }
                    if (vm.configSaved) {
                        Spacer(Modifier.height(6.dp))
                        Text("✓ 已保存", color = StudioColors.Green, fontSize = 12.sp)
                    }
                }
            }
        }
        // 工具
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("模块自检", StudioColors.Surface2, vm::selfTest, Modifier.weight(1f), Icons.Default.CheckCircle)
                ActionButton("查找游戏包名", StudioColors.Surface2, vm::findPkg, Modifier.weight(1f), Icons.Default.Info)
            }
        }
        item { OutputCard("工具输出", vm.gameOutput) }
        // 边界声明
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Error, null, Modifier.size(16.dp), tint = StudioColors.Warning)
                        Text(" 边界声明", color = StudioColors.Warning, fontSize = 13.sp)
                    }
                    Spacer(Modifier.height(6.dp))
                    Text(
                        "1. 模块停用需重启才完全生效（机制限制）。\n" +
                            "2. 无法隐藏解锁/Root 状态，也不提供任何防封保护。\n" +
                            "3. 诊断无法定位冻结的确切原因，只提供关联性提示。\n" +
                            "4. 不修改游戏文件/内存，不注入，不自动操作。",
                        color = StudioColors.TextSecondary,
                        fontSize = 11.5.sp,
                    )
                }
            }
        }
    }
}

@Composable
private fun StatusRow(label: String, ok: Boolean?) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        val (icon, color, text) = when (ok) {
            true -> Triple(Icons.Default.CheckCircle, StudioColors.Green, "正常")
            false -> Triple(Icons.Default.Error, StudioColors.Danger, "异常/未就绪")
            null -> Triple(Icons.Default.Info, StudioColors.TextSecondary, "检查中…")
        }
        Icon(icon, null, Modifier.size(16.dp), tint = color)
        Text(label, color = StudioColors.TextSecondary, fontSize = 13.sp, modifier = Modifier.weight(1f))
        Text(text, color = color, fontSize = 12.5.sp)
    }
}
