package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Person
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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import java.text.SimpleDateFormat
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
    
    var selectedTabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("Pending", "Completed")
    
    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = onCreateChore
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add Chore"
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
                
                TabRow(selectedTabIndex = selectedTabIndex) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            text = { Text(title) },
                            selected = selectedTabIndex == index,
                            onClick = { selectedTabIndex = index }
                        )
                    }
                }
                
                if (isLoading) {
                    LoadingIndicator(fullscreen = true)
                } else {
                    val chores = if (selectedTabIndex == 0) pendingChores else completedChores
                    
                    if (chores.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(top = 32.dp),
                            contentAlignment = Alignment.TopCenter
                        ) {
                            Text(
                                text = if (selectedTabIndex == 0) 
                                    "No pending chores found.\nAdd a chore to get started!"
                                else 
                                    "No completed chores yet.",
                                style = MaterialTheme.typography.bodyLarge,
                                textAlign = TextAlign.Center
                            )
                        }
                    } else {
                        ChoreList(
                            chores = chores,
                            householdMembers = householdMembers,
                            onChoreClick = onChoreClick
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
                onClick = { chore.id?.let { onChoreClick(it) } }
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
    modifier: Modifier = Modifier
) {
    val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
    val isOverdue = chore.dueDate?.before(Date()) == true && !chore.isCompleted
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = when {
                chore.isCompleted -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                isOverdue -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.7f)
                else -> MaterialTheme.colorScheme.surface
            }
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status/completion icon
            if (chore.isCompleted) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Completed",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Chore details
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = chore.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                if (chore.description.isNotEmpty()) {
                    Text(
                        text = chore.description,
                        style = MaterialTheme.typography.bodyMedium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
                
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Assignee
                    if (assignee != null) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "Assigned to",
                            modifier = Modifier.padding(end = 4.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Text(
                            text = assignee.displayName,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    
                    // Points badge
                    Text(
                        text = "${chore.pointValue} ${if (chore.pointValue == 1) "pt" else "pts"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            // Due date & recurrence indicators
            if (chore.dueDate != null) {
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = dateFormat.format(chore.dueDate!!),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (isOverdue) MaterialTheme.colorScheme.error 
                               else MaterialTheme.colorScheme.onSurface
                    )
                    
                    if (chore.isRecurring) {
                        Text(
                            text = "Recurring",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
