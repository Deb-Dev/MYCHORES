package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.ui.utils.getValidHouseholdId

/**
 * Screen for creating a new chore
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoreCreateEditScreen(
    choreId: String?,
    onBack: () -> Unit,
    onSaveComplete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val TAG = "ChoreCreateScreen"
    
    android.util.Log.d(TAG, "Rendering ChoreCreateScreen")

    val viewModel = AppContainer.choreViewModel
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val successMessage by viewModel.successMessage.collectAsState()

    // Initialize editable chore state
    val currentHouseholdId = getValidHouseholdId()
    android.util.Log.d(TAG, "Current householdId: $currentHouseholdId")

    var editableChore by remember {
        mutableStateOf(Chore(householdId = currentHouseholdId))
    }

    // Load data when screen is displayed
    LaunchedEffect(Unit) {
        // Initialize for new chore creation
        android.util.Log.d(TAG, "Initializing for new chore creation")
        val validHouseholdId = getValidHouseholdId()
        android.util.Log.d(TAG, "Setting householdId for new chore: $validHouseholdId")
        editableChore = Chore(householdId = validHouseholdId)

        if (validHouseholdId.isNotEmpty()) {
            android.util.Log.d(TAG, "Loading household members for householdId: $validHouseholdId")
            try {
                viewModel.loadHouseholdChores(validHouseholdId) // To populate assignees dropdown
            } catch (e: Exception) {
                android.util.Log.e(TAG, "ERROR loading household members: ${e.message}", e)
                viewModel.setError("Failed to load household data: ${e.message}")
            }
        } else {
            android.util.Log.e(TAG, "ERROR: Empty household ID, cannot load members for new chore")
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "New Chore") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Surface(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (isLoading) {
                LoadingIndicator(fullscreen = true)
            } else {
                ChoreEditForm(
                    chore = editableChore,
                    onChoreChange = { updatedChore -> 
                        android.util.Log.d(TAG, "Chore updated in parent. New point value: ${updatedChore.pointValue}")
                        editableChore = updatedChore 
                    },
                    householdMembers = householdMembers,
                    onSave = {
                        val validHouseholdIdForSave = editableChore.householdId.takeIf { it.isNotEmpty() }
                        
                        android.util.Log.d(TAG, "Save button pressed. Household ID: $validHouseholdIdForSave")
                        android.util.Log.d(TAG, "Chore state at save: $editableChore")
                        android.util.Log.d(TAG, "Point value at save: ${editableChore.pointValue}")
                        
                        // Add code to save the chore with the viewModel
                        viewModel.createChore(
                            title = editableChore.title,
                            description = editableChore.description,
                            householdId = editableChore.householdId,
                            assignedToUserId = editableChore.assignedToUserId,
                            dueDate = editableChore.dueDate,
                            pointValue = editableChore.pointValue,
                            isRecurring = editableChore.isRecurring,
                            recurrenceType = editableChore.recurrenceType,
                            recurrenceDaysOfWeek = editableChore.recurrenceDaysOfWeek,
                            recurrenceDayOfMonth = editableChore.recurrenceDayOfMonth,
                            recurrenceInterval = editableChore.recurrenceInterval,
                            recurrenceEndDate = editableChore.recurrenceEndDate
                        ) { success ->
                            if (success) {
                                onSaveComplete()
                            }
                        }
                    },
                    onCancel = onBack
                )
            }
        }
    }
    
    // Show error dialog if there's an error message
    errorMessage?.let { errorMsg ->
        if (errorMsg.isNotEmpty()) {
            AlertDialog(
                onDismissRequest = { viewModel.clearError() },
                title = { Text("Error") },
                text = { Text(errorMsg) },
                confirmButton = {
                    TextButton(onClick = { viewModel.clearError() }) {
                        Text("OK")
                    }
                }
            )
        }
    }

    // Show success message if there's a success message
    successMessage?.let { successMsg ->
        if (successMsg.isNotEmpty()) {
            AlertDialog(
                onDismissRequest = { viewModel.clearSuccess() },
                title = { Text("Success") },
                text = { Text(successMsg) },
                confirmButton = {
                    TextButton(onClick = { viewModel.clearSuccess() }) {
                        Text("OK")
                    }
                }
            )
        }
    }
}
