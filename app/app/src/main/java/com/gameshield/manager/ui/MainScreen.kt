package com.gameshield.manager.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import com.gameshield.manager.ui.screens.DiagScreen
import com.gameshield.manager.ui.screens.EnvScreen
import com.gameshield.manager.ui.screens.GameScreen
import com.gameshield.manager.ui.screens.SettingsScreen
import com.gameshield.manager.ui.theme.StudioColors

private data class Tab(val label: String, val icon: ImageVector)

@Composable
fun MainScreen(vm: AppViewModel) {
    val tabs = remember {
        listOf(
            Tab("环境", Icons.Default.MonitorHeart),
            Tab("游戏模式", Icons.Default.SportsEsports),
            Tab("诊断", Icons.AutoMirrored.Filled.Article),
            Tab("设置", Icons.Default.Settings),
        )
    }
    var current by remember { mutableIntStateOf(0) }

    Scaffold(
        containerColor = StudioColors.BgDark,
        bottomBar = {
            NavigationBar(containerColor = StudioColors.Surface) {
                tabs.forEachIndexed { i, t ->
                    NavigationBarItem(
                        selected = current == i,
                        onClick = { current = i },
                        icon = { Icon(t.icon, contentDescription = t.label) },
                        label = { Text(t.label) },
                    )
                }
            }
        },
    ) { pad ->
        Box(
            Modifier
                .fillMaxSize()
                .padding(pad),
        ) {
            when (current) {
                0 -> EnvScreen(vm)
                1 -> GameScreen(vm)
                2 -> DiagScreen(vm)
                else -> SettingsScreen(vm)
            }
        }
    }
}
