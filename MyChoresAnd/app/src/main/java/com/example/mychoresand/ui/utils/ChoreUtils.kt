package com.example.mychoresand.ui.utils

import com.example.mychoresand.di.AppContainer
import android.util.Log

/**
 * Utility functions related to chores and household management
 */

private const val TAG = "ChoreUtils"

/**
 * Helper function to get a valid household ID
 * This is used when creating new chores and we need a valid household ID
 */
fun getValidHouseholdId(): String {
    // First try to get it from the auth service
    val firebaseUser = AppContainer.authService.currentUser
    Log.d(TAG, "Firebase User: $firebaseUser")
    
    // Then try the household view model's current user
    val user = AppContainer.householdViewModel.currentUser.value
    Log.d(TAG, "Current user from viewModel: $user")
    
    // If the user has household IDs, use the first one
    if (user != null && user.householdIds.isNotEmpty()) {
        val primaryHouseholdId = user.householdIds.first()
        Log.d(TAG, "Using user's primary household ID: $primaryHouseholdId")
        return primaryHouseholdId
    }
    
    // Otherwise try to get it from the household view model
    val households = AppContainer.householdViewModel.households.value
    Log.d(TAG, "Households: $households")
    
    if (households.isNotEmpty()) {
        val primaryHouseholdId = households.first().id
        Log.d(TAG, "Using first household ID from list: $primaryHouseholdId")
        return primaryHouseholdId ?: ""
    }
    
    // If all else fails, check if we have an active household setting
    val activeHouseholdId = AppContainer.preferencesManager.getCurrentHouseholdId()
    Log.d(TAG, "Active household ID from preferences: $activeHouseholdId")
    
    return activeHouseholdId ?: ""
}
