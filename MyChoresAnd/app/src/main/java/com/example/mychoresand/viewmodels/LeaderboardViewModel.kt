package com.example.mychoresand.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.models.User
import com.example.mychoresand.services.UserService
import com.example.mychoresand.services.AuthService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel handling leaderboard-related operations
 */
class LeaderboardViewModel(
    private val userService: UserService,
    private val authService: AuthService // Adding AuthService dependency for currentUser
) : ViewModel() {
    
    companion object {
        private const val TAG = "LeaderboardViewModel"
    }
    
    // All users in the household
    private val _householdUsers = MutableStateFlow<List<User>>(emptyList())
    
    // Current user
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser
    
    // Weekly leaderboard
    private val _weeklyLeaderboard = MutableStateFlow<List<User>>(emptyList())
    val weeklyLeaderboard: StateFlow<List<User>> = _weeklyLeaderboard
    
    // Monthly leaderboard
    private val _monthlyLeaderboard = MutableStateFlow<List<User>>(emptyList())
    val monthlyLeaderboard: StateFlow<List<User>> = _monthlyLeaderboard
    
    // All-time leaderboard
    private val _allTimeLeaderboard = MutableStateFlow<List<User>>(emptyList())
    val allTimeLeaderboard: StateFlow<List<User>> = _allTimeLeaderboard
    
    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    // Error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    init {
        loadCurrentUser()
    }
    
    /**
     * Load the current user
     */
    private fun loadCurrentUser() {
        viewModelScope.launch {
            try {
                // Use existing auth property instead of a non-existent method
                val userId = authService.currentUser?.uid ?: return@launch
                
                // Use the Flow-based API from UserService
                userService.getUser(userId).collect { user ->
                    user?.let {
                        _currentUser.value = it
                    }
                }
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load user: ${e.message}"
            }
        }
    }
    
    /**
     * Load leaderboard data for the given household
     */
    fun loadLeaderboard(householdId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                // Use the correct method name from UserService and collect the flow
                userService.getHouseholdUsers(householdId).collect { users ->
                    _householdUsers.value = users
                    
                    // Sort for weekly leaderboard
                    _weeklyLeaderboard.value = users.sortedByDescending { it.weeklyPoints }
                    
                    // Sort for monthly leaderboard
                    _monthlyLeaderboard.value = users.sortedByDescending { it.monthlyPoints }
                    
                    // Sort for all-time leaderboard
                    _allTimeLeaderboard.value = users.sortedByDescending { it.totalPoints }
                    
                    _isLoading.value = false
                }
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load leaderboard: ${e.message}"
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Refresh the leaderboard data
     */
    fun refreshLeaderboard(householdId: String) {
        loadLeaderboard(householdId)
    }
}
