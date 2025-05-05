package com.example.mychoresand

import android.app.Application
import com.example.mychoresand.di.AppContainer

/**
 * Main application class for the MyChores app
 */
class MyChoresApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize dependency injection
        AppContainer.initialize(applicationContext)
    }
}
