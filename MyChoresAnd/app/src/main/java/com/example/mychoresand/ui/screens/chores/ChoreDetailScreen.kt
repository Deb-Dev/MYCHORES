package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TimePickerState
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.ui.components.SecondaryButton
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material3.Switch
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Checkbox
import androidx.compose.ui.window.Dialog
import com.example.mychoresand.ui.screens.chores.getDayName

/**
 * Screen for viewing and editing chore details
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoreDetailScreen(
    choreId: String?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val TAG = "ChoreDetailScreen"
    android.util.Log.d(TAG, "Rendering ChoreDetailScreen with choreId: $choreId")

    val viewModel = AppContainer.choreViewModel
    val selectedChore by viewModel.selectedChore.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    // Determine if we are creating a new chore. This screen no longer supports editing existing chores.
    val isCreatingNewChore = choreId.isNullOrEmpty()

    // Editable chore state - only used when creating a new chore.
    val currentHouseholdId = getValidHouseholdId(AppContainer)
    android.util.Log.d(TAG, "Current householdId for new chore: $currentHouseholdId")

    var editableChore by remember(selectedChore, isCreatingNewChore) {
        mutableStateOf(
            if (isCreatingNewChore) Chore(householdId = currentHouseholdId)
            else selectedChore?.copy() ?: Chore() // Fallback for detail view if selectedChore is null initially
        )
    }

    LaunchedEffect(choreId, isCreatingNewChore) {
        if (!isCreatingNewChore && !choreId.isNullOrEmpty()) {
            // Load existing chore for viewing details
            android.util.Log.d(TAG, "Loading existing chore with ID: $choreId for detail view")
            viewModel.getChoreById(choreId)
        } else if (isCreatingNewChore) {
            // Initialize for new chore creation
            android.util.Log.d(TAG, "Initializing for new chore creation")
            val validHouseholdId = getValidHouseholdId(AppContainer)
            android.util.Log.d(TAG, "Setting householdId for new chore: $validHouseholdId")
            editableChore = Chore(householdId = validHouseholdId) // Ensure a fresh Chore object

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
    }
    
    // Update editableChore when selectedChore changes for the detail view case (though it's not edited)
    LaunchedEffect(selectedChore) {
        if (!isCreatingNewChore) {
            selectedChore?.let {
                editableChore = it.copy() 
            }
        }
    }


    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isCreatingNewChore) "New Chore" else "Chore Details"
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    if (!isCreatingNewChore && selectedChore != null) { // Only show delete for existing chores
                        IconButton(
                            onClick = {
                                selectedChore?.id?.let { id ->
                                    viewModel.deleteChore(id)
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
                }
            )
        },
        floatingActionButton = {
            if (!isCreatingNewChore && selectedChore != null && selectedChore?.isCompleted == false) {
                FloatingActionButton(
                    onClick = {
                        selectedChore?.id?.let { id ->
                            viewModel.completeChore(id)
                            // onBack() // Optionally navigate back, or rely on list refresh
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
            if (isLoading && (isCreatingNewChore || selectedChore == null)) {
                LoadingIndicator(fullscreen = true)
            } else {
                if (isCreatingNewChore) {
                    ChoreEditForm(
                        chore = editableChore,
                        onChoreChange = { updatedChore ->
                            editableChore = updatedChore
                        },
                        householdMembers = householdMembers,
                        onSave = {
                            val validHouseholdIdForSave = editableChore.householdId.takeIf { it.isNotEmpty() } ?: getValidHouseholdId(AppContainer)
                            android.util.Log.d(TAG, "Save button pressed for new chore. Household ID: $validHouseholdIdForSave")
                            android.util.Log.d(TAG, "Chore state at save: $editableChore")

                            if (validHouseholdIdForSave.isEmpty()) {
                                android.util.Log.e(TAG, "ERROR: Cannot create chore, missing valid household ID")
                                viewModel.setError("Cannot create chore: Missing valid household")
                                return@ChoreEditForm
                            }
                            
                            // Ensure the chore being created has the latest valid householdId
                            val choreToCreate = editableChore.copy(householdId = validHouseholdIdForSave)

                            viewModel.createChore(
                                title = choreToCreate.title,
                                description = choreToCreate.description,
                                householdId = choreToCreate.householdId, // Use validated and potentially updated ID
                                assignedToUserId = choreToCreate.assignedToUserId,
                                dueDate = choreToCreate.dueDate,
                                pointValue = choreToCreate.pointValue,
                                isRecurring = choreToCreate.isRecurring,
                                recurrenceType = choreToCreate.recurrenceType,
                                recurrenceInterval = choreToCreate.recurrenceInterval,
                                recurrenceDaysOfWeek = choreToCreate.recurrenceDaysOfWeek,
                                recurrenceDayOfMonth = choreToCreate.recurrenceDayOfMonth,
                                recurrenceEndDate = choreToCreate.recurrenceEndDate,
                                onComplete = { success ->
                                    android.util.Log.d(TAG, "Create chore callback: success=$success")
                                    if (success) {
                                        onBack()
                                    } else {
                                        android.util.Log.e(TAG, "ERROR: Failed to create chore")
                                        // Error message is handled by the viewModel's errorMessage StateFlow
                                    }
                                }
                            )
                        },
                        onCancel = {
                            onBack()
                        }
                    )
                } else { // Viewing details of an existing chore
                    selectedChore?.let { choreToView ->
                        ChoreDetailView(chore = choreToView, householdMembers = householdMembers)
                    } ?: run {
                        if (!isLoading) { // Avoid showing "not found" during initial load
                            Text("Chore not found or an error occurred.", modifier = Modifier.padding(16.dp))
                        }
                    }
                }
            }
        }
    }
    
    // Error state
    val errorMessage by viewModel.errorMessage.collectAsState()
    
    // Success state
    val successMessage by viewModel.successMessage.collectAsState()
    
    // Display error message if there is one
    errorMessage?.let { error ->
        android.util.Log.e(TAG, "Error displayed: $error")
        AlertDialog(
            onDismissRequest = { AppContainer.choreViewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { AppContainer.choreViewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
    
    // Display success message if there is one
    successMessage?.let { message ->
        android.util.Log.d(TAG, "Success message displayed: $message")
        AlertDialog(
            onDismissRequest = { AppContainer.choreViewModel.clearSuccess() },
            title = { Text("Success") },
            text = { Text(message) },
            confirmButton = {
                TextButton(onClick = { AppContainer.choreViewModel.clearSuccess() }) {
                    Text("OK")
                }
            }
        )
    }
}

/**
 * Helper function to get a valid household ID from the AppContainer
 * This is used when creating new chores and we need a valid household ID
 */
