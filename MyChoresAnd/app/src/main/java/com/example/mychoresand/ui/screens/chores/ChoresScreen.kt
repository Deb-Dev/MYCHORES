package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.tween
import androidx.compose.ui.draw.scale
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.viewmodels.ChoreViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Screen that displays the list of chores with navigation to detail/edit screens
 */
@Composable
fun ChoresScreen(
    modifier: Modifier = Modifier
) {
    val navController = rememberNavController()
    
    NavHost(
        navController = navController,
        startDestination = "chore_list"
    ) {
        composable("chore_list") {
            ChoreListScreen(
                onChoreClick = { choreId ->
                    navController.navigate("chore_detail/$choreId")
                },
                onCreateChore = {
                    navController.navigate("chore_detail/new")
                },
                modifier = modifier
            )
        }
        
        composable("chore_detail/{choreId}") { backStackEntry ->
            val choreId = backStackEntry.arguments?.getString("choreId")
            
            if (choreId == "new") {
                ChoreDetailScreen(
                    choreId = null,
                    onBack = { navController.navigateUp() }
                )
            } else {
                ChoreDetailScreen(
                    choreId = choreId,
                    onBack = { navController.navigateUp() }
                )
            }
        }
    }
}

/**
 * Screen that displays the list of chores
 */
