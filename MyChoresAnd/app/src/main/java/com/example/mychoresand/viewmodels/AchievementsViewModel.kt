package com.example.mychoresand.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.models.Badge
import com.example.mychoresand.models.User
import com.example.mychoresand.services.NotificationService
import com.example.mychoresand.services.UserService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * ViewModel handling achievements and badges operations
 */
class AchievementsViewModel(
    private val userService: UserService,
    private val notificationService: NotificationService
) : ViewModel() {
    
    // Current user's earned badges
    private val _earnedBadges = MutableStateFlow<List<Badge>>(emptyList())
    val earnedBadges: StateFlow<List<Badge>> = _earnedBadges
    
    // All available badges
    private val _availableBadges = MutableStateFlow<List<Badge>>(Badge.predefinedBadges)
    val availableBadges: StateFlow<List<Badge>> = _availableBadges
    
    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    // Error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    /**
     * Load badges for the current user
     */
    fun loadUserBadges() {
        viewModelScope.launch {
            _isLoading.value = true
            
            userService.getCurrentUser().collect { user ->
                if (user != null) {
                    processUserBadges(user)
                } else {
                    _earnedBadges.value = emptyList()
                    _errorMessage.value = "Couldn't retrieve user information"
                }
                
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Process user badges to determine which ones they've earned
     * @param user The user whose badges to process
     */
    private fun processUserBadges(user: User) {
        // Changed from earnedBadges to earnedBadgeIds to match User model
        val earned = user.earnedBadgeIds.mapNotNull { badgeKey ->
            Badge.getBadge(byKey = badgeKey)
        }
        
        _earnedBadges.value = earned
    }
    
    /**
     * Check if the user qualifies for any badges they don't already have
     * @param user The user to check badges for
     */
    fun checkForNewBadges(user: User) {
        viewModelScope.launch {
            // Changed from earnedBadges to earnedBadgeIds to match User model
            val currentBadgeKeys = user.earnedBadgeIds
            
            // Find badges the user doesn't have but meets requirements for
            val eligibleBadges = Badge.predefinedBadges.filter { badge ->
                val requiredCount = badge.requiredTaskCount
                requiredCount != null &&
                        !currentBadgeKeys.contains(badge.badgeKey) &&
                        user.totalPoints >= requiredCount
            }
            
            for (badge in eligibleBadges) {
                val result = userService.awardBadge(user.id!!, badge.badgeKey)
                if (result) {
                    // Show notification for new badge
                    notificationService.showBadgeEarnedNotification(badge.badgeKey)
                }
            }
            
            // If any badges were awarded, refresh the earned badges list
            if (eligibleBadges.isNotEmpty()) {
                loadUserBadges()
            }
        }
    }
    
    /**
     * Clear error message
     */
    fun clearErrorMessage() {
        _errorMessage.value = null
    }
}
