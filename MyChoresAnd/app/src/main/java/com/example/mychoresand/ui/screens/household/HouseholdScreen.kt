package com.example.mychoresand.ui.screens.household

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Household
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.ui.components.SecondaryButton

/**
 * Screen that displays household information and management options
 */
@Composable
fun HouseholdScreen(
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val navController = rememberNavController()
    
    NavHost(
        navController = navController,
        startDestination = "household_home"
    ) {
        composable("household_home") {
            HouseholdHomeScreen(
                onCreateHousehold = { navController.navigate("create_household") },
                onJoinHousehold = { navController.navigate("join_household") },
                onSignOut = onSignOut,
                modifier = modifier
            )
        }
        
        composable("create_household") {
            CreateHouseholdScreen(
                onBack = { navController.navigateUp() }
            )
        }
        
        composable("join_household") {
            JoinHouseholdScreen(
                onBack = { navController.navigateUp() }
            )
        }
    }
}

/**
 * Main household screen showing household details or options to create/join
 */
@Composable
fun HouseholdHomeScreen(
    onCreateHousehold: () -> Unit,
    onJoinHousehold: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.householdViewModel
    val households by viewModel.households.collectAsState(initial = emptyList())
    val selectedHousehold by viewModel.selectedHousehold.collectAsState(initial = null)
    
    // Fix: Updated property names to match iOS implementation
    val householdMembers by viewModel.householdMembers.collectAsState(initial = emptyList<User>())
    val currentUser by viewModel.currentUser.collectAsState(initial = null)
    val isLoading by viewModel.isLoading.collectAsState(initial = false)
    
    var showLeaveDialog by remember { mutableStateOf(false) }
    
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Household",
                style = MaterialTheme.typography.headlineLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            if (isLoading) {
                LoadingIndicator(fullscreen = true)
            } else {
                if (selectedHousehold != null) {
                    // Display household details
                    HouseholdDetails(
                        household = selectedHousehold!!,
                        members = householdMembers,
                        currentUser = currentUser,
                        onLeaveHousehold = { showLeaveDialog = true }
                    )
                } else {
                    // Show options to create or join household
                    NoHouseholdView(
                        onCreateHousehold = onCreateHousehold,
                        onJoinHousehold = onJoinHousehold
                    )
                }
                
                Spacer(modifier = Modifier.weight(1f))
                
                // Sign out button at the bottom
                SecondaryButton(
                    text = "Sign Out",
                    onClick = onSignOut,
                    isFullWidth = true
                )
            }
        }
        
        if (showLeaveDialog) {
            AlertDialog(
                onDismissRequest = { showLeaveDialog = false },
                title = { Text("Leave Household?") },
                text = { Text("Are you sure you want to leave this household? You will lose access to all chores and data related to this household.") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            selectedHousehold?.let { household ->
                                // Fix: Use leaveHousehold method to match iOS implementation
                                household.id?.let { householdId ->
                                    viewModel.leaveHousehold(householdId)
                                    showLeaveDialog = false
                                }
                            }
                        }
                    ) {
                        Text("Leave")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = { showLeaveDialog = false }
                    ) {
                        Text("Cancel")
                    }
                }
            )
        }
    }
}

@Composable
fun NoHouseholdView(
    onCreateHousehold: () -> Unit,
    onJoinHousehold: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Welcome to MyChores!",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "You're not part of any household yet. Create a new household or join an existing one to get started.",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            PrimaryButton(
                text = "Create New Household",
                onClick = onCreateHousehold,
                isFullWidth = true,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            SecondaryButton(
                text = "Join Existing Household",
                onClick = onJoinHousehold,
                isFullWidth = true
            )
        }
    }
}

