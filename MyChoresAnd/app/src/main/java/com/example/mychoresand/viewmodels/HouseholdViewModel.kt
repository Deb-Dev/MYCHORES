package com.example.mychoresand.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Household
import com.example.mychoresand.models.User
import com.example.mychoresand.services.AuthService
import com.example.mychoresand.services.HouseholdService
import com.example.mychoresand.services.UserService
import com.example.mychoresand.utils.PreferencesManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for household-related views
 */
class HouseholdViewModel(
    private val householdService: HouseholdService,
    private val userService: UserService,
    private val authService: AuthService
) : ViewModel() {
    
    companion object {
        private const val TAG = "HouseholdViewModel"
    }
    
    // StateFlow for households
    private val _households = MutableStateFlow<List<Household>>(emptyList())
    val households: StateFlow<List<Household>> = _households
    
    // StateFlow for selected household
    private val _selectedHousehold = MutableStateFlow<Household?>(null)
    val selectedHousehold: StateFlow<Household?> = _selectedHousehold
    
    // StateFlow for household members - match iOS property name
    private val _householdMembers = MutableStateFlow<List<User>>(emptyList())
    val householdMembers: StateFlow<List<User>> = _householdMembers
    
    // StateFlow for current user - match iOS property name
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser
    
    // StateFlow for loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    // StateFlow for error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    init {
        loadCurrentUser()
        loadHouseholds()
    }
    
    /**
     * Load the current user
     */
    private fun loadCurrentUser() {
        viewModelScope.launch {
            val uid = authService.currentUser?.uid ?: return@launch
            
            try {
                // Use the flow-based API
                userService.getUser(uid).collect { user ->
                    _currentUser.value = user
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading current user: ${e.message}", e)
            }
        }
    }
    
    /**
     * Load all households for the current user
     */
    fun loadHouseholds() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                if (authService.currentUser == null) {
                    throw IllegalStateException("Not signed in")
                }
                
                // Use the flow-based API
                householdService.getUserHouseholds().collect { fetchedHouseholds ->
                    _households.value = fetchedHouseholds
                    
                    // If we only have one household, select it automatically
                    if (fetchedHouseholds.size == 1) {
                        _selectedHousehold.value = fetchedHouseholds.first()
                        fetchedHouseholds.first().id?.let { householdId ->
                            loadHouseholdMembers(householdId)
                            // Save current household ID to preferences
                            AppContainer.preferencesManager.saveString(
                                PreferencesManager.KEY_CURRENT_HOUSEHOLD_ID, 
                                householdId
                            )
                        }
                    }
                    
                    _isLoading.value = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading households: ${e.message}", e)
                _errorMessage.value = "Failed to load households: ${e.message}"
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Load a specific household
     */
    fun fetchHousehold(householdId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                // Use the flow-based API
                householdService.getHousehold(householdId).collect { household ->
                    household?.let {
                        _selectedHousehold.value = it
                        loadHouseholdMembers(householdId)
                    } ?: run {
                        _errorMessage.value = "Household not found"
                    }
                    
                    _isLoading.value = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading household: ${e.message}", e)
                _errorMessage.value = "Failed to load household: ${e.message}"
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Clear any error message
     */
    fun clearErrorMessage() {
        _errorMessage.value = null
    }
    
    /**
     * Create a new household
     */
    fun createHousehold(name: String, description: String = "", callback: (Result<String?>) -> Unit = {}) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                val result = householdService.createHousehold(name, description)
                
                result.fold(
                    onSuccess = { household ->
                        // Add to list and select it
                        val updatedHouseholds = _households.value.toMutableList()
                        updatedHouseholds.add(household)
                        _households.value = updatedHouseholds
                        _selectedHousehold.value = household
                        
                        // Save current household ID to preferences
                        household.id?.let { householdId ->
                            AppContainer.preferencesManager.saveString(
                                PreferencesManager.KEY_CURRENT_HOUSEHOLD_ID, 
                                householdId
                            )
                            // Load members for the new household
                            loadHouseholdMembers(householdId)
                        }
                        
                        // Call the callback with success
                        callback(Result.success(household.id))
                    },
                    onFailure = { e ->
                        callback(Result.failure(e))
                        throw e
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error creating household: ${e.message}", e)
                _errorMessage.value = "Failed to create household: ${e.message}"
                callback(Result.failure(e))
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Join a household using an invite code
     */
    fun joinHousehold(inviteCode: String, callback: (Result<String?>) -> Unit = {}) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                val result = householdService.joinHousehold(inviteCode)
                
                result.fold(
                    onSuccess = { household ->
                        // Reload households to get updated list
                        loadHouseholds()
                        // Select the joined household
                        _selectedHousehold.value = household
                        
                        // Save current household ID to preferences
                        household.id?.let { householdId ->
                            AppContainer.preferencesManager.saveString(
                                PreferencesManager.KEY_CURRENT_HOUSEHOLD_ID, 
                                householdId
                            )
                            // Load members for the joined household
                            loadHouseholdMembers(householdId)
                        }
                        
                        // Call the callback with success
                        callback(Result.success(household.id))
                    },
                    onFailure = { e ->
                        callback(Result.failure(e))
                        throw e
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error joining household: ${e.message}", e)
                _errorMessage.value = "Failed to join household: ${e.message}"
                _isLoading.value = false
                callback(Result.failure(e))
            }
        }
    }
    
    /**
     * Leave a household
     */
    fun leaveHousehold(householdId: String, onComplete: ((hasHouseholds: Boolean) -> Unit)? = null) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                val result = householdService.leaveHousehold(householdId)
                
                result.fold(
                    onSuccess = {
                        // Clear selected household if it was the one we left
                        if (_selectedHousehold.value?.id == householdId) {
                            _selectedHousehold.value = null
                            // Clear current household ID from preferences
                            AppContainer.preferencesManager.remove(PreferencesManager.KEY_CURRENT_HOUSEHOLD_ID)
                        }
                        
                        // Reload households to get updated list and check if any remain
                        householdService.getUserHouseholds().collect { updatedHouseholds ->
                            _households.value = updatedHouseholds
                            // Notify caller if user has any households left
                            onComplete?.invoke(updatedHouseholds.isNotEmpty())
                            _isLoading.value = false
                        }
                    },
                    onFailure = { e ->
                        _isLoading.value = false
                        onComplete?.invoke(_households.value.isNotEmpty())
                        throw e
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error leaving household: ${e.message}", e)
                _errorMessage.value = "Failed to leave household: ${e.message}"
                _isLoading.value = false
                // Call callback with current household state in case of error
                onComplete?.invoke(_households.value.isNotEmpty())
            }
        }
    }
    
    /**
     * Load members of a household
     */
    private fun loadHouseholdMembers(householdId: String) {
        viewModelScope.launch {
            try {
                // Use the flow-based API
                userService.getHouseholdUsers(householdId).collect { members ->
                    _householdMembers.value = members
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading household members: ${e.message}", e)
                _errorMessage.value = "Failed to load members: ${e.message}"
            }
        }
    }
    
    /**
     * Check if the current user is the owner of a household
     */
    fun isCurrentUserOwner(household: Household): Boolean {
        val userId = authService.currentUser?.uid ?: return false
        return household.ownerUserId == userId
    }
    
    /**
     * Select a household and load its data
     * @param household The household to select
     */
    fun selectHousehold(household: Household) {
        viewModelScope.launch {
            _selectedHousehold.value = household
            
            household.id?.let { householdId ->
                // Save current household ID to preferences
                AppContainer.preferencesManager.saveString(
                    PreferencesManager.KEY_CURRENT_HOUSEHOLD_ID,
                    householdId
                )
                
                // Load household members
                loadHouseholdMembers(householdId)
                
                // Load chores for the selected household using ChoreViewModel
                AppContainer.choreViewModel.loadHouseholdChores(householdId)
            }
        }
    }
}
