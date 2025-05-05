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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
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
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
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
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.ui.components.SecondaryButton
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import androidx.compose.runtime.LaunchedEffect

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
    val viewModel = AppContainer.choreViewModel
    val selectedChore by viewModel.selectedChore.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    // Whether we're in edit mode
    var isEditing by remember { mutableStateOf(false) }
    
    // Editable chore state
    var editableChore by remember(selectedChore) {
        mutableStateOf(selectedChore?.copy() ?: Chore())
    }
    
    // Load the chore if we have an ID
    LaunchedEffect(choreId) {
        if (!choreId.isNullOrEmpty()) {
            // The method needs to be added to the ViewModel with similar functionality to iOS version
            viewModel.getChoreById(choreId)
        } else {
            // Create new chore
            isEditing = true
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (choreId.isNullOrEmpty()) "New Chore" 
                               else if (isEditing) "Edit Chore" 
                               else "Chore Details"
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
                    if (!choreId.isNullOrEmpty() && !isEditing) {
                        IconButton(onClick = { isEditing = true }) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = "Edit"
                            )
                        }
                        
                        IconButton(
                            onClick = {
                                selectedChore?.let {
                                    // Fix: Add null check and use safe call with let
                                    it.id?.let { choreId ->
                                        viewModel.deleteChore(choreId)
                                        onBack()
                                    }
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
            if (!isEditing && selectedChore != null && !selectedChore?.isCompleted!!) {
                FloatingActionButton(
                    onClick = {
                        selectedChore?.let {
                            // Fix: Add null check and use safe call with let
                            it.id?.let { choreId ->
                                viewModel.completeChore(choreId)
                                onBack()
                            }
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
            if (isLoading && selectedChore == null) {
                LoadingIndicator(fullscreen = true)
            } else {
                if (isEditing) {
                    ChoreEditForm(
                        chore = editableChore,
                        onChoreChange = { editableChore = it },
                        householdMembers = householdMembers,
                        onSave = {
                            if (choreId.isNullOrEmpty()) {
                                // Create new chore with individual parameters matching the iOS implementation
                                viewModel.createChore(
                                    title = editableChore.title,
                                    description = editableChore.description,
                                    householdId = editableChore.householdId,
                                    assignedToUserId = editableChore.assignedToUserId,
                                    dueDate = editableChore.dueDate,
                                    pointValue = editableChore.pointValue,
                                    isRecurring = editableChore.isRecurring,
                                    recurrenceType = editableChore.recurrenceType,
                                    recurrenceInterval = editableChore.recurrenceInterval
                                )
                            } else {
                                // Update the chore - use the Chore object directly instead
                                // of individual parameters to match iOS implementation
                                viewModel.updateChore(editableChore)
                            }
                            isEditing = false
                            onBack()
                        },
                        onCancel = {
                            if (choreId.isNullOrEmpty()) {
                                onBack()
                            } else {
                                isEditing = false
                                editableChore = selectedChore?.copy() ?: Chore()
                            }
                        }
                    )
                } else {
                    selectedChore?.let { chore ->
                        ChoreDetailView(chore = chore, householdMembers = householdMembers)
                    }
                }
            }
        }
    }
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
    var showDatePicker by remember { mutableStateOf(false) }
    var assigneeDropdownExpanded by remember { mutableStateOf(false) }
    var recurrenceDropdownExpanded by remember { mutableStateOf(false) }
    
    // Create a date picker state with the current due date or today's date
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = chore.dueDate?.time ?: System.currentTimeMillis()
    )
    
    // Date format for displaying the selected date
    val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    
    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            onChoreChange(chore.copy(dueDate = Date(millis)))
                        }
                        showDatePicker = false
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showDatePicker = false }
                ) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
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
            onValueChange = { onChoreChange(chore.copy(title = it)) },
            label = { Text("Title") },
            modifier = Modifier.fillMaxWidth()
        )
        
        // Description field
        OutlinedTextField(
            value = chore.description,
            onValueChange = { onChoreChange(chore.copy(description = it)) },
            label = { Text("Description") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3
        )
        
        // Points field
        OutlinedTextField(
            value = chore.pointValue.toString(),
            onValueChange = { 
                val points = it.toIntOrNull() ?: 1
                onChoreChange(chore.copy(pointValue = points))
            },
            label = { Text("Points") },
            modifier = Modifier.fillMaxWidth()
        )
        
        // Due date picker
        OutlinedTextField(
            value = chore.dueDate?.let { dateFormat.format(it) } ?: "",
            onValueChange = { },
            label = { Text("Due Date") },
            modifier = Modifier.fillMaxWidth(),
            readOnly = true,
            trailingIcon = {
                TextButton(onClick = { showDatePicker = true }) {
                    Text("Pick Date")
                }
            }
        )
        
        // Assignee dropdown
        ExposedDropdownMenuBox(
            expanded = assigneeDropdownExpanded,
            onExpandedChange = { assigneeDropdownExpanded = it }
        ) {
            OutlinedTextField(
                value = householdMembers.find { it.id == chore.assignedToUserId }?.displayName ?: "Select Assignee",
                onValueChange = { },
                readOnly = true,
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = assigneeDropdownExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor(),
                label = { Text("Assigned To") }
            )
            
            ExposedDropdownMenu(
                expanded = assigneeDropdownExpanded,
                onDismissRequest = { assigneeDropdownExpanded = false }
            ) {
                householdMembers.forEach { user ->
                    DropdownMenuItem(
                        text = { Text(user.displayName) },
                        onClick = {
                            onChoreChange(chore.copy(assignedToUserId = user.id))
                            assigneeDropdownExpanded = false
                        }
                    )
                }
            }
        }
        
        // Recurring toggle
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            androidx.compose.material3.Switch(
                checked = chore.isRecurring,
                onCheckedChange = { isRecurring ->
                    if (isRecurring) {
                        onChoreChange(chore.copy(
                            isRecurring = true,
                            recurrenceType = Chore.RecurrenceType.WEEKLY
                        ))
                    } else {
                        onChoreChange(chore.copy(
                            isRecurring = false,
                            recurrenceType = null,
                            recurrenceInterval = null
                        ))
                    }
                }
            )
            
            Text(
                text = "Recurring Chore",
                modifier = Modifier.padding(start = 8.dp)
            )
        }
        
        // If recurring, show recurrence options
        if (chore.isRecurring) {
            ExposedDropdownMenuBox(
                expanded = recurrenceDropdownExpanded,
                onExpandedChange = { recurrenceDropdownExpanded = it }
            ) {
                OutlinedTextField(
                    value = when (chore.recurrenceType) {
                        Chore.RecurrenceType.DAILY -> "Daily"
                        Chore.RecurrenceType.WEEKLY -> "Weekly"
                        Chore.RecurrenceType.MONTHLY -> "Monthly"
                        null -> "Select Recurrence"
                    },
                    onValueChange = { },
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = recurrenceDropdownExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    label = { Text("Recurrence Pattern") }
                )
                
                ExposedDropdownMenu(
                    expanded = recurrenceDropdownExpanded,
                    onDismissRequest = { recurrenceDropdownExpanded = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("Daily") },
                        onClick = {
                            onChoreChange(chore.copy(recurrenceType = Chore.RecurrenceType.DAILY))
                            recurrenceDropdownExpanded = false
                        }
                    )
                    
                    DropdownMenuItem(
                        text = { Text("Weekly") },
                        onClick = {
                            onChoreChange(chore.copy(recurrenceType = Chore.RecurrenceType.WEEKLY))
                            recurrenceDropdownExpanded = false
                        }
                    )
                    
                    DropdownMenuItem(
                        text = { Text("Monthly") },
                        onClick = {
                            onChoreChange(chore.copy(recurrenceType = Chore.RecurrenceType.MONTHLY))
                            recurrenceDropdownExpanded = false
                        }
                    )
                }
            }
        }
        
        // Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            SecondaryButton(
                text = "Cancel",
                onClick = onCancel,
                modifier = Modifier.padding(end = 8.dp)
            )
            
            PrimaryButton(
                text = "Save",
                onClick = onSave,
                enabled = chore.title.isNotBlank()
            )
        }
    }
}