@Composable
fun ChoreListScreen(
    onChoreClick: (String) -> Unit,
    onCreateChore: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.choreViewModel
    val pendingChores by viewModel.pendingChores.collectAsState()
    val completedChores by viewModel.completedChores.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    // Get current household ID and load chores when screen is displayed
    LaunchedEffect(Unit) {
        val currentHouseholdId = AppContainer.preferencesManager.getCurrentHouseholdId()
        if (!currentHouseholdId.isNullOrEmpty()) {
            viewModel.loadHouseholdChores(currentHouseholdId)
        }
    }
    
    var selectedTabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("All", "Assigned to Me", "Pending", "Overdue")
    
    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = onCreateChore,
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add Chore",
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        },
        modifier = modifier
    ) { paddingValues ->
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            color = MaterialTheme.colorScheme.background
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Chores",
                    style = MaterialTheme.typography.headlineLarge,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    tabs.forEachIndexed { index, title ->
                        val isSelected = selectedTabIndex == index
                        val backgroundColor = if (isSelected) 
                            MaterialTheme.colorScheme.primary 
                        else 
                            MaterialTheme.colorScheme.surfaceVariant
                        val contentColor = if (isSelected) 
                            MaterialTheme.colorScheme.onPrimary 
                        else 
                            MaterialTheme.colorScheme.onSurfaceVariant
                            
                        Surface(
                            color = backgroundColor,
                            shape = MaterialTheme.shapes.small,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { selectedTabIndex = index }
                        ) {
                            Text(
                                text = title,
                                color = contentColor,
                                style = MaterialTheme.typography.bodyMedium,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp)
                            )
                        }
                    }
                }
                
                if (isLoading) {
                    LoadingIndicator(fullscreen = true)
                } else {
                    val preferencesManager = AppContainer.preferencesManager
    val currentUserId = preferencesManager?.getCurrentUserId() ?: ""
                    val choresToDisplay = when (selectedTabIndex) {
                        0 -> pendingChores + completedChores // All chores
                        1 -> (pendingChores + completedChores).filter { it.assignedToUserId == currentUserId } // Assigned to me
                        2 -> pendingChores // Pending only
                        3 -> pendingChores.filter { it.isOverdue } // Overdue
                        else -> pendingChores
                    }
                    
                    if (choresToDisplay.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(top = 32.dp),
                            contentAlignment = Alignment.TopCenter
                        ) {
                            Text(
                                text = when(selectedTabIndex) {
                                    0 -> "No chores found.\nAdd a chore to get started!"
                                    1 -> "No chores assigned to you.\nTake on a new task!"
                                    2 -> "No pending chores.\nGreat job!"
                                    3 -> "No overdue chores.\nYou're all caught up!"
                                    else -> "No chores found."
                                },
                                style = MaterialTheme.typography.bodyLarge,
                                textAlign = TextAlign.Center
                            )
                        }
                    } else {
                        // Pass the non-null viewModel or handle the null case safely
                        viewModel?.let { vm ->
                            ChoreList(
                                chores = choresToDisplay,
                                householdMembers = householdMembers,
                                onChoreClick = onChoreClick,
                                viewModel = vm
                            )
                        } ?: Text(
                            text = "Error loading chore list",
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}

/**
 * Displays a list of chores
 */
@Composable
fun ChoreList(
    chores: List<Chore>,
    householdMembers: List<User>,
    onChoreClick: (String) -> Unit,
    viewModel: ChoreViewModel,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        contentPadding = PaddingValues(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = modifier.fillMaxSize()
    ) {
        items(chores) { chore ->
            ChoreItem(
                chore = chore,
                assignee = householdMembers.find { it.id == chore.assignedToUserId },
                onClick = { chore.id?.let { onChoreClick(it) } },
                onComplete = { choreId -> 
                    choreId?.let { viewModel.completeChore(it) }
                },
                onDelete = { choreId ->
                    choreId?.let { viewModel.deleteChore(it) } 
                }
            )
        }
    }
}

/**
 * Individual chore item in the list
 */
@Composable
fun ChoreItem(
    chore: Chore,
    assignee: User?,
    onClick: () -> Unit,
    onComplete: (String?) -> Unit,
    onDelete: (String?) -> Unit,
    modifier: Modifier = Modifier
) {
    val isOverdue = chore.dueDate?.before(Date()) == true && !chore.isCompleted
    val statusColor = when {
        chore.isCompleted -> MaterialTheme.colorScheme.primary
        isOverdue -> MaterialTheme.colorScheme.error
        else -> MaterialTheme.colorScheme.primary
    }
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() },
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp,
            pressedElevation = 4.dp,
            hoveredElevation = 3.dp
        ),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status indicator with enhanced design
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(44.dp)
                    .padding(end = 8.dp)
            ) {
                // Background circle with gradient effect
                Canvas(modifier = Modifier.fillMaxSize()) {
                    // Base circle - use white color
                    drawCircle(
                        color = androidx.compose.ui.graphics.Color.White,
                        radius = size.minDimension / 2
                    )
                    
                    // Gradient overlay
                    drawCircle(
                        color = statusColor.copy(alpha = 0.8f),
                        radius = size.minDimension / 2
                    )
                }
                
                // Status icon
                StatusIcon(
                    isCompleted = chore.isCompleted,
                    isOverdue = isOverdue,
                    modifier = Modifier
                )
            }
            
            // Chore details with enhanced styling
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = chore.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    color = if (chore.isCompleted) 
                        MaterialTheme.colorScheme.onSurfaceVariant
                    else 
                        MaterialTheme.colorScheme.onSurface,
                    textDecoration = if (chore.isCompleted) TextDecoration.LineThrough else null
                )
                
                // Date, points, and recurrence info
                Row(
                    modifier = Modifier.padding(top = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Due date with enhanced formatting
                    if (chore.dueDate != null) {
                        val dateText = formatDateLikeIOS(chore.dueDate!!)
                        val dateColor = if (isOverdue) 
                            MaterialTheme.colorScheme.error
                        else 
                            MaterialTheme.colorScheme.onSurfaceVariant
                            
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(
                                    color = dateColor.copy(alpha = 0.1f),
                                    shape = MaterialTheme.shapes.small
                                )
                                .padding(horizontal = 6.dp, vertical = 3.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.DateRange,
                                contentDescription = "Due date",
                                modifier = Modifier.size(12.dp),
                                tint = dateColor
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = dateText,
                                style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
                                color = dateColor
                            )
                        }
                    }
                    
                    // Points badge
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .background(
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                shape = MaterialTheme.shapes.small
                            )
                            .padding(horizontal = 6.dp, vertical = 3.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = "Points",
                            modifier = Modifier.size(12.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "${chore.pointValue} pts",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    // Recurring indicator
                    if (chore.isRecurring) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(
                                    MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f),
                                    shape = MaterialTheme.shapes.small
                                )
                                .padding(horizontal = 6.dp, vertical = 3.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Repeat,
                                contentDescription = "Recurring",
                                modifier = Modifier.size(12.dp),
                                tint = MaterialTheme.colorScheme.secondary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = getRecurrenceText(chore),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.secondary
                            )
                        }
                    }
                }
            }
            
            // Assignee initials (if assigned)
            if (assignee != null) {
                val initials = getInitials(assignee.displayName)
                
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(30.dp)
                        .background(
                            color = MaterialTheme.colorScheme.secondary,
                            shape = CircleShape
                        )
                ) {
                    Text(
                        text = initials,
                        style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.onSecondary
                    )
                }
            }
        }
    }
}

/**
 * Composable for status icon that handles all states with enhanced styling:
 * - Completed: CheckCircle icon
 * - Overdue: Warning icon with pulsing effect
 * - Pending: Empty circle
 */
