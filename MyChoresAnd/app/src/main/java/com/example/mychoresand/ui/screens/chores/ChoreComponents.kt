package com.example.mychoresand.ui.screens.chores

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.ui.components.SecondaryButton
import com.example.mychoresand.ui.utils.TimePickerDialog
import java.text.SimpleDateFormat
import java.util.*

/**
 * Displays the detail view of a chore (read-only)
 */
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
            color = MaterialTheme.colorScheme.onBackground // Ensure proper contrast
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        if (chore.description.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Description",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    
                    Text(
                        text = chore.description,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
        }
        
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Details",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
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
            }
        }
    }
}

/**
 * A row in the chore detail view showing a label and value
 */
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

/**
 * Form for creating or editing a chore
 */
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
        TimePickerDialog(
            onDismissRequest = { showTimePicker = false },
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
            content = { TimePicker(state = timePickerState) }
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
            onValueChange = { updatedDescription ->
                Log.d("ChoreEditForm", "Description changed to: $updatedDescription")
                onChoreChange(chore.copy(description = updatedDescription))
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(120.dp)
                .padding(bottom = 16.dp),
            label = { Text("Description") },
            supportingText = { Text("Enter a detailed description of the chore") },
            keyboardOptions = KeyboardOptions(
                imeAction = ImeAction.Done,
                keyboardType = KeyboardType.Text
            ),
            keyboardActions = KeyboardActions(
                onDone = { /* Hide keyboard */ }
            ),
            singleLine = false,
            maxLines = 5,
            textStyle = MaterialTheme.typography.bodyMedium
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

        // Points Field - Using a stepper UI component for better usability
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "Points: ${chore.pointValue}",
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Decrease points button
                OutlinedIconButton(
                    onClick = {
                        val newValue = (chore.pointValue - 1).coerceAtLeast(1)
                        android.util.Log.d(TAG, "Points decreased to: $newValue")
                        onChoreChange(chore.copy(pointValue = newValue))
                    },
                    enabled = chore.pointValue > 1,
                    modifier = Modifier.size(48.dp),
                    colors = IconButtonDefaults.outlinedIconButtonColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("-", style = MaterialTheme.typography.titleLarge)
                }
                
                // Slider for points
                Slider(
                    value = chore.pointValue.toFloat(),
                    onValueChange = { 
                        val newValue = it.toInt()
                        android.util.Log.d(TAG, "Points changed with slider: $newValue")
                        onChoreChange(chore.copy(pointValue = newValue))
                    },
                    valueRange = 1f..10f,
                    steps = 8,
                    modifier = Modifier.weight(1f),
                    colors = SliderDefaults.colors(
                        thumbColor = MaterialTheme.colorScheme.primary,
                        activeTrackColor = MaterialTheme.colorScheme.primary
                    )
                )
                
                // Increase points button
                OutlinedIconButton(
                    onClick = {
                        val newValue = (chore.pointValue + 1).coerceAtMost(10)
                        android.util.Log.d(TAG, "Points increased to: $newValue")
                        onChoreChange(chore.copy(pointValue = newValue))
                    },
                    enabled = chore.pointValue < 10,
                    modifier = Modifier.size(48.dp),
                    colors = IconButtonDefaults.outlinedIconButtonColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("+", style = MaterialTheme.typography.titleLarge)
                }
            }
            
            Text(
                text = when (chore.pointValue) {
                    1 -> "Very easy task"
                    in 2..3 -> "Easy task"
                    in 4..6 -> "Moderate task"
                    in 7..8 -> "Challenging task"
                    else -> "Difficult task"
                },
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp)
            )
        }

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
