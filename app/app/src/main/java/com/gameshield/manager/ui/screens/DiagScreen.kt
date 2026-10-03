package com.gameshield.manager.ui.screens

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
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Summarize
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.gameshield.manager.ui.AppViewModel
import com.gameshield.manager.ui.theme.StudioColors

@Composable
fun DiagScreen(vm: AppViewModel) {
    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("问题定位诊断", color = StudioColors.TextPrimary, fontSize = 16.sp)
            Text("开始诊断 → 正常玩游戏 → 结束后停止并生成报告。只读取系统信息，不触碰游戏。", color = StudioColors.TextSecondary, fontSize = 12.5.sp)
        }
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text("会话状态", color = StudioColors.Accent, fontSize = 13.sp)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        vm.diagStatus.ifEmpty { "加载中…" },
                        color = StudioColors.TextPrimary,
                        fontSize = 12.5.sp,
                        fontFamily = FontFamily.Monospace,
                    )
                    Spacer(Modifier.height(6.dp))
                    Button(
                        onClick = { vm.refreshDiagStatus() },
                        colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Surface2),
                    ) {
                        Text("刷新状态", color = StudioColors.Accent, fontSize = 13.sp)
                    }
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("开始诊断", StudioColors.Accent, vm::diagStart, Modifier.weight(1f), Icons.Default.PlayArrow)
                ActionButton("停止诊断", StudioColors.Surface2, vm::diagStop, Modifier.weight(1f), Icons.Default.Stop)
            }
            Spacer(Modifier.height(10.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("生成/查看报告", StudioColors.Surface2, vm::diagReport, Modifier.weight(1f), Icons.Default.Summarize)
                ActionButton("查看日志", StudioColors.Surface2, vm::viewLog, Modifier.weight(1f))
            }
        }
        item {
            Text(
                "报告为关联性提示，不构成对封禁/冻结原因的任何断言。冻结判定发生在服务器侧。",
                color = StudioColors.Warning,
                fontSize = 12.sp,
            )
        }
        item { OutputCard("诊断输出 / 报告", vm.diagOutput) }
    }
}