private fun getValidHouseholdId(appContainer: AppContainer): String {
    val TAG = "getValidHouseholdId"
    // First try to get it from the auth service
    val firebaseUser = appContainer.authService.currentUser
    android.util.Log.d(TAG, "Firebase User: $firebaseUser")
    
    // Then try the household view model's current user
    val user = appContainer.householdViewModel.currentUser.value
    android.util.Log.d(TAG, "Current user from viewModel: $user")
    
    // If the user has household IDs, use the first one
    if (user != null && user.householdIds.isNotEmpty()) {
        val primaryHouseholdId = user.householdIds.first()
        android.util.Log.d(TAG, "Using user's primary household ID: $primaryHouseholdId")
        return primaryHouseholdId
    }
    
    // Otherwise try to get it from the household view model
    val households = appContainer.householdViewModel.households.value
    android.util.Log.d(TAG, "Households: $households")
    
    if (households.isNotEmpty()) {
        val primaryHouseholdId = households.first().id
        android.util.Log.d(TAG, "Using first household ID from list: $primaryHouseholdId")
        return primaryHouseholdId ?: ""
    }
    
    // If all else fails, check if we have an active household setting
    val activeHouseholdId = appContainer.preferencesManager.getCurrentHouseholdId()
    android.util.Log.d(TAG, "Active household ID from preferences: $activeHouseholdId")
    
    return activeHouseholdId ?: ""
}

