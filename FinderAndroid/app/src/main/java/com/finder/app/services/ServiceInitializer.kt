package com.finder.app.services

import android.app.Application
import android.content.Context

object ServiceInitializer {
    private var isInitialized = false

    fun init(context: Context) {
        if (isInitialized) return
        val appContext = context.applicationContext

        // Initialize all services that require Context
        val application = appContext as Application
        AuthService.init(application)
        ThemeService.init(appContext)
        LocalizationService.init(appContext)
        ChatService.init(application)
        RatingService.init(appContext)
        HapticService.init(appContext)
        AdminService.init(appContext)
        ReportService.init(appContext)
        ScreenshotExceptionsService.init(appContext)

        isInitialized = true
    }
}
