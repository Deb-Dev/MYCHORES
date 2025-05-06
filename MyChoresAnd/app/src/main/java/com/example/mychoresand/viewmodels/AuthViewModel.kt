package com.example.mychoresand.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.services.AuthService
import com.example.mychoresand.services.NotificationService
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel handling authentication state and operations
 */
class AuthViewModel(
    private val authService: AuthService,
    private val notificationService: NotificationService
) : ViewModel() {
    
    // Authentication state
    private val _authState = MutableStateFlow<AuthState>(AuthState.Loading)
    val authState: StateFlow<AuthState> = _authState
    
    // Error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    init {
        // Check initial authentication state
        val currentUser = authService.currentUser
        _authState.value = if (currentUser != null) {
            AuthState.Authenticated(currentUser)
        } else {
            AuthState.Unauthenticated
        }
        
        // Set up notification channels
        notificationService.createNotificationChannels()
    }
    
    /**
     * Sign in with email and password
     * @param email User's email
     * @param password User's password
     */
    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            
            val result = authService.signIn(email, password)
            
            result.fold(
                onSuccess = { user ->
                    _authState.value = AuthState.Authenticated(user)
                    
                    // Update FCM token and subscribe to notifications
                    authService.updateFcmToken()
                    notificationService.subscribeToNotifications()
                },
                onFailure = { error ->
                    _authState.value = AuthState.Unauthenticated
                    
                    // Map common Firebase error messages to more user-friendly messages
                    val errorMsg = when {
                        error.message?.contains("badly formatted") == true -> "Please enter a valid email address"
                        error.message?.contains("password is invalid") == true -> "Incorrect password"
                        error.message?.contains("no user record") == true -> "No account found with this email"
                        else -> error.message ?: "Authentication failed"
                    }
                    
                    _errorMessage.value = errorMsg
                }
            )
        }
    }
    
    /**
     * Create a new account with email and password
     * @param email User's email
     * @param password User's password
     * @param name User's display name
     */
    fun createAccount(email: String, password: String, name: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            
            val result = authService.createAccount(email, password, name)
            
            result.fold(
                onSuccess = { user ->
                    _authState.value = AuthState.Authenticated(user)
                    
                    // Update FCM token and subscribe to notifications
                    authService.updateFcmToken()
                    notificationService.subscribeToNotifications()
                },
                onFailure = { error ->
                    _authState.value = AuthState.Unauthenticated
                    
                    // Map common Firebase error messages to more user-friendly messages
                    val errorMsg = when {
                        error.message?.contains("badly formatted") == true -> "Please enter a valid email address"
                        error.message?.contains("password") == true && error.message?.contains("weak") == true -> "Password is too weak"
                        error.message?.contains("email address is already in use") == true -> "This email is already registered"
                        else -> error.message ?: "Account creation failed"
                    }
                    
                    _errorMessage.value = errorMsg
                }
            )
        }
    }
    
    /**
     * Sign out the current user
     */
    fun signOut() {
        authService.signOut()
        _authState.value = AuthState.Unauthenticated
    }
    
    /**
     * Send a password reset email
     * @param email The email address to send the reset link to
     */
    fun sendPasswordResetEmail(email: String) {
        viewModelScope.launch {
            val result = authService.sendPasswordResetEmail(email)
            
            _errorMessage.value = result.fold(
                onSuccess = { "Password reset email sent" },
                onFailure = { it.message ?: "Failed to send password reset email" }
            )
        }
    }
    
    /**
     * Clear any error messages
     */
    fun clearError() {
        _errorMessage.value = null
    }
}

/**
 * Sealed class representing different authentication states
 */
sealed class AuthState {
    object Loading : AuthState()
    object Unauthenticated : AuthState()
    data class Authenticated(val user: FirebaseUser) : AuthState()
}
