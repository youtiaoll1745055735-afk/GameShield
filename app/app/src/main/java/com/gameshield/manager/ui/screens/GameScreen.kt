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
import androidx.compose.material.icons.filled.PowerSettingsNew
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.Visibility
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
fun GameScreen(vm: AppViewModel) {
    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("游戏兼容模式", color = StudioColors.TextPrimary, fontSize = 16.sp)
            Text("临时停用指定模块，减少对游戏环境的干扰；结束后一键恢复。", color = StudioColors.TextSecondary, fontSize = 12.5.sp)
        }
        item {
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text("当前状态", color = StudioColors.Accent, fontSize = 13.sp)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        vm.gameStatus.ifEmpty { "加载中…" },
                        color = StudioColors.TextPrimary,
                        fontSize = 12.5.sp,
                        fontFamily = FontFamily.Monospace,
                    )
                    Spacer(Modifier.height(6.dp))
                    Button(
                        onClick = { vm.refreshGameStatus() },
                        colors = ButtonDefaults.buttonColors(containerColor = StudioColors.Surface2),
                    ) {
                        Text("刷新状态", color = StudioColors.Accent, fontSize = 13.sp)
                    }
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("开启兼容模式", StudioColors.Accent, vm::gameOn, Modifier.weight(1f), Icons.Default.PowerSettingsNew)
                ActionButton("关闭并恢复", StudioColors.Surface2, vm::gameOff, Modifier.weight(1f), Icons.Default.Restore)
            }
            Spacer(Modifier.height(10.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("预览管理范围", StudioColors.Surface2, vm::gamePreview, Modifier.weight(1f), Icons.Default.Visibility)
            }
        }
        item {
            Text(
                "⚠ 生效边界：停用标志与进程清理立即生效；模块脚本与挂载需重启后完全生效。" +
                    "推荐流程：开启 → 重启 → 游戏 → 结束后关闭 → 重启。",
                color = StudioColors.Warning,
                fontSize = 12.sp,
            )
        }
        item { OutputCard("操作输出", vm.gameOutput) }
    }
}

@Composable
internal fun ActionButton(
    label: String,
    color: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.buttonColors(containerColor = color),
        shape = RoundedCornerShape(10.dp),
    ) {
        if (icon != null) Icon(icon, null, Modifier.size(17.dp), tint = if (color == StudioColors.Accent) StudioColors.BgDark else StudioColors.Accent)
        Text(
            "  $label",
            color = if (color == StudioColors.Accent) StudioColors.BgDark else StudioColors.TextPrimary,
            fontSize = 13.sp,
        )
    }
}

@Composable
internal fun OutputCard(title: String, text: String) {
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = StudioColors.Surface),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(Modifier.padding(14.dp)) {
            Text(title, color = StudioColors.Accent, fontSize = 13.sp)
            Spacer(Modifier.height(8.dp))
            Text(
                text.ifEmpty { "（暂无输出）" },
                color = StudioColors.TextPrimary,
                fontSize = 12.sp,
                fontFamily = FontFamily.Monospace,
                modifier = Modifier.background(StudioColors.BgDark, RoundedCornerShape(8.dp)).padding(10.dp),
            )
        }
    }
}
