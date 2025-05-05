package com.example.mychoresand.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.services.ChoreService
import com.example.mychoresand.services.UserService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import java.util.Date

/**
 * ViewModel handling chore-related operations
 */
class ChoreViewModel(
    private val choreService: ChoreService,
    private val userService: UserService
) : ViewModel() {
    
    companion object {
        private const val TAG = "ChoreViewModel"
    }
    
    // Pending chores state
    private val _pendingChores = MutableStateFlow<List<Chore>>(emptyList())
    val pendingChores: StateFlow<List<Chore>> = _pendingChores
    
    // Completed chores state
    private val _completedChores = MutableStateFlow<List<Chore>>(emptyList())
    val completedChores: StateFlow<List<Chore>> = _completedChores
    
    // Current household members
    private val _householdMembers = MutableStateFlow<List<User>>(emptyList())
    val householdMembers: StateFlow<List<User>> = _householdMembers
    
    // Selected chore for viewing details
    private val _selectedChore = MutableStateFlow<Chore?>(null)
    val selectedChore: StateFlow<Chore?> = _selectedChore
    
    // Loading states
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    // Error message
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage
    
    /**
     * Load chores for a household
     * @param householdId The ID of the household to load chores for
     */
    fun loadHouseholdChores(householdId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            
            // Load pending chores
            choreService.getHouseholdChores(householdId, false).collect { chores ->
                _pendingChores.value = chores
            }
            
            // Load completed chores
            choreService.getHouseholdChores(householdId, true).collect { chores ->
                _completedChores.value = chores
            }
            
            // Load household members
            userService.getHouseholdUsers(householdId).collect { users ->
                _householdMembers.value = users
            }
            
            _isLoading.value = false
        }
    }
    
    /**
     * Load chores assigned to the current user
     */
    fun loadUserChores() {
        viewModelScope.launch {
            _isLoading.value = true
            
            // Load pending chores
            choreService.getUserChores(false).collect { chores ->
                _pendingChores.value = chores
            }
            
            // Load completed chores
            choreService.getUserChores(true).collect { chores ->
                _completedChores.value = chores
            }
            
            _isLoading.value = false
        }
    }
    
    /**
     * Select a chore to view its details
     * @param choreId The ID of the chore to select
     */
    fun selectChore(choreId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            
            choreService.getChore(choreId).collect { chore ->
                _selectedChore.value = chore
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Clear the selected chore
     */
    fun clearSelectedChore() {
        _selectedChore.value = null
    }
    
    /**
     * Create a new chore
     * @param title Chore title
     * @param description Chore description
     * @param householdId Household ID
     * @param assignedToUserId User ID of the assignee (can be null)
     * @param dueDate Due date (can be null)
     * @param pointValue Point value for completing the chore
     * @param isRecurring Whether the chore recurs
     * @param recurrenceType Type of recurrence (daily, weekly, monthly)
     * @param recurrenceInterval Interval between recurrences
     * @param recurrenceDaysOfWeek Days of week for weekly recurrence
     * @param recurrenceDayOfMonth Day of month for monthly recurrence
     * @param recurrenceEndDate End date for recurrence
     */
    fun createChore(
        title: String,
        description: String,
        householdId: String,
        assignedToUserId: String?,
        dueDate: Date?,
        pointValue: Int,
        isRecurring: Boolean = false,
        recurrenceType: Chore.RecurrenceType? = null,
        recurrenceInterval: Int? = null,
        recurrenceDaysOfWeek: List<Int>? = null,
        recurrenceDayOfMonth: Int? = null,
        recurrenceEndDate: Date? = null
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            
            val chore = Chore(
                title = title,
                description = description,
                householdId = householdId,
                assignedToUserId = assignedToUserId,
                dueDate = dueDate,
                pointValue = pointValue,
                isRecurring = isRecurring,
                recurrenceType = recurrenceType,
                recurrenceInterval = recurrenceInterval,
                recurrenceDaysOfWeek = recurrenceDaysOfWeek,
                recurrenceDayOfMonth = recurrenceDayOfMonth,
                recurrenceEndDate = recurrenceEndDate,
                createdAt = Date()
            )
            
            val result = choreService.createChore(chore)
            
            result.fold(
                onSuccess = {
                    // Refresh the chore list
                    loadHouseholdChores(householdId)
                },
                onFailure = { error ->
                    _errorMessage.value = error.message ?: "Failed to create chore"
                }
            )
            
            _isLoading.value = false
        }
    }
    
    /**
     * Update an existing chore
     * @param chore The chore with updated values
     */
    fun updateChore(chore: Chore) {
        viewModelScope.launch {
            _isLoading.value = true
            
            val result = choreService.updateChore(chore)
            
            result.fold(
                onSuccess = {
                    // Refresh the chore list and selected chore
                    loadHouseholdChores(chore.householdId)
                    _selectedChore.value = chore
                },
                onFailure = { error ->
                    _errorMessage.value = error.message ?: "Failed to update chore"
                }
            )
            
            _isLoading.value = false
        }
    }
    
    /**
     * Get a chore by ID - equivalent to loadChore in iOS
     */
    fun getChoreById(choreId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                // Updated to properly collect the Flow
                choreService.getChore(choreId).collect { chore ->
                    _selectedChore.value = chore
                }
            } catch (e: Exception) {
                // Improved error handling with logging
                _errorMessage.value = e.message ?: "Error loading chore"
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Delete a chore
     */
    fun deleteChore(choreId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                // Updated to handle Result type
                val result = choreService.deleteChore(choreId)
                
                result.fold(
                    onSuccess = {
                        // Remove from pending and completed lists if present
                        _pendingChores.value = _pendingChores.value.filter { it.id != choreId }
                        _completedChores.value = _completedChores.value.filter { it.id != choreId }
                        
                        // Clear selected chore if it was the deleted one
                        if (_selectedChore.value?.id == choreId) {
                            _selectedChore.value = null
                        }
                    },
                    onFailure = { e ->
                        _errorMessage.value = e.message ?: "Error deleting chore"
                    }
                )
            } catch (e: Exception) {
                // Fallback error handling
                _errorMessage.value = e.message ?: "Error deleting chore"
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Mark a chore as complete
     */
    fun completeChore(choreId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            try {
                // Updated to handle Result type
                val result = choreService.completeChore(choreId)
                
                result.fold(
                    onSuccess = { completedChore ->
                        // Move chore from pending to completed lists
                        _pendingChores.value = _pendingChores.value.filter { it.id != choreId }
                        _completedChores.value = _completedChores.value + completedChore
                        
                        // Update selected chore if needed
                        if (_selectedChore.value?.id == choreId) {
                            _selectedChore.value = completedChore
                        }
                        
                        // Show points earned message
                        _errorMessage.value = "You earned ${completedChore.pointValue} points!"
                    },
                    onFailure = { e ->
                        _errorMessage.value = e.message ?: "Error completing chore"
                    }
                )
            } catch (e: Exception) {
                // Fallback error handling
                _errorMessage.value = e.message ?: "Error completing chore"
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    /**
     * Clear any error messages
     */
    fun clearError() {
        _errorMessage.value = null
    }
}
