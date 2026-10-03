package com.gameshield.manager.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gameshield.manager.data.model.EnvItem
import com.gameshield.manager.data.model.EnvParser
import com.gameshield.manager.ui.AppViewModel
import com.gameshield.manager.ui.theme.StudioColors

@Composable
fun EnvScreen(vm: AppViewModel) {
    Column(Modifier.fillMaxSize()) {
        Banner(vm)
        if (vm.envLoading) {
            Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = StudioColors.Accent, modifier = Modifier.size(40.dp))
                Spacer(Modifier.height(12.dp))
                Text("正在检测环境…", color = StudioColors.TextSecondary, fontSize = 13.sp)
            }
        } else if (vm.envItems.isEmpty()) {
            Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                Text("暂无数据", color = StudioColors.TextSecondary)
                Spacer(Modifier.height(10.dp))
                Button(onClick = { vm.refreshEnv() }, colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Accent)) {
                    Icon(Icons.Default.Refresh, null, Modifier.size(18.dp))
                    Text("  开始检测", color = StudioColors.BgDark)
                }
            }
        } else {
            val groups = EnvParser.group(vm.envItems)
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Text("环境检测结果", color = StudioColors.TextPrimary, fontSize = 16.sp)
                        Button(
                            onClick = { vm.refreshEnv() },
                            colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Surface2),
                        ) {
                            Icon(Icons.Default.Refresh, null, Modifier.size(18.dp), tint = StudioColors.Accent)
                            Text("  刷新", color = StudioColors.Accent, fontSize = 13.sp)
                        }
                    }
                }
                groups.forEach { (section, items) ->
                    item(key = section) { SectionCard(section, items) }
                }
                item {
                    Text(
                        "⚠ 解锁/Root 状态本身可能被游戏检测到。本工具不隐藏、不伪造任何状态。",
                        color = StudioColors.Warning,
                        fontSize = 12.sp,
                        modifier = Modifier.padding(top = 4.dp, bottom = 8.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionCard(section: String, items: List<EnvItem>) {
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(Modifier.padding(14.dp)) {
            Text(section, color = StudioColors.Accent, fontSize = 13.sp)
            Spacer(Modifier.height(8.dp))
            items.forEach { it ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(vertical = 5.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top,
                ) {
                    Text(
                        it.key,
                        color = StudioColors.TextSecondary,
                        fontSize = 13.sp,
                        modifier = Modifier.weight(0.38f),
                    )
                    val color = when (it.level) {
                        "ok" -> StudioColors.Green
                        "warn" -> StudioColors.Warning
                        "bad" -> StudioColors.Danger
                        else -> StudioColors.TextPrimary
                    }
                    Text(
                        it.value,
                        color = color,
                        fontSize = 13.sp,
                        modifier = Modifier.weight(0.62f),
                        fontFamily = FontFamily.Monospace,
                    )
                }
            }
        }
    }
}

@Composable
private fun Banner(vm: AppViewModel) {
    val msg = when {
        vm.suOk == false -> "✗ 未检测到 Root/KernelSU，或未授权本应用。请在 KernelSU Manager 中授权。"
        vm.moduleInstalled == false -> "⚠ Game Shield 模块未安装。到「设置」页一键部署，或手动安装模块 zip。"
        vm.moduleInstalled == true -> null
        else -> "正在检查环境…"
    }
    if (msg != null) {
        Row(
            Modifier
                .fillMaxWidth()
                .background(StudioColors.Surface2)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Default.WarningAmber, null, Modifier.size(18.dp), tint = StudioColors.Warning)
            Text(msg, color = StudioColors.TextPrimary, fontSize = 12.5.sp, modifier = Modifier.padding(start = 8.dp))
        }
    }
}
