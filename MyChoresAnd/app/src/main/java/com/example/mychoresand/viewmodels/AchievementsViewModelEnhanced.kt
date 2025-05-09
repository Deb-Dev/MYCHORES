package com.example.mychoresand.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.models.Badge
import com.example.mychoresand.models.User
import com.example.mychoresand.services.ChoreService
import com.example.mychoresand.services.NotificationServiceEnhanced
import com.example.mychoresand.services.UserService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Enhanced ViewModel handling achievements and badges operations
 * Designed to match iOS implementation functionality
 */
class AchievementsViewModelEnhanced(
    private val userService: UserService,
    private val choreService: ChoreService,
    private val notificationService: NotificationServiceEnhanced,
    private val userId: String? = null
) : ViewModel() {
    
    // All predefined badges in the system
    private val _allBadges = MutableStateFlow<List<Badge>>(Badge.predefinedBadges)
    val allBadges: StateFlow<List<Badge>> = _allBadges
    
    // Current user's earned badges
    private val _earnedBadges = MutableStateFlow<List<Badge>>(emptyList())
    val earnedBadges: StateFlow<List<Badge>> = _earnedBadges
    
    // Badges not yet earned by the user
    private val _unearnedBadges = MutableStateFlow<List<Badge>>(emptyList())
    val unearnedBadges: StateFlow<List<Badge>> = _unearnedBadges
    
    // Total tasks completed by the user
    private val _totalCompletedTasks = MutableStateFlow(0)
    val totalCompletedTasks: StateFlow<Int> = _totalCompletedTasks
    
    // Total badges earned by the user
    private val _totalEarnedBadges = MutableStateFlow(0)
    val totalEarnedBadges: StateFlow<Int> = _totalEarnedBadges
    
    // Total points earned by the user
    private val _totalPoints = MutableStateFlow(0)
    val totalPoints: StateFlow<Int> = _totalPoints
    
    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    // Error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    // Badge progress cache like iOS implementation
    private val badgeProgressMap: MutableMap<String, Double> = mutableMapOf()
    
    /**
     * Load badges for the current user
     */
    fun loadBadges() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            // Use provided ID or get from user service
            val effectiveUserId = userId ?: userService.getCurrentUserId()
            
            if (effectiveUserId.isNullOrEmpty()) {
                _errorMessage.value = "User ID not available"
                showDefaultBadges()
                _isLoading.value = false
                return@launch
            }
            
            try {
                // Fetch user to get their earned badges
                val user = userService.getUserById(effectiveUserId).first()
                
                if (user != null) {
                    // Get earned badges - handle potential empty earnedBadgeIds list
                    val earnedBadgeKeys = user.earnedBadgeIds
                    
                    // Map badge keys to actual Badge objects
                    val earned = earnedBadgeKeys.mapNotNull { badgeKey ->
                        Badge.getBadge(byKey = badgeKey)
                    }
                    
                    // Get unearned badges
                    val unearned = Badge.predefinedBadges.filter { badge ->
                        !earnedBadgeKeys.contains(badge.badgeKey)
                    }
                    
                    // Try to fetch completed tasks, but don't fail if this errors
                    var completedCount = 0
                    try {
                        val completedChores = choreService.getUserChores(true).first()
                        completedCount = completedChores.size
                    } catch (e: Exception) {
                        // Continue anyway, we can still show badges
                    }
                    
                    // Update the UI state
                    _earnedBadges.value = earned
                    _unearnedBadges.value = unearned
                    _totalCompletedTasks.value = completedCount
                    _totalEarnedBadges.value = earned.size
                    _totalPoints.value = user.totalPoints
                } else {
                    // Handle missing user by showing default badges
                    showDefaultBadges()
                }
            } catch (e: Exception) {
                // Handle the error gracefully by showing default badges
                showDefaultBadges()
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Show default badges when there's an error fetching the real ones
     */
    private fun showDefaultBadges() {
        _earnedBadges.value = emptyList()
        _unearnedBadges.value = Badge.predefinedBadges
        _totalCompletedTasks.value = 0
        _totalEarnedBadges.value = 0
        _totalPoints.value = 0
        // We don't set an error message so the UI shows empty state instead of error
    }
    
    /**
     * Calculate progress toward a badge
     * @param badge Badge to check progress for
     * @return Progress value between 0.0 and 1.0
     */
    fun getBadgeProgress(badge: Badge): Double {
        // Check cache first
        badgeProgressMap[badge.badgeKey]?.let { return it }
        
        // Check if badge is already earned
        if (_earnedBadges.value.any { it.badgeKey == badge.badgeKey }) {
            badgeProgressMap[badge.badgeKey] = 1.0
            return 1.0
        }
        
        // If badge requires tasks, use the completed task count
        val requiredTaskCount = badge.requiredTaskCount ?: return 0.0
        if (requiredTaskCount <= 0) return 0.0
        
        // Calculate progress based on total completed tasks
        val progress = (_totalCompletedTasks.value.toDouble() / requiredTaskCount.toDouble()).coerceAtMost(1.0)
        
        // Cache the result
        badgeProgressMap[badge.badgeKey] = progress
        return progress
    }
    
    /**
     * Check if the user qualifies for any badges they don't already have
     */
    fun checkForNewBadges() {
        viewModelScope.launch {
            // Use provided ID or get from user service
            val effectiveUserId = userId ?: userService.getCurrentUserId()
            
            if (effectiveUserId.isNullOrEmpty()) {
                return@launch
            }
            
            try {
                // Fetch current user
                val user = userService.getUserById(effectiveUserId).first() ?: return@launch
                
                // Get current badges
                val currentBadgeKeys = user.earnedBadgeIds
                
                // Find badges the user doesn't have but meets requirements for
                val completedTasksCount = _totalCompletedTasks.value
                
                val eligibleBadges = Badge.predefinedBadges.filter { badge ->
                    val requiredCount = badge.requiredTaskCount ?: return@filter false
                    !currentBadgeKeys.contains(badge.badgeKey) && completedTasksCount >= requiredCount
                }
                
                for (badge in eligibleBadges) {
                    val result = userService.awardBadge(user.id!!, badge.badgeKey)
                    if (result) {
                        // Send notification for new badge (matching iOS implementation)
                        notificationService.sendBadgeEarnedNotification(
                            toUserId = user.id!!,
                            badgeKey = badge.badgeKey,
                            badgeName = badge.name
                        )
                    }
                }
                
                // If any badges were awarded, refresh the earned badges list
                if (eligibleBadges.isNotEmpty()) {
                    loadBadges()
                }
            } catch (e: Exception) {
                // Silently handle exceptions during badge checks
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
