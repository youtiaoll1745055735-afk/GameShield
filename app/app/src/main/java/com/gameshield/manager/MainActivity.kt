package com.gameshield.manager

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.gameshield.manager.ui.AppViewModel
import com.gameshield.manager.ui.MainScreen
import com.gameshield.manager.ui.theme.CrosshairStudioTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CrosshairStudioTheme {
                MainScreen(vm = AppViewModel())
            }
        }
    }
}
