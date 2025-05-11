package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.ui.components.LoadingIndicator

/**
 * Screen for viewing chore details (read-only)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoreViewScreen(
    choreId: String,
    onBack: () -> Unit,
    onEdit: (String) -> Unit,
    onDelete: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val TAG = "ChoreViewScreen"
    android.util.Log.d(TAG, "Rendering ChoreViewScreen with choreId: $choreId")

    val viewModel = AppContainer.choreViewModel
    val selectedChore by viewModel.selectedChore.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val successMessage by viewModel.successMessage.collectAsState()

    // Load data when screen is displayed
    LaunchedEffect(choreId) {
        android.util.Log.d(TAG, "Loading chore with ID: $choreId for detail view")
        viewModel.getChoreById(choreId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = "Chore Details") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    // Edit button
                    IconButton(
                        onClick = { 
                            selectedChore?.id?.let { id ->
                                onEdit(id)
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "Edit"
                        )
                    }
                    
                    // Delete button
                    IconButton(
                        onClick = {
                            selectedChore?.id?.let { id ->
                                onDelete(id)
                                onBack()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Delete"
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            if (selectedChore != null && selectedChore?.isCompleted == false) {
                FloatingActionButton(
                    onClick = {
                        selectedChore?.id?.let { id ->
                            viewModel.completeChore(id)
                        }
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Mark Complete"
                    )
                }
            }
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
                selectedChore?.let { choreToView ->
                    ChoreDetailView(chore = choreToView, householdMembers = householdMembers)
                } ?: run {
                    Text("Chore not found or an error occurred.", modifier = Modifier.padding(16.dp))
                }
            }
        }
    }
    
    // Display error message if there is one
    errorMessage?.let { error ->
        android.util.Log.e(TAG, "Error displayed: $error")
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
    
    // Display success message if there is one
    successMessage?.let { message ->
        android.util.Log.d(TAG, "Success message displayed: $message")
        AlertDialog(
            onDismissRequest = { viewModel.clearSuccess() },
            title = { Text("Success") },
            text = { Text(message) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearSuccess() }) {
                    Text("OK")
                }
            }
        )
    }
}