@Composable
private fun StatusIcon(
    isCompleted: Boolean,
    isOverdue: Boolean,
    modifier: Modifier = Modifier
) {
    val iconSize = 26.dp
    
    if (isCompleted) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = "Completed",
            tint = androidx.compose.ui.graphics.Color.White,
            modifier = modifier.size(iconSize)
        )
    } else if (isOverdue) {
        // Warning icon with pulsing effect for overdue tasks
        val infiniteTransition = rememberInfiniteTransition(label = "pulse")
        val scale by infiniteTransition.animateFloat(
            initialValue = 0.95f,
            targetValue = 1.05f,
            animationSpec = infiniteRepeatable(
                animation = tween(1200),
                repeatMode = RepeatMode.Reverse
            ),
            label = "pulse animation"
        )
        
        Icon(
            imageVector = Icons.Default.Warning,
            contentDescription = "Overdue",
            tint = androidx.compose.ui.graphics.Color.White,
            modifier = modifier
                .size(iconSize)
                .scale(scale)
        )
    } else {
        // Empty circle for pending tasks
        Icon(
            imageVector = Icons.Default.Circle,
            contentDescription = "Pending",
            tint = androidx.compose.ui.graphics.Color.White,
            modifier = modifier.size(iconSize)
        )
    }
}

/**
 * Helper composable to draw pending task circle
 * Draws a simple outlined circle to indicate pending status
 */
@Composable
private fun DrawPendingCircle(modifier: Modifier = Modifier) {
    // Capture the color during composition phase, before entering the Canvas drawing scope
    val circleColor = MaterialTheme.colorScheme.secondary
    
    Canvas(modifier = modifier.size(24.dp)) {
        // Simple circle for pending tasks without gradient effect
        drawCircle(
            color = circleColor, // Use the pre-captured color here
            radius = size.minDimension / 2.5f,
            style = Stroke(width = 2.dp.toPx())
        )
    }
}

/**
 * Format date in a similar way to iOS implementation
 * Shows relative dates like "Today", "Tomorrow", or day of week for dates within a week
 */
private fun formatDateLikeIOS(date: Date): String {
    val now = Date()
    val calendar = Calendar.getInstance()
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
    
    // Today
    if (isSameDay(now, date)) {
        return "Today, ${timeFormat.format(date)}"
    }
    
    // Tomorrow
    val tomorrowCalendar = Calendar.getInstance()
    tomorrowCalendar.time = now
    tomorrowCalendar.add(Calendar.DAY_OF_YEAR, 1)
    if (isSameDay(tomorrowCalendar.time, date)) {
        return "Tomorrow, ${timeFormat.format(date)}"
    }
    
    // Within the next week
    val weekCalendar = Calendar.getInstance() 
    weekCalendar.time = now
    weekCalendar.add(Calendar.DAY_OF_YEAR, 7)
    if (date.before(weekCalendar.time)) {
        val dayFormat = SimpleDateFormat("EEEE", Locale.getDefault())
        return dayFormat.format(date)
    }
    
    // Otherwise, standard date format
    val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
    return dateFormat.format(date)
}

/**
 * Check if two dates are on the same day
 */
private fun isSameDay(date1: Date, date2: Date): Boolean {
    val cal1 = Calendar.getInstance()
    cal1.time = date1
    val cal2 = Calendar.getInstance()
    cal2.time = date2
    return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
           cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
}

/**
 * Get recurrence text for a recurring chore
 */
private fun getRecurrenceText(chore: Chore): String {
    if (!chore.isRecurring || chore.recurrenceType == null || chore.recurrenceInterval == null) {
        return "Recurring"
    }
    
    return when (chore.recurrenceType) {
        Chore.RecurrenceType.DAILY -> 
            if (chore.recurrenceInterval == 1) "Daily" else "Every ${chore.recurrenceInterval} days"
            
        Chore.RecurrenceType.WEEKLY -> 
            if (chore.recurrenceInterval == 1) "Weekly" else "Every ${chore.recurrenceInterval} weeks"
            
        Chore.RecurrenceType.MONTHLY -> 
            if (chore.recurrenceInterval == 1) "Monthly" else "Every ${chore.recurrenceInterval} months"
            
        else -> "Recurring"
    }
}

/**
 * Get initials from a name
 */
private fun getInitials(name: String): String {
    if (name.isEmpty()) return "U"
    
    val parts = name.trim().split(" ")
    return if (parts.size > 1) {
        (parts[0].firstOrNull()?.toString() ?: "") + 
        (parts[1].firstOrNull()?.toString() ?: "")
    } else {
        parts[0].take(1).uppercase()
    }
}
