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
 * Screen for editing an existing chore
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoreEditScreen(
    choreId: String,
    onBack: () -> Unit,
    onSaveComplete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val TAG = "ChoreEditScreen"
    
    android.util.Log.d(TAG, "Rendering ChoreEditScreen with choreId: $choreId")

    val viewModel = AppContainer.choreViewModel
    val selectedChore by viewModel.selectedChore.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val successMessage by viewModel.successMessage.collectAsState()

    // Initialize editable chore state
    val currentHouseholdId = getValidHouseholdId()
    android.util.Log.d(TAG, "Current householdId: $currentHouseholdId")

    var editableChore by remember(selectedChore) {
        mutableStateOf(selectedChore?.copy() ?: Chore())
    }

    // Load data when screen is displayed
    LaunchedEffect(choreId) {
        // Load existing chore for editing
        android.util.Log.d(TAG, "Loading existing chore with ID: $choreId for editing")
        viewModel.getChoreById(choreId)
    }
    
    // Update editableChore when selectedChore changes
    LaunchedEffect(selectedChore) {
        selectedChore?.let {
            editableChore = it.copy()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Edit Chore") },
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
                LoadingIndicator()
            } else {
                ChoreEditForm(
                    chore = editableChore,
                    householdMembers = householdMembers,
                    onChoreChange = { updatedChore ->
                        android.util.Log.d(TAG, "Chore updated: $updatedChore")
                        editableChore = updatedChore
                    },
                    onSave = {
                        android.util.Log.d(TAG, "Saving edited chore")
                        
                        val validHouseholdIdForSave = editableChore.householdId.ifEmpty {
                            getValidHouseholdId()
                        }
                        
                        android.util.Log.d(TAG, "Chore state at save: $editableChore")

                        if (validHouseholdIdForSave.isEmpty()) {
                            android.util.Log.e(TAG, "ERROR: Cannot save chore, missing valid household ID")
                            viewModel.setError("Cannot save chore: Missing valid household")
                            return@ChoreEditForm
                        }
                        
                        // Ensure the chore has the latest valid householdId
                        val choreToSave = editableChore.copy(householdId = validHouseholdIdForSave)

                        // Update existing chore
                        viewModel.updateChore(choreToSave)
                        // Manually call onSaveComplete since updateChore doesn't have a callback
                        android.util.Log.d(TAG, "Chore updated, navigating back")
                        onSaveComplete()
                    },
                    onCancel = onBack
                )
            }
        }
    }

    // Show error dialog
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

    // Show success message
    successMessage?.let { successMsg ->
        if (successMsg.isNotEmpty()) {
            AlertDialog(
                onDismissRequest = { viewModel.clearSuccess() },
                title = { Text("Success") },
                text = { Text(successMsg) },
                confirmButton = {
                    TextButton(onClick = { 
                        viewModel.clearSuccess()
                        onSaveComplete()
                    }) {
                        Text("OK")
                    }
                }
            )
        }
    }
}
