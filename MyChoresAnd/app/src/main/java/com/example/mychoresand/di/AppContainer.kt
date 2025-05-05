package com.example.mychoresand.di

import android.content.Context
import com.example.mychoresand.services.AuthService
import com.example.mychoresand.services.ChoreService
import com.example.mychoresand.services.HouseholdService
import com.example.mychoresand.services.NotificationService
import com.example.mychoresand.services.UserService
import com.example.mychoresand.utils.PreferencesManager
import com.example.mychoresand.viewmodels.AchievementsViewModel
import com.example.mychoresand.viewmodels.AuthViewModel
import com.example.mychoresand.viewmodels.ChoreViewModel
import com.example.mychoresand.viewmodels.HouseholdViewModel
import com.example.mychoresand.viewmodels.LeaderboardViewModel

/**
 * Simple dependency injection container
 */
object AppContainer {
    private var _authService: AuthService? = null
    private var _userService: UserService? = null
    private var _householdService: HouseholdService? = null
    private var _choreService: ChoreService? = null
    private var _notificationService: NotificationService? = null
    private var _preferencesManager: PreferencesManager? = null
    
    private var _authViewModel: AuthViewModel? = null
    private var _choreViewModel: ChoreViewModel? = null
    private var _householdViewModel: HouseholdViewModel? = null
    private var _leaderboardViewModel: LeaderboardViewModel? = null
    private var _achievementsViewModel: AchievementsViewModel? = null
    
    /**
     * Initialize the container with application context
     * @param context The application context
     */
    fun initialize(context: Context) {
        // Create utilities
        _preferencesManager = PreferencesManager(context)
        
        // Create services
        _authService = AuthService(_preferencesManager!!)
        _userService = UserService()
        _householdService = HouseholdService()
        _notificationService = NotificationService(context)
        _choreService = ChoreService(_userService!!)
        
        // Create viewmodels
        _authViewModel = AuthViewModel(_authService!!, _notificationService!!)
        _choreViewModel = ChoreViewModel(_choreService!!, _userService!!)
        _householdViewModel = HouseholdViewModel(
            _householdService!!,
            _userService!!,
            _authService!!
        )
        // Fix: Add AuthService to LeaderboardViewModel
        _leaderboardViewModel = LeaderboardViewModel(_userService!!, _authService!!)
        _achievementsViewModel = AchievementsViewModel(_userService!!, _notificationService!!)
    }
    
    /**
     * Reset the container (for testing or logout)
     */
    fun reset() {
        _authService = null
        _userService = null
        _householdService = null
        _choreService = null
        _notificationService = null
        _preferencesManager = null
        
        _authViewModel = null
        _choreViewModel = null
        _householdViewModel = null
        _leaderboardViewModel = null
        _achievementsViewModel = null
    }
    
    // Service getters
    val authService: AuthService get() = _authService!!
    val userService: UserService get() = _userService!!
    val householdService: HouseholdService get() = _householdService!!
    val choreService: ChoreService get() = _choreService!!
    val notificationService: NotificationService get() = _notificationService!!
    val preferencesManager: PreferencesManager get() = _preferencesManager!!
    
    // ViewModel getters
    val authViewModel: AuthViewModel get() = _authViewModel!!
    val choreViewModel: ChoreViewModel get() = _choreViewModel!!
    val householdViewModel: HouseholdViewModel get() = _householdViewModel!!
    val leaderboardViewModel: LeaderboardViewModel get() = _leaderboardViewModel!!
    val achievementsViewModel: AchievementsViewModel get() = _achievementsViewModel!!
}