@Composable
fun ChoreDetailView(
    chore: Chore,
    householdMembers: List<User>,
    modifier: Modifier = Modifier
) {
    val assignee = householdMembers.find { it.id == chore.assignedToUserId }
    val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Text(
            text = chore.title,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        if (chore.description.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Description",
                        style = MaterialTheme.typography.titleMedium
                    )
                    
                    Text(
                        text = chore.description,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
        }
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Details",
                    style = MaterialTheme.typography.titleMedium
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                DetailRow(
                    label = "Assigned to",
                    value = assignee?.displayName ?: "Unassigned"
                )
                
                DetailRow(
                    label = "Points",
                    value = chore.pointValue.toString()
                )
                
                if (chore.dueDate != null) {
                    DetailRow(
                        label = "Due date",
                        value = dateFormat.format(chore.dueDate!!)
                    )
                }
                
                if (chore.isRecurring) {
                    val recurrenceText = when (chore.recurrenceType) {
                        Chore.RecurrenceType.DAILY -> "Daily"
                        Chore.RecurrenceType.WEEKLY -> "Weekly"
                        Chore.RecurrenceType.MONTHLY -> "Monthly"
                        null -> "None"
                    }
                    
                    DetailRow(
                        label = "Recurrence",
                        value = recurrenceText
                    )
                }
                
                if (chore.isCompleted && chore.completedAt != null) {
                    DetailRow(
                        label = "Completed",
                        value = dateFormat.format(chore.completedAt!!)
                    )
                    
                    val completedBy = householdMembers.find { it.id == chore.completedByUserId }
                    if (completedBy != null) {
                        DetailRow(
                            label = "Completed by",
                            value = completedBy.displayName
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DetailRow(
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoreEditForm(
    chore: Chore,
    onChoreChange: (Chore) -> Unit,
    householdMembers: List<User>,
    onSave: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    val TAG = "ChoreEditForm"
    
    android.util.Log.d(TAG, "Rendering ChoreEditForm with chore: $chore")
    
    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    var showRecurrenceEndDatePicker by remember { mutableStateOf(false) }
    var assigneeDropdownExpanded by remember { mutableStateOf(false) }
    var recurrenceTypeDropdownExpanded by remember { mutableStateOf(false) }
    var showDaysOfWeekDialog by remember { mutableStateOf(false) }
    var dayOfMonthDropdownExpanded by remember { mutableStateOf(false) }

    // Validation states
    var titleError by remember { mutableStateOf("") }
    var hasAttemptedSave by remember { mutableStateOf(false) }

    LaunchedEffect(chore.title, hasAttemptedSave) {
        titleError = if (chore.title.isBlank() && hasAttemptedSave) {
            "Title is required"
        } else {
            ""
        }
    }

    // Get current hour and minute or default from chore
    val calendar = Calendar.getInstance()
    if (chore.dueDate != null) {
        calendar.time = chore.dueDate!!
    }
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    val minute = calendar.get(Calendar.MINUTE)

    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = chore.dueDate?.time ?: System.currentTimeMillis()
    )
    val timePickerState = rememberTimePickerState(
        initialHour = hour,
        initialMinute = minute
    )
    
    // Recurrence end date picker state
    val recurrenceEndDatePickerState = rememberDatePickerState(
        initialSelectedDateMillis = chore.recurrenceEndDate?.time 
            ?: (System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000) // Default to 30 days from now
    )

    val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    val timeFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())

    // Date Picker Dialog
    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d(TAG, "Date selected: ${datePickerState.selectedDateMillis}")
                        datePickerState.selectedDateMillis?.let { millis ->
                            val newDate = Date(millis)
                            val cal = Calendar.getInstance()
                            cal.time = newDate
                            
                            // Preserve existing time if available
                            if (chore.dueDate != null) {
                                val existingCal = Calendar.getInstance()
                                existingCal.time = chore.dueDate!!
                                cal.set(Calendar.HOUR_OF_DAY, existingCal.get(Calendar.HOUR_OF_DAY))
                                cal.set(Calendar.MINUTE, existingCal.get(Calendar.MINUTE))
                            }
                            
                            val updatedChore = chore.copy(dueDate = cal.time)
                            android.util.Log.d(TAG, "Updated chore with new date: ${updatedChore.dueDate}")
                            onChoreChange(updatedChore)
                        }
                        showDatePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
            }
        ) { DatePicker(state = datePickerState) }
    }

    // Time Picker Dialog
    if (showTimePicker) {
        AlertDialog(
            onDismissRequest = { showTimePicker = false },
            title = { Text("Select Time") },
            confirmButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d(TAG, "Time selected: ${timePickerState.hour}:${timePickerState.minute}")
                        val cal = Calendar.getInstance()
                        if (chore.dueDate != null) {
                            cal.time = chore.dueDate!!
                        }
                        cal.set(Calendar.HOUR_OF_DAY, timePickerState.hour)
                        cal.set(Calendar.MINUTE, timePickerState.minute)
                        
                        val updatedChore = chore.copy(dueDate = cal.time)
                        android.util.Log.d(TAG, "Updated chore with new time: ${updatedChore.dueDate}")
                        onChoreChange(updatedChore)
                        showTimePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showTimePicker = false }) { Text("Cancel") }
            },
            text = { TimePicker(state = timePickerState) }
        )
    }

    // DatePickerDialog for Recurrence End Date
    if (showRecurrenceEndDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showRecurrenceEndDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        recurrenceEndDatePickerState.selectedDateMillis?.let { millis ->
                            onChoreChange(chore.copy(recurrenceEndDate = Date(millis)))
                        }
                        showRecurrenceEndDatePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showRecurrenceEndDatePicker = false }) { Text("Cancel") }
            }
        ) { DatePicker(state = recurrenceEndDatePickerState) }
    }

    // Dialog for Days of Week Selection
    if (showDaysOfWeekDialog) {
        DaysOfWeekDialog(
            selectedDays = chore.recurrenceDaysOfWeek ?: emptyList(),
            onDismissRequest = { showDaysOfWeekDialog = false },
            onConfirm = { selectedDays ->
                onChoreChange(chore.copy(recurrenceDaysOfWeek = selectedDays.sorted()))
                showDaysOfWeekDialog = false
            }
        )
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Title field
        OutlinedTextField(
            value = chore.title,
            onValueChange = { 
                android.util.Log.d(TAG, "Title changed: $it")
                onChoreChange(chore.copy(title = it)) 
            },
            label = { Text("Title") },
            placeholder = { Text("Enter chore title...") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            isError = titleError.isNotEmpty(),
            supportingText = {
                if (titleError.isNotEmpty()) {
                    Text(titleError)
                }
            }
        )

        // Description field - Using standard OutlinedTextField
        OutlinedTextField(
            value = chore.description,
            onValueChange = { 
                android.util.Log.d(TAG, "Description changed: $it")
                onChoreChange(chore.copy(description = it)) 
            },
            label = { Text("Description") },
            placeholder = { Text("Enter chore description...") },
            modifier = Modifier
                .fillMaxWidth()
                .height(120.dp),
            maxLines = 5
        )

        // Assigned To Dropdown
        ExposedDropdownMenuBox(
            expanded = assigneeDropdownExpanded,
            onExpandedChange = { assigneeDropdownExpanded = !assigneeDropdownExpanded }
        ) {
            OutlinedTextField(
                value = householdMembers.find { it.id == chore.assignedToUserId }?.displayName ?: "Unassigned",
                onValueChange = {}, // Not directly editable
                label = { Text("Assign To") },
                readOnly = true,
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = assigneeDropdownExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            ExposedDropdownMenu(
                expanded = assigneeDropdownExpanded,
                onDismissRequest = { assigneeDropdownExpanded = false }
            ) {
                DropdownMenuItem(
                    text = { Text("Unassigned") },
                    onClick = {
                        android.util.Log.d(TAG, "Assigned to: Unassigned")
                        onChoreChange(chore.copy(assignedToUserId = null))
                        assigneeDropdownExpanded = false
                    }
                )
                householdMembers.forEach { member ->
                    DropdownMenuItem(
                        text = { Text(member.displayName) },
                        onClick = {
                            android.util.Log.d(TAG, "Assigned to: ${member.displayName} (${member.id})")
                            onChoreChange(chore.copy(assignedToUserId = member.id))
                            assigneeDropdownExpanded = false
                        }
                    )
                }
            }
        }

        // Due Date Picker
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Has Due Date", modifier = Modifier.weight(1f))
            Switch(
                checked = chore.dueDate != null,
                onCheckedChange = { isChecked ->
                    android.util.Log.d(TAG, "Has Due Date toggled: $isChecked")
                    if (isChecked) {
                        if (chore.dueDate == null) {
                            onChoreChange(chore.copy(dueDate = Date(System.currentTimeMillis())))
                        }
                    } else {
                        onChoreChange(chore.copy(dueDate = null))
                    }
                }
            )
        }

        if (chore.dueDate != null) {
            // Date Button
            OutlinedTextField(
                value = dateFormat.format(chore.dueDate!!),
                onValueChange = {},
                label = { Text("Due Date") },
                readOnly = true,
                modifier = Modifier.fillMaxWidth(),
                trailingIcon = {
                    IconButton(onClick = { 
                        android.util.Log.d(TAG, "Opening date picker")
                        showDatePicker = true 
                    }) {
                        Icon(Icons.Default.DateRange, contentDescription = "Select Date")
                    }
                }
            )

            // Time Button
            OutlinedTextField(
                value = timeFormat.format(chore.dueDate!!),
                onValueChange = {},
                label = { Text("Due Time") },
                readOnly = true,
                modifier = Modifier.fillMaxWidth(),
                trailingIcon = {
                    IconButton(onClick = { 
                        android.util.Log.d(TAG, "Opening time picker")
                        showTimePicker = true 
                    }) {
                        Icon(Icons.Default.Schedule, contentDescription = "Select Time")
                    }
                }
            )
        }

        // Points Field - Using a numeric keyboard
        OutlinedTextField(
            value = chore.pointValue.toString(),
            onValueChange = { valueStr ->
                val pointValue = valueStr.toIntOrNull() ?: 1
                android.util.Log.d(TAG, "Points changed: $pointValue")
                onChoreChange(chore.copy(pointValue = pointValue))
            },
            label = { Text("Points") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        // Recurrence Section
        Text("Recurrence", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 16.dp))

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Recurring Chore", modifier = Modifier.weight(1f))
            Switch(
                checked = chore.isRecurring,
                onCheckedChange = { isChecked ->
                    android.util.Log.d(TAG, "Is Recurring toggled: $isChecked")
                    onChoreChange(chore.copy(isRecurring = isChecked))
                }
            )
        }

        if (chore.isRecurring) {
            // Recurrence Type Dropdown
            ExposedDropdownMenuBox(
                expanded = recurrenceTypeDropdownExpanded,
                onExpandedChange = { recurrenceTypeDropdownExpanded = !recurrenceTypeDropdownExpanded }
            ) {
                OutlinedTextField(
                    value = chore.recurrenceType?.displayName ?: "Select Type",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Recurrence Type") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = recurrenceTypeDropdownExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )
                ExposedDropdownMenu(
                    expanded = recurrenceTypeDropdownExpanded,
                    onDismissRequest = { recurrenceTypeDropdownExpanded = false }
                ) {
                    Chore.RecurrenceType.values().forEach { type ->
                        DropdownMenuItem(
                            text = { Text(type.displayName) },
                            onClick = {
                                android.util.Log.d(TAG, "Recurrence type selected: ${type.name}")
                                onChoreChange(chore.copy(recurrenceType = type))
                                recurrenceTypeDropdownExpanded = false
                            }
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(8.dp))

            // Recurrence Interval
            OutlinedTextField(
                value = chore.recurrenceInterval?.toString() ?: "1",
                onValueChange = { value ->
                    val interval = value.toIntOrNull() ?: 1
                    android.util.Log.d(TAG, "Recurrence interval: $interval")
                    onChoreChange(chore.copy(recurrenceInterval = interval))
                },
                label = { Text("Repeat Every (Interval)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            // Days of Week Picker (for Weekly Recurrence)
            if (chore.recurrenceType == Chore.RecurrenceType.WEEKLY) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Days of Week", style = MaterialTheme.typography.bodyLarge)
                    TextButton(onClick = { 
                        android.util.Log.d(TAG, "Opening days of week dialog")
                        showDaysOfWeekDialog = true 
                    }) {
                        Text(
                            // Fix for smart cast issue: make a local copy
                            if (chore.recurrenceDaysOfWeek.isNullOrEmpty()) "Select Days"
                            else {
                                val days = chore.recurrenceDaysOfWeek ?: emptyList()
                                days.map { getDayName(it) }.joinToString(", ")
                            }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Day of Month Picker (for Monthly Recurrence)
            if (chore.recurrenceType == Chore.RecurrenceType.MONTHLY) {
                ExposedDropdownMenuBox(
                    expanded = dayOfMonthDropdownExpanded,
                    onExpandedChange = { dayOfMonthDropdownExpanded = !dayOfMonthDropdownExpanded }
                ) {
                    OutlinedTextField(
                        value = chore.recurrenceDayOfMonth?.toString() ?: "Same day as first occurrence",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Day of Month") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = dayOfMonthDropdownExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = dayOfMonthDropdownExpanded,
                        onDismissRequest = { dayOfMonthDropdownExpanded = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Same day as first occurrence") },
                            onClick = {
                                android.util.Log.d(TAG, "Day of month: Same day as first occurrence")
                                onChoreChange(chore.copy(recurrenceDayOfMonth = null))
                                dayOfMonthDropdownExpanded = false
                            }
                        )
                        (1..28).forEach { day ->
                            DropdownMenuItem(
                                text = { Text(day.toString()) },
                                onClick = {
                                    android.util.Log.d(TAG, "Day of month selected: $day")
                                    onChoreChange(chore.copy(recurrenceDayOfMonth = day))
                                    dayOfMonthDropdownExpanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            // Recurrence End Date Switch and Picker
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
            ) {
                Text("Has End Date", modifier = Modifier.weight(1f))
                Switch(
                    checked = chore.recurrenceEndDate != null,
                    onCheckedChange = { isChecked ->
                        android.util.Log.d(TAG, "Has End Date toggled: $isChecked")
                        if (isChecked) {
                            if (chore.recurrenceEndDate == null) {
                                val initialEndDate = chore.dueDate?.let { Date(it.time + 30L * 24 * 60 * 60 * 1000) } 
                                    ?: Date(System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000)
                                onChoreChange(chore.copy(recurrenceEndDate = initialEndDate))
                            }
                            showRecurrenceEndDatePicker = true
                        } else {
                            onChoreChange(chore.copy(recurrenceEndDate = null))
                        }
                    }
                )
            }

            if (chore.recurrenceEndDate != null) {
                OutlinedTextField(
                    value = dateFormat.format(chore.recurrenceEndDate!!),
                    onValueChange = {},
                    label = { Text("End Date") },
                    readOnly = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    trailingIcon = {
                        IconButton(onClick = { 
                            android.util.Log.d(TAG, "Opening recurrence end date picker")
                            showRecurrenceEndDatePicker = true 
                        }) {
                            Icon(Icons.Default.DateRange, contentDescription = "Change Recurrence End Date")
                        }
                    }
                )
            }
        }

        // Save and Cancel Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            SecondaryButton(onClick = {
                android.util.Log.d(TAG, "Cancel button clicked")
                onCancel()
            }, text = "Cancel")
            Spacer(modifier = Modifier.padding(horizontal = 4.dp))
            PrimaryButton(
                onClick = {
                    android.util.Log.d(TAG, "Save button clicked. Title blank: ${chore.title.isBlank()}")
                    hasAttemptedSave = true
                    if (chore.title.isNotBlank()) {
                        android.util.Log.d(TAG, "Saving chore: $chore")
                        onSave()
                    }
                },
                text = "Save Chore"
            )
        }
    }
}

