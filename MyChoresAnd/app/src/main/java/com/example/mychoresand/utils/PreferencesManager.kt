package com.example.mychoresand.utils

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Helper class for storing and retrieving preferences
 */
class PreferencesManager(context: Context) {
    
    companion object {
        private const val PREFERENCES_NAME = "my_chores_prefs"
        private const val SECURE_PREFS_NAME = "my_chores_secure_prefs"
        
        // Regular preference keys
        const val KEY_SELECTED_HOUSEHOLD_ID = "selected_household_id"
        const val KEY_NOTIFICATION_ENABLED = "notification_enabled"
        const val KEY_THEME_MODE = "theme_mode"
        const val KEY_LAST_SYNC_TIME = "last_sync_time"
        const val KEY_CURRENT_HOUSEHOLD_ID = "current_household_id"
        
        // Secure preference keys
        const val KEY_AUTH_TOKEN = "auth_token"
        const val KEY_USER_ID = "user_id"
        const val KEY_USER_EMAIL = "user_email"
        const val KEY_DEVICE_TOKEN = "device_token"
    }
    
    // Regular preferences for non-sensitive data
    private val preferences: SharedPreferences = context.getSharedPreferences(
        PREFERENCES_NAME, Context.MODE_PRIVATE
    )
    
    // Encrypted preferences for sensitive data
    private val securePreferences: SharedPreferences
    
    private val gson = Gson()
    
    init {
        // Initialize encrypted shared preferences
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        
        securePreferences = EncryptedSharedPreferences.create(
            context,
            SECURE_PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }
    
    /**
     * Save a string value to preferences
     */
    fun saveString(key: String, value: String, secure: Boolean = false) {
        val prefs = if (secure) securePreferences else preferences
        prefs.edit().putString(key, value).apply()
    }
    
    /**
     * Get a string value from preferences
     */
    fun getString(key: String, defaultValue: String = "", secure: Boolean = false): String {
        val prefs = if (secure) securePreferences else preferences
        return prefs.getString(key, defaultValue) ?: defaultValue
    }
    
    /**
     * Save an integer value to preferences
     */
    fun saveInt(key: String, value: Int, secure: Boolean = false) {
        val prefs = if (secure) securePreferences else preferences
        prefs.edit().putInt(key, value).apply()
    }
    
    /**
     * Get an integer value from preferences
     */
    fun getInt(key: String, defaultValue: Int = 0, secure: Boolean = false): Int {
        val prefs = if (secure) securePreferences else preferences
        return prefs.getInt(key, defaultValue)
    }
    
    /**
     * Save a boolean value to preferences
     */
    fun saveBoolean(key: String, value: Boolean, secure: Boolean = false) {
        val prefs = if (secure) securePreferences else preferences
        prefs.edit().putBoolean(key, value).apply()
    }
    
    /**
     * Get a boolean value from preferences
     */
    fun getBoolean(key: String, defaultValue: Boolean = false, secure: Boolean = false): Boolean {
        val prefs = if (secure) securePreferences else preferences
        return prefs.getBoolean(key, defaultValue)
    }
    
    /**
     * Save an object to preferences (serialized as JSON)
     */
    inline fun <reified T> saveObject(key: String, value: T, secure: Boolean = false) {
        // Call the internal implementation function
        saveObjectImpl(key, value, secure)
    }

    /**
     * Implementation function that handles the actual saving
     * This is internal (not private), so it can be accessed from inline functions
     */
    public fun <T> saveObjectImpl(key: String, value: T, secure: Boolean) {
        val json = gson.toJson(value)
        val prefs = if (secure) securePreferences else preferences
        prefs.edit().putString(key, json).apply()
    }
    
    /**
     * Get an object from preferences (deserialized from JSON)
     */
    inline fun <reified T> getObject(key: String, secure: Boolean = false): T? {
        // Call the internal implementation function
        return getObjectImpl(key, secure, T::class.java)
    }

    /**
     * Implementation function that handles the actual retrieval
     * This is internal (not private), so it can be accessed from inline functions
     */
    public fun <T> getObjectImpl(key: String, secure: Boolean, type: Class<T>): T? {
        val prefs = if (secure) securePreferences else preferences
        val json = prefs.getString(key, null) ?: return null
        return try {
            gson.fromJson(json, TypeToken.get(type))
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Remove a preference
     */
    fun remove(key: String, secure: Boolean = false) {
        val prefs = if (secure) securePreferences else preferences
        prefs.edit().remove(key).apply()
    }
    
    /**
     * Clear all preferences
     */
    fun clearAll() {
        preferences.edit().clear().apply()
        securePreferences.edit().clear().apply()
    }
    
    /**
     * Save the selected household ID
     */
    fun saveSelectedHouseholdId(householdId: String?) {
        householdId?.let {
            saveString(KEY_SELECTED_HOUSEHOLD_ID, it)
        } ?: run {
            remove(KEY_SELECTED_HOUSEHOLD_ID)
        }
    }
    
    /**
     * Get the selected household ID
     */
    fun getSelectedHouseholdId(): String? {
        val id = getString(KEY_SELECTED_HOUSEHOLD_ID)
        return if (id.isEmpty()) null else id
    }
    
    /**
     * Get the ID of the current household
     */
    fun getCurrentHouseholdId(): String? {
        return preferences.getString(KEY_CURRENT_HOUSEHOLD_ID, null)
    }
    
    /**
     * Save the authenticated user ID
     */
    fun saveUserId(userId: String) {
        saveString(KEY_USER_ID, userId, secure = true)
    }
    
    /**
     * Get the authenticated user ID
     */
    fun getUserId(): String? {
        val id = getString(KEY_USER_ID, secure = true)
        return if (id.isEmpty()) null else id
    }
    
    /**
     * Get the authenticated user ID as a non-nullable String
     * Returns empty string if no user ID is found
     */
    fun getCurrentUserId(): String {
        return getUserId() ?: ""
    }
    
    /**
     * Save the user's authentication token
     */
    fun saveAuthToken(token: String) {
        saveString(KEY_AUTH_TOKEN, token, secure = true)
    }
    
    /**
     * Get the user's authentication token
     */
    fun getAuthToken(): String? {
        val token = getString(KEY_AUTH_TOKEN, secure = true)
        return if (token.isEmpty()) null else token
    }
    
    /**
     * Save the device FCM token for push notifications
     */
    fun saveDeviceToken(token: String) {
        saveString(KEY_DEVICE_TOKEN, token, secure = true)
    }
    
    /**
     * Get the device FCM token for push notifications
     */
    fun getDeviceToken(): String? {
        val token = getString(KEY_DEVICE_TOKEN, secure = true)
        return if (token.isEmpty()) null else token
    }
}
