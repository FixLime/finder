package com.finder.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import com.finder.app.navigation.FinderNavHost
import com.finder.app.services.ServiceInitializer
import com.finder.app.services.ThemeService
import com.finder.app.ui.theme.FinderTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize all services with application context
        ServiceInitializer.init(applicationContext)
        enableEdgeToEdge()
        setContent {
            val isDarkMode by ThemeService.isDarkMode.collectAsState()
            FinderTheme(darkTheme = isDarkMode) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    FinderNavHost()
                }
            }
        }
    }
}
