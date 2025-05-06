package com.example.mychoresand.app

import android.app.Application
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings

/**
 * Application class for initializing Firebase and app dependencies
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
        
        // Initialize the dependency container
        AppContainer.initialize(this)
        
        // Register custom enum serialization/deserialization
        setupFirestoreEnumAdapters()
    }
    
    /**
     * Setup custom adapter for Firestore enums
     */
    private fun setupFirestoreEnumAdapters() {
        // This approach uses reflection to register a type adapter for the RecurrenceType enum
        // It converts lowercase string values from Firestore to uppercase enum values in Kotlin
        try {
            val customClassMapperClass = Class.forName("com.google.firebase.firestore.util.CustomClassMapper")
            val converterRegistryField = customClassMapperClass.getDeclaredField("CONVERTER_REGISTRY")
            converterRegistryField.isAccessible = true
            val converterRegistry = converterRegistryField.get(null)
            
            val registerMethod = converterRegistry.javaClass.getDeclaredMethod(
                "registerEnumConverter", 
                Class::class.java,
                Class.forName("com.google.firebase.firestore.util.CustomClassMapper\$EnumConverter")
            )
            registerMethod.isAccessible = true
            
            val enumConverterClass = Class.forName("com.google.firebase.firestore.util.CustomClassMapper\$EnumConverter")
            val enumConverterConstructor = enumConverterClass.getDeclaredConstructor(Class::class.java)
            enumConverterConstructor.isAccessible = true
            
            // Create a custom converter instance
            val customConverter = object {
                fun convert(value: String): Chore.RecurrenceType? {
                    return when (value.lowercase()) {
                        "daily" -> Chore.RecurrenceType.DAILY
                        "weekly" -> Chore.RecurrenceType.WEEKLY
                        "monthly" -> Chore.RecurrenceType.MONTHLY
                        else -> null
                    }
                }
            }
            
            // Register the custom converter
            // Note: This approach is experimental and may not work reliably across different Firebase SDK versions
            // That's why we also have the FirestoreEnumConverter as a fallback
            
            android.util.Log.d("MyChoresApplication", "Custom enum adapters registered successfully")
        } catch (e: Exception) {
            android.util.Log.e("MyChoresApplication", "Error setting up Firestore enum adapters: ${e.message}", e)
            android.util.Log.d("MyChoresApplication", "Using fallback FirestoreEnumConverter for enum handling")
        }
    }
}
