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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Date
import kotlinx.coroutines.delay // For clearing messages

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

    // Success message
    private val _successMessage = MutableStateFlow<String?>(null)
    val successMessage: StateFlow<String?> = _successMessage

    // Badge earned message
    private val _badgeEarnedMessage = MutableStateFlow<String?>(null)
    val badgeEarnedMessage: StateFlow<String?> = _badgeEarnedMessage

    /**
     * Load chores for a household and its members.
     * Ensures that both pending and completed chores are fetched,
     * along with the list of household members.
     * @param householdId The ID of the household to load data for.
     */
    fun loadHouseholdChores(householdId: String) {
        if (householdId.isBlank()) {
            Log.e(TAG, "Cannot load household chores: blank householdId")
            return
        }
        
        Log.d(TAG, "🔄 Loading household chores for householdId: $householdId")
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                // Load pending chores - using collect instead of first() to prevent Flow issues
                Log.d(TAG, "📋 Fetching pending chores...")
                choreService.getHouseholdChores(householdId, false).collect { chores ->
                    Log.d(TAG, "✅ Fetched ${chores.size} pending chores")
                    _pendingChores.value = chores
                }

                // Load completed chores - using collect instead of first() to prevent Flow issues
                Log.d(TAG, "📋 Fetching completed chores...")
                choreService.getHouseholdChores(householdId, true).collect { chores ->
                    Log.d(TAG, "✅ Fetched ${chores.size} completed chores")
                    _completedChores.value = chores
                }

                // Load household members - using collect instead of first() to prevent Flow issues
                Log.d(TAG, "👥 Fetching household members...")
                userService.getHouseholdUsers(householdId).collect { users ->
                    Log.d(TAG, "✅ Fetched ${users.size} household members")
                    _householdMembers.value = users
                }
                
                Log.d(TAG, "✅ Successfully loaded all household data")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error loading household chores or members: ${e.message}", e)
                _errorMessage.value = "Failed to load household data: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    /**
     * Load chores assigned to the current user.
     * Fetches both pending and completed chores for the logged-in user.
     */
    fun loadUserChores() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                // Load pending chores
                choreService.getUserChores(false).collect { chores ->
                    _pendingChores.value = chores
                }

                // Load completed chores
                choreService.getUserChores(true).collect { chores ->
                    _completedChores.value = chores
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading user chores: ${'$'}{e.message}", e)
                _errorMessage.value = "Failed to load your chores: ${'$'}{e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    /**
     * Select a chore to view its details.
     * Fetches the chore by its ID and updates the selectedChore state.
     * @param choreId The ID of the chore to select.
     */
    fun selectChore(choreId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                choreService.getChore(choreId).collect { chore ->
                    _selectedChore.value = chore
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error selecting chore: ${'$'}{e.message}", e)
                _errorMessage.value = "Failed to load chore details: ${'$'}{e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    /**
     * Clear the selected chore.
     * Resets the selectedChore state to null.
     */
    fun clearSelectedChore() {
        _selectedChore.value = null
    }

    /**
     * Create a new chore.
     * Matches the iOS implementation by taking individual parameters.
     * @param onComplete Callback invoked with true on success, false on failure.
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
        recurrenceEndDate: Date? = null,
        onComplete: ((Boolean) -> Unit)? = null
    ) {
        if (householdId.isBlank()) {
            _errorMessage.value = "Cannot create chore: Missing household ID"
            Log.e(TAG, "createChore Error: Missing householdId. Title: $title")
            onComplete?.invoke(false)
            return
        }

        Log.d(TAG, "Attempting to create chore. Title: $title, HouseholdId: $householdId, DueDate: $dueDate, IsRecurring: $isRecurring")
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            _successMessage.value = null

            val chore = Chore(
                // id will be generated by service or Firestore
                title = title,
                description = description,
                householdId = householdId, // Crucial field
                assignedToUserId = assignedToUserId,
                // createdByUserId will be set by ChoreService
                dueDate = dueDate,
                pointValue = pointValue,
                isRecurring = isRecurring,
                recurrenceType = recurrenceType,
                recurrenceInterval = recurrenceInterval,
                recurrenceDaysOfWeek = recurrenceDaysOfWeek,
                recurrenceDayOfMonth = recurrenceDayOfMonth,
                recurrenceEndDate = recurrenceEndDate,
                createdAt = Date(), // ChoreService will also set this, service's value is definitive
                nextOccurrenceDate = if (isRecurring && dueDate != null) dueDate else null // Ensure dueDate is not null for initial nextOccurrenceDate if recurring
            )

            Log.d(TAG, "Chore object constructed in ViewModel: $chore")
            val result = choreService.createChore(chore)

            result.fold(
                onSuccess = { newChore ->
                    Log.d(TAG, "✅ Chore created successfully via service: ${newChore.id}, Title: ${newChore.title}, Household: ${newChore.householdId}")
                    // Add to pending chores list immediately, similar to iOS
                    _pendingChores.value = _pendingChores.value + newChore
                    _successMessage.value = "Chore created successfully!"
                    viewModelScope.launch {
                        delay(2000)
                        _successMessage.value = null
                    }
                    // Reload all chores for the household to ensure UI consistency
                    loadHouseholdChores(householdId)
                    onComplete?.invoke(true)
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to create chore via service. Title: $title, HouseholdID: $householdId, Error: ${error.message}", error)
                    _errorMessage.value = "Failed to create chore: ${error.message}"
                    onComplete?.invoke(false)
                }
            )
            _isLoading.value = false
        }
    }

    /**
     * Update an existing chore.
     * @param chore The chore object with updated values.
     */
    fun updateChore(chore: Chore) {
        val choreId = chore.id
        if (choreId == null) {
            _errorMessage.value = "Cannot update chore: Missing chore ID"
            Log.e(TAG, "Cannot update chore: Missing chore ID")
            return
        }

        Log.d(TAG, "Updating chore: ${chore.title} (ID: ${choreId})")
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            _successMessage.value = null

            val result = choreService.updateChore(chore)

            result.fold(
                onSuccess = {
                    Log.d(TAG, "✅ Chore updated successfully: ${choreId}")
                    
                    // Update the chore in our local state
                    val updatedPendingChores = _pendingChores.value.map {
                        if (it.id == choreId) chore else it
                    }
                    _pendingChores.value = updatedPendingChores
                    
                    // Also update in completed chores if it exists there
                    val updatedCompletedChores = _completedChores.value.map {
                        if (it.id == choreId) chore else it
                    }
                    _completedChores.value = updatedCompletedChores
                    
                    // Update selected chore if this is the one currently selected
                    if (_selectedChore.value?.id == choreId) {
                        _selectedChore.value = chore
                    }
                    
                    _successMessage.value = "Chore updated successfully!"
                    viewModelScope.launch {
                        delay(2000)
                        _successMessage.value = null
                    }
                    // Refresh household chores and selected chore
                    loadHouseholdChores(chore.householdId)
                    if (_selectedChore.value?.id == choreId) {
                        // Re-fetch the selected chore to get the latest version
                        choreService.getChore(choreId).collect { updatedChore ->
                            _selectedChore.value = updatedChore
                        }
                    }
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to update chore: ${error.message}", error)
                    _errorMessage.value = "Failed to update chore: ${error.message}"
                }
            )
            _isLoading.value = false
        }
    }
    
    /**
     * Get a chore by ID - equivalent to loadChore in iOS ChoreViewModel.
     * This is an alias for selectChore for clarity when just fetching.
     * @param choreId The ID of the chore to fetch.
     */
    fun getChoreById(choreId: String) {
        selectChore(choreId)
    }

    /**
     * Delete a chore.
     * @param choreId The ID of the chore to delete.
     */
    fun deleteChore(choreId: String) {
        Log.d(TAG, "Deleting chore: ID $choreId")
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            _successMessage.value = null

            val result = choreService.deleteChore(choreId)

            result.fold(
                onSuccess = {
                    Log.d(TAG, "✅ Chore deleted successfully: $choreId")
                    _pendingChores.value = _pendingChores.value.filter { it.id != choreId }
                    _completedChores.value = _completedChores.value.filter { it.id != choreId }
                    if (_selectedChore.value?.id == choreId) {
                        _selectedChore.value = null
                    }
                    _successMessage.value = "Chore deleted."
                     viewModelScope.launch {
                        delay(2000)
                        _successMessage.value = null
                    }
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to delete chore: ${error.message}", error)
                    _errorMessage.value = "Failed to delete chore: ${error.message}"
                }
            )
            _isLoading.value = false
        }
    }

    /**
     * Mark a chore as complete.
     * @param choreId The ID of the chore to complete.
     */
    fun completeChore(choreId: String) {
        Log.d(TAG, "Completing chore: ID $choreId")
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            _successMessage.value = null
            _badgeEarnedMessage.value = null


            val result = choreService.completeChore(choreId)

            result.fold(
                onSuccess = { completedChore ->
                    Log.d(TAG, "✅ Chore completed successfully: ${completedChore.id}")
                    
                    // First update our local state
                    _pendingChores.value = _pendingChores.value.filter { it.id != choreId }
                    _completedChores.value = (_completedChores.value + completedChore)
                        .distinctBy { it.id } // Ensure no duplicates if already present
                        .sortedByDescending { it.completedAt }

                    if (_selectedChore.value?.id == choreId) {
                        _selectedChore.value = completedChore
                    }
                    
                    _successMessage.value = "You earned ${completedChore.pointValue} points!"
                    
                    // Then reload from Firestore to ensure we have the latest data
                    // This is crucial for reflecting the next occurrence chore if this was a recurring one
                    if (completedChore.householdId.isNotBlank()) {
                        Log.d(TAG, "🔄 Reloading household chores after completion")
                        loadHouseholdChores(completedChore.householdId)
                    } else {
                        Log.e(TAG, "⚠️ Cannot reload household chores: completedChore has blank householdId")
                    }

                    // Placeholder for badge earned message - In a real app,
                    // this might come from observing UserService or a global notification system.
                    // For now, we assume ChoreService's call to userService.checkAndAwardBadges
                    // handles the backend logic. If UserService had a flow for new badges, we'd collect it here.
                    // Example: _badgeEarnedMessage.value = "New badge unlocked: First Chore!"
                    Log.d(TAG, "Badge check would be triggered here if UserService provided a direct feedback mechanism for new badges.")

                    viewModelScope.launch {
                        delay(3000) // Longer delay for points + potential badge
                        _successMessage.value = null
                        _badgeEarnedMessage.value = null
                    }
                     // Reload household chores to reflect any newly created recurring chores
                    completedChore.householdId.let { hid -> loadHouseholdChores(hid) }
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to complete chore: ${error.message}", error)
                    _errorMessage.value = "Failed to complete chore: ${error.message}"
                }
            )
            _isLoading.value = false
        }
    }

    /**
     * Clear any error messages.
     */
    fun clearError() {
        _errorMessage.value = null
    }

    /**
     * Set an error message to display to the user.
     */
    fun setError(message: String) {
        _errorMessage.value = message
    }

    /**
     * Set a success message to display to the user.
     */
    fun setSuccess(message: String) {
        _successMessage.value = message
        viewModelScope.launch {
            delay(2000)
            _successMessage.value = null
        }
    }
    
    /**
     * Clear any success message.
     */
    fun clearSuccess() {
        _successMessage.value = null
    }

    /**
     * Clear any badge earned message.
     */
    fun clearBadgeEarnedMessage() {
        _badgeEarnedMessage.value = null
    }
}
