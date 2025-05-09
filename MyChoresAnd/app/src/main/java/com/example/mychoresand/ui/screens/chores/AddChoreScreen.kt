package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.ui.components.SecondaryButton
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

// Helper function to get a valid household ID (moved here for now)
private fun getValidHouseholdId(appContainer: AppContainer): String {
    val TAG = "AddChoreScreen.getValidHouseholdId" // More specific tag
    val prefsHouseholdId = appContainer.preferencesManager.getCurrentHouseholdId()
    android.util.Log.d(TAG, "Attempting to get household ID. From Preferences: '$prefsHouseholdId'")

    if (!prefsHouseholdId.isNullOrBlank()) {
        android.util.Log.d(TAG, "Using household ID from PreferencesManager: '$prefsHouseholdId'")
        return prefsHouseholdId
    }
    android.util.Log.w(TAG, "Household ID from PreferencesManager is null or blank. Attempting fallbacks.")

    val user = appContainer.householdViewModel.currentUser.value
    android.util.Log.d(TAG, "Fallback: Current user from viewModel: $user")
    if (user != null && user.householdIds.isNotEmpty()) {
        val userPrimaryHouseholdId = user.householdIds.first()
        android.util.Log.d(TAG, "Fallback: Using user's primary household ID: '$userPrimaryHouseholdId'")
        // Consider if this should also update PreferencesManager if it was blank:
        // appContainer.preferencesManager.setCurrentHouseholdId(userPrimaryHouseholdId)
        return userPrimaryHouseholdId
    }
    android.util.Log.w(TAG, "Fallback: User is null or has no household IDs.")

    val households = appContainer.householdViewModel.households.value
    android.util.Log.d(TAG, "Fallback: Households from viewModel: $households")
    if (households.isNotEmpty()) {
        val firstHouseholdId = households.first().id
        if (!firstHouseholdId.isNullOrBlank()) {
            android.util.Log.d(TAG, "Fallback: Using first household ID from list: '$firstHouseholdId'")
            // Consider if this should also update PreferencesManager if it was blank:
            // appContainer.preferencesManager.setCurrentHouseholdId(firstHouseholdId)
            return firstHouseholdId
        }
        android.util.Log.w(TAG, "Fallback: First household from list has null or blank ID.")
    }
    android.util.Log.e(TAG, "CRITICAL: No valid household ID found through any method. UI should prevent chore creation.")
    return "" // This will cause form validation (isFormValid) to fail
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddChoreScreen(
    onBack: () -> Unit,
    appContainer: AppContainer
) {
    val TAG = "AddChoreScreen"
    val viewModel = appContainer.choreViewModel
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoadingMembers by viewModel.isLoading.collectAsState() // Assuming this reflects member loading
    val errorMessage by viewModel.errorMessage.collectAsState()

    // Chore properties state
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var assignedToUserId by remember { mutableStateOf<String?>(null) }
    var dueDate by remember { mutableStateOf<Date?>(Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000)) } // Tomorrow
    var hasDueDate by remember { mutableStateOf(true) } // Matches screenshot initial state
    var pointValue by remember { mutableStateOf(1) }
    var isRecurring by remember { mutableStateOf(false) }
    var recurrenceType by remember { mutableStateOf(Chore.RecurrenceType.WEEKLY) }
    var recurrenceInterval by remember { mutableStateOf(1) }
    var recurrenceDaysOfWeek by remember { mutableStateOf<List<Int>>(emptyList()) }
    var recurrenceDayOfMonth by remember { mutableStateOf<Int?>(null) }
    var recurrenceEndDate by remember { mutableStateOf<Date?>(null) }
    var hasRecurrenceEndDate by remember { mutableStateOf(false) }

    // UI state for pickers/dialogs
    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    var assigneeDropdownExpanded by remember { mutableStateOf(false) }
    var recurrenceTypeDropdownExpanded by remember { mutableStateOf(false) }
    var showDaysOfWeekDialog by remember { mutableStateOf(false) }
    var dayOfMonthDropdownExpanded by remember { mutableStateOf(false) }
    var showRecurrenceEndDatePicker by remember { mutableStateOf(false) }

    var titleError by remember { mutableStateOf("") }
    var hasAttemptedSave by remember { mutableStateOf(false) }

    val currentHouseholdId = remember { getValidHouseholdId(appContainer) }

    LaunchedEffect(currentHouseholdId) {
        if (currentHouseholdId.isNotEmpty()) {
            android.util.Log.d(TAG, "Loading household members for householdId: $currentHouseholdId")
            try {
                viewModel.loadHouseholdChores(currentHouseholdId) // This loads members too
            } catch (e: Exception) {
                android.util.Log.e(TAG, "ERROR loading household data: ${e.message}", e)
                viewModel.setError("Failed to load household data: ${e.message}")
            }
        } else {
            android.util.Log.e(TAG, "ERROR: Empty household ID, cannot load members")
            viewModel.setError("Cannot create chore: Missing household information.")
        }
    }

    LaunchedEffect(title, hasAttemptedSave) {
        titleError = if (title.isBlank() && hasAttemptedSave) "Title is required" else ""
    }

    val isFormValid = title.isNotBlank() && currentHouseholdId.isNotBlank()

    val datePickerState = rememberDatePickerState(initialSelectedDateMillis = dueDate?.time ?: System.currentTimeMillis())
    val timePickerState = rememberTimePickerState(
        initialHour = Calendar.getInstance().apply { time = dueDate ?: Date() }.get(Calendar.HOUR_OF_DAY),
        initialMinute = Calendar.getInstance().apply { time = dueDate ?: Date() }.get(Calendar.MINUTE)
    )
    val recurrenceEndDatePickerState = rememberDatePickerState(
        initialSelectedDateMillis = recurrenceEndDate?.time ?: (System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000)
    )

    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    val timeFormat = remember { SimpleDateFormat("hh:mm a", Locale.getDefault()) }

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            val newCal = Calendar.getInstance().apply { timeInMillis = millis }
                            val existingCal = Calendar.getInstance().apply { time = dueDate ?: Date() }
                            newCal.set(Calendar.HOUR_OF_DAY, existingCal.get(Calendar.HOUR_OF_DAY))
                            newCal.set(Calendar.MINUTE, existingCal.get(Calendar.MINUTE))
                            dueDate = newCal.time
                        }
                        showDatePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { showDatePicker = false }) { Text("Cancel") } }
        ) { DatePicker(state = datePickerState) }
    }

    if (showTimePicker) {
        TimePickerDialog( // Using a more standard TimePickerDialog if available, else AlertDialog wrapper
            onDismissRequest = { showTimePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        val cal = Calendar.getInstance().apply { time = dueDate ?: Date() }
                        cal.set(Calendar.HOUR_OF_DAY, timePickerState.hour)
                        cal.set(Calendar.MINUTE, timePickerState.minute)
                        dueDate = cal.time
                        showTimePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { showTimePicker = false }) { Text("Cancel") } }
        ) { TimePicker(state = timePickerState) }
    }
    
    if (showRecurrenceEndDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showRecurrenceEndDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        recurrenceEndDatePickerState.selectedDateMillis?.let { millis ->
                            recurrenceEndDate = Date(millis)
                        }
                        showRecurrenceEndDatePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { showRecurrenceEndDatePicker = false }) { Text("Cancel") } }
        ) { DatePicker(state = recurrenceEndDatePickerState) }
    }

    if (showDaysOfWeekDialog) {
        DaysOfWeekDialog(
            selectedDays = recurrenceDaysOfWeek,
            onDismissRequest = { showDaysOfWeekDialog = false },
            onConfirm = { selectedDays: List<Int> -> // EXPLICITLY TYPED
                recurrenceDaysOfWeek = selectedDays.sorted()
                showDaysOfWeekDialog = false
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Chore") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            hasAttemptedSave = true
                            if (isFormValid) {
                                viewModel.createChore(
                                    title = title,
                                    description = description,
                                    householdId = currentHouseholdId,
                                    assignedToUserId = assignedToUserId,
                                    dueDate = if (hasDueDate) dueDate else null,
                                    pointValue = pointValue,
                                    isRecurring = isRecurring,
                                    recurrenceType = if (isRecurring) recurrenceType else null,
                                    recurrenceInterval = if (isRecurring) recurrenceInterval else null,
                                    recurrenceDaysOfWeek = if (isRecurring && recurrenceType == Chore.RecurrenceType.WEEKLY) recurrenceDaysOfWeek else null,
                                    recurrenceDayOfMonth = if (isRecurring && recurrenceType == Chore.RecurrenceType.MONTHLY) recurrenceDayOfMonth else null,
                                    recurrenceEndDate = if (isRecurring && hasRecurrenceEndDate) recurrenceEndDate else null,
                                    onComplete = { success ->
                                        if (success) {
                                            onBack()
                                        }
                                    }
                                )
                            } else {
                                if (currentHouseholdId.isEmpty()){
                                     viewModel.setError("Cannot create chore: Missing household information.")
                                }
                                android.util.Log.d(TAG, "Form not valid. Title: $title, HouseholdID: $currentHouseholdId")
                            }
                        },
                        enabled = isFormValid // Enable only if form is valid
                    ) {
                        Text("Add")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Title") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                isError = titleError.isNotEmpty(),
                supportingText = { if (titleError.isNotEmpty()) Text(titleError) }
            )

            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                maxLines = 5
            )

            ExposedDropdownMenuBox(
                expanded = assigneeDropdownExpanded,
                onExpandedChange = { assigneeDropdownExpanded = !assigneeDropdownExpanded }
            ) {
                OutlinedTextField(
                    value = householdMembers.find { it.id == assignedToUserId }?.displayName ?: "Unassigned",
                    onValueChange = {},
                    label = { Text("Assign To") },
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = assigneeDropdownExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor()
                )
                ExposedDropdownMenu(
                    expanded = assigneeDropdownExpanded,
                    onDismissRequest = { assigneeDropdownExpanded = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("Unassigned") },
                        onClick = {
                            assignedToUserId = null
                            assigneeDropdownExpanded = false
                        }
                    )
                    householdMembers.forEach { member ->
                        DropdownMenuItem(
                            text = { Text(member.displayName) },
                            onClick = {
                                assignedToUserId = member.id
                                assigneeDropdownExpanded = false
                            }
                        )
                    }
                }
            }

            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                Text("Has Due Date", modifier = Modifier.weight(1f))
                Switch(
                    checked = hasDueDate,
                    onCheckedChange = {
                        hasDueDate = it
                        if (!it) dueDate = null // Clear date if toggled off
                        else if (dueDate == null) dueDate = Date(System.currentTimeMillis() + 24*60*60*1000) // Set to tomorrow if toggled on and was null
                    }
                )
            }

            if (hasDueDate) {
                OutlinedTextField(
                    value = dueDate?.let { dateFormat.format(it) } ?: "",
                    onValueChange = {},
                    label = { Text("Due Date") },
                    readOnly = true,
                    modifier = Modifier.fillMaxWidth(),
                    trailingIcon = {
                        IconButton(onClick = { showDatePicker = true }) {
                            Icon(Icons.Default.DateRange, contentDescription = "Select Date")
                        }
                    }
                )
                OutlinedTextField(
                    value = dueDate?.let { timeFormat.format(it) } ?: "",
                    onValueChange = {},
                    label = { Text("Due Time") },
                    readOnly = true,
                    modifier = Modifier.fillMaxWidth(),
                    trailingIcon = {
                        IconButton(onClick = { showTimePicker = true }) {
                            Icon(Icons.Default.Schedule, contentDescription = "Select Time")
                        }
                    }
                )
            }

            OutlinedTextField(
                value = pointValue.toString(),
                onValueChange = { pointValue = it.toIntOrNull() ?: 1 },
                label = { Text("Points") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            Text("Recurrence", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 8.dp))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                Text("Recurring Chore", modifier = Modifier.weight(1f))
                Switch(
                    checked = isRecurring,
                    onCheckedChange = { isRecurring = it }
                )
            }

            if (isRecurring) {
                ExposedDropdownMenuBox(
                    expanded = recurrenceTypeDropdownExpanded,
                    onExpandedChange = { recurrenceTypeDropdownExpanded = !recurrenceTypeDropdownExpanded }
                ) {
                    OutlinedTextField(
                        value = recurrenceType.displayName,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Recurrence Type") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = recurrenceTypeDropdownExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = recurrenceTypeDropdownExpanded,
                        onDismissRequest = { recurrenceTypeDropdownExpanded = false }
                    ) {
                        Chore.RecurrenceType.values().forEach { type ->
                            DropdownMenuItem(
                                text = { Text(type.displayName) },
                                onClick = {
                                    recurrenceType = type
                                    recurrenceTypeDropdownExpanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = recurrenceInterval.toString(),
                    onValueChange = { recurrenceInterval = it.toIntOrNull() ?: 1 },
                    label = { Text("Repeat Every (Interval)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))

                if (recurrenceType == Chore.RecurrenceType.WEEKLY) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Days of Week", style = MaterialTheme.typography.bodyLarge)
                        TextButton(onClick = { showDaysOfWeekDialog = true }) {
                            Text(
                                if (recurrenceDaysOfWeek.isEmpty()) "Select Days"
                                else recurrenceDaysOfWeek.map { dayIndex: Int -> getDayName(dayIndex) }.joinToString(", ") // EXPLICITLY TYPED
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }

                if (recurrenceType == Chore.RecurrenceType.MONTHLY) {
                    ExposedDropdownMenuBox(
                        expanded = dayOfMonthDropdownExpanded,
                        onExpandedChange = { dayOfMonthDropdownExpanded = !dayOfMonthDropdownExpanded }
                    ) {
                        OutlinedTextField(
                            value = recurrenceDayOfMonth?.toString() ?: "Same day as first occurrence",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Day of Month") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = dayOfMonthDropdownExpanded) },
                            modifier = Modifier.fillMaxWidth().menuAnchor()
                        )
                        ExposedDropdownMenu(
                            expanded = dayOfMonthDropdownExpanded,
                            onDismissRequest = { dayOfMonthDropdownExpanded = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Same day as first occurrence") },
                                onClick = {
                                    recurrenceDayOfMonth = null
                                    dayOfMonthDropdownExpanded = false
                                }
                            )
                            (1..28).forEach { day -> // Simplified to 28 for all months
                                DropdownMenuItem(
                                    text = { Text(day.toString()) },
                                    onClick = {
                                        recurrenceDayOfMonth = day
                                        dayOfMonthDropdownExpanded = false
                                    }
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                    Text("Has End Date", modifier = Modifier.weight(1f))
                    Switch(
                        checked = hasRecurrenceEndDate,
                        onCheckedChange = {
                            hasRecurrenceEndDate = it
                            if (!it) recurrenceEndDate = null
                            else if (recurrenceEndDate == null) showRecurrenceEndDatePicker = true // Open picker if toggled on and no date set
                        }
                    )
                }

                if (hasRecurrenceEndDate) {
                    OutlinedTextField(
                        value = recurrenceEndDate?.let { dateFormat.format(it) } ?: "Select End Date",
                        onValueChange = {},
                        label = { Text("End Date") },
                        readOnly = true,
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        trailingIcon = {
                            IconButton(onClick = { showRecurrenceEndDatePicker = true }) {
                                Icon(Icons.Default.DateRange, contentDescription = "Change Recurrence End Date")
                            }
                        }
                    )
                }
            }
            // Save/Cancel buttons are not in the form body for this design, "Add" is in TopAppBar
        }

        errorMessage?.let { error ->
            AlertDialog(
                onDismissRequest = { viewModel.clearError() },
                title = { Text("Error") },
                text = { Text(error) },
                confirmButton = { TextButton(onClick = { viewModel.clearError() }) { Text("OK") } }
            )
        }
    }
}

// A more standard TimePickerDialog Composable
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimePickerDialog(
    onDismissRequest: () -> Unit,
    confirmButton: @Composable () -> Unit,
    dismissButton: @Composable () -> Unit,
    content: @Composable () -> Unit // This will be the TimePicker
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text("Select Time") },
        text = content,
        confirmButton = confirmButton,
        dismissButton = dismissButton
    )
}

