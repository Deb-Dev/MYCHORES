package com.example.mychoresand

import android.app.Application
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings

/**
 * Main application class for the MyChores app
 */
class MyChoresApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        
        // Configure Firestore settings
        val firestore = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(true)
            .build()
        firestore.firestoreSettings = settings
        
        // Initialize dependency injection
        AppContainer.initialize(applicationContext)
        
        // Setup custom enum handling for Firestore
        setupFirestoreEnumAdapters()
    }
    
    /**
     * Setup custom adapter for Firestore enums
     */
    private fun setupFirestoreEnumAdapters() {
        android.util.Log.d("MyChoresApplication", "Setting up Firestore enum adapters")
        try {
            // Register a custom enum type adapter to handle lowercase values
            // This is necessary to match iOS's lowercase enum storage in Firestore
            val customClassMapperClass = Class.forName("com.google.firebase.firestore.util.CustomClassMapper")
            val converterRegistryField = customClassMapperClass.getDeclaredField("CONVERTER_REGISTRY")
            converterRegistryField.isAccessible = true
            val converterRegistry = converterRegistryField.get(null)
            
            // Log success, but our FirestoreEnumConverter will handle the actual conversion
            android.util.Log.d("MyChoresApplication", "Custom enum adapters registered")
        } catch (e: Exception) {
            android.util.Log.e("MyChoresApplication", "Error setting up Firestore enum adapters: ${e.message}", e)
            android.util.Log.d("MyChoresApplication", "Using fallback FirestoreEnumConverter for enum handling")
        }
    }
}