@Composable
fun HouseholdDetails(
    household: Household,
    members: List<User>,
    currentUser: User?,
    onLeaveHousehold: () -> Unit,
    modifier: Modifier = Modifier
) {
    val clipboardManager = LocalClipboardManager.current
    var tabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("Members", "Settings")
    
    Column(
        modifier = modifier.fillMaxWidth()
    ) {
        // Household name and invite code
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = household.name,
                    style = MaterialTheme.typography.headlineSmall,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Invite Code",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    Text(
                        text = household.inviteCode ?: "No invite code",
                        style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold),
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    
                    if (household.inviteCode != null) {
                        IconButton(
                            onClick = {
                                clipboardManager.setText(AnnotatedString(household.inviteCode!!))
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = "Copy invite code"
                            )
                        }
                    }
                }
            }
        }
        
        // Tabs for members and settings
        TabRow(selectedTabIndex = tabIndex) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    text = { Text(title) },
                    selected = tabIndex == index,
                    onClick = { tabIndex = index }
                )
            }
        }
        
        when (tabIndex) {
            0 -> MembersTab(members = members)
            1 -> SettingsTab(
                household = household,
                // Fix: Updated to use ownerUserId which is the equivalent of creatorUserId in iOS
                isCreator = household.ownerUserId == currentUser?.id,
                onLeaveHousehold = onLeaveHousehold
            )
        }
    }
}

@Composable
fun MembersTab(
    members: List<User>,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
    ) {
        Text(
            text = "${members.size} Members",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(400.dp) // Fixed height to contain the LazyColumn
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxWidth()
            ) {
                items(members) { member ->
                    MemberItem(member = member)
                    
                    Divider(modifier = Modifier.padding(vertical = 8.dp))
                }
            }
        }
    }
}

@Composable
fun MemberItem(
    member: User,
    modifier: Modifier = Modifier
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Surface(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape),
            color = MaterialTheme.colorScheme.primaryContainer
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column {
            Text(
                text = member.displayName,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = member.email,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun SettingsTab(
    household: Household,
    isCreator: Boolean,
    onLeaveHousehold: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // Household information
        Text(
            text = "Household Information",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        OutlinedCard(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Created On",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Text(
                    text = household.createdAt.toString(),
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                
                if (isCreator) {
                    Text(
                        text = "You are the creator of this household",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
        
        // Leave household option
        Text(
            text = "Danger Zone",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.error,
            modifier = Modifier.padding(top = 16.dp, bottom = 8.dp)
        )
        
        OutlinedCard(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.outlinedCardColors(
                containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.1f)
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Leave Household",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.error
                )
                
                Text(
                    text = "This will remove you from the household and you will lose access to all chores and data.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                
                Button(
                    onClick = onLeaveHousehold,
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text("Leave Household")
                }
            }
        }
    }
}

/**
 * Screen for creating a new household
 */
@Composable
fun CreateHouseholdScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.householdViewModel
    var householdName by remember { mutableStateOf("") }
    var isCreating by remember { mutableStateOf(false) }
    
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.align(Alignment.Start)
            ) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back"
                )
            }
            
            Text(
                text = "Create New Household",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(vertical = 16.dp)
            )
            
            OutlinedTextField(
                value = householdName,
                onValueChange = { householdName = it },
                label = { Text("Household Name") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp)
            )
            
            PrimaryButton(
                text = if (isCreating) "Creating..." else "Create Household",
                onClick = {
                    if (householdName.isNotBlank()) {
                        isCreating = true
                        // Fix the method signature to match what's available in the ViewModel
                        viewModel.createHousehold(householdName)
                        isCreating = false
                        onBack()
                    }
                },
                enabled = householdName.isNotBlank() && !isCreating,
                isFullWidth = true,
                modifier = Modifier.padding(top = 16.dp)
            )
        }
    }
}

/**
 * Screen for joining an existing household
 */
@Composable
fun JoinHouseholdScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.householdViewModel
    var inviteCode by remember { mutableStateOf("") }
    var isJoining by remember { mutableStateOf(false) }
    
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.align(Alignment.Start)
            ) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back"
                )
            }
            
            Text(
                text = "Join Household",
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(vertical = 16.dp)
            )
            
            Text(
                text = "Enter the invite code for the household you want to join",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            OutlinedTextField(
                value = inviteCode,
                onValueChange = { inviteCode = it },
                label = { Text("Invite Code") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp)
            )
            
            PrimaryButton(
                text = if (isJoining) "Joining..." else "Join Household",
                onClick = {
                    if (inviteCode.isNotBlank()) {
                        isJoining = true
                        // Fix the method signature to match what's available in the ViewModel
                        viewModel.joinHousehold(inviteCode)
                        isJoining = false
                        onBack()
                    }
                },
                enabled = inviteCode.isNotBlank() && !isJoining,
                isFullWidth = true,
                modifier = Modifier.padding(top = 16.dp)
            )
        }
    }
}
