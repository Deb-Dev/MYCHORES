package com.example.mychoresand.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.automirrored.filled.Help
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ElevatedButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Household
import com.example.mychoresand.ui.components.PrimaryButton
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun ProfileScreen(
    onSignOut: () -> Unit,
    onNavigateToWelcome: (() -> Unit)? = null,
    onNavigateToPrivacy: () -> Unit,
    onEditProfile: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val householdViewModel = AppContainer.householdViewModel
    val selectedHousehold by householdViewModel.selectedHousehold.collectAsState(initial = null)
    val currentUser by householdViewModel.currentUser.collectAsState(initial = null)
    val userHouseholds by householdViewModel.households.collectAsState(initial = emptyList())
    var showLeaveDialog by remember { mutableStateOf(false) }
    var showSignOutDialog by remember { mutableStateOf(false) }

    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Profile",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )
            
            currentUser?.let { user ->
                // User profile information goes here
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // User avatar
                        Box(
                            modifier = Modifier
                                .size(100.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentAlignment = Alignment.Center
                        ) {
                            if (user.photoURL != null) {
                                AsyncImage(
                                    model = user.photoURL,
                                    contentDescription = "Profile picture",
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier.fillMaxSize()
                                )
                            } else {
                                Text(
                                    text = user.displayName.take(1).uppercase(),
                                    style = MaterialTheme.typography.headlineLarge,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // User name
                        Text(
                            text = user.displayName,
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // User email
                        Text(
                            text = user.email,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Edit profile button
                        OutlinedButton(
                            onClick = { onEditProfile?.invoke() },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Edit Profile")
                        }
                    }
                }
                
                // User Statistics Card
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Your Statistics",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            // Total Points
                            StatisticItem(
                                icon = Icons.Default.Star,
                                iconBackground = MaterialTheme.colorScheme.primaryContainer,
                                value = user.totalPoints.toString(),
                                label = "Total Points",
                                modifier = Modifier.weight(1f)
                            )
                            
                            // Badges Earned
                            StatisticItem(
                                icon = Icons.Default.EmojiEvents,
                                iconBackground = MaterialTheme.colorScheme.tertiaryContainer,
                                value = user.earnedBadgeIds.size.toString(),
                                label = "Badges Earned",
                                modifier = Modifier.weight(1f)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            // Households Count
                            StatisticItem(
                                icon = Icons.Default.Home,
                                iconBackground = MaterialTheme.colorScheme.secondaryContainer,
                                value = userHouseholds.size.toString(),
                                label = "Households",
                                modifier = Modifier.weight(1f)
                            )
                            
                            // Member Since
                            val memberSince = user.createdAt.let {
                                val formatter = SimpleDateFormat("MMM yyyy", Locale.getDefault())
                                formatter.format(it)
                            }
                            StatisticItem(
                                icon = Icons.Default.DateRange,
                                iconBackground = MaterialTheme.colorScheme.surfaceVariant,
                                value = memberSince,
                                label = "Member Since",
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
                
                // Settings Card
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Settings",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                        
                        // Notifications Setting
                        SettingsItem(
                            icon = Icons.Default.Notifications,
                            iconTint = MaterialTheme.colorScheme.primary,
                            title = "Notifications",
                            onClick = { /* Navigate to notifications settings */ }
                        )
                        
                        // Privacy Settings
                        SettingsItem(
                            icon = Icons.Default.Lock,
                            iconTint = MaterialTheme.colorScheme.primary,
                            title = "Privacy",
                            onClick = onNavigateToPrivacy
                        )
                        
                        // Help & Support
                        SettingsItem(
                            icon = Icons.AutoMirrored.Filled.Help,
                            iconTint = MaterialTheme.colorScheme.primary,
                            title = "Help & Support",
                            onClick = { /* Navigate to help & support */ }
                        )
                        
                        // About
                        SettingsItem(
                            icon = Icons.Default.Info,
                            iconTint = MaterialTheme.colorScheme.primary,
                            title = "About",
                            onClick = { /* Navigate to about screen */ }
                        )
                    }
                }
                
                // Sign out button
                Button(
                    onClick = { showSignOutDialog = true },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer,
                        contentColor = MaterialTheme.colorScheme.onErrorContainer
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Logout,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sign Out")
                }
            }
            
            // Sign out confirmation dialog
            if (showSignOutDialog) {
                AlertDialog(
                    onDismissRequest = { showSignOutDialog = false },
                    title = { Text("Sign Out") },
                    text = { Text("Are you sure you want to sign out?") },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                showSignOutDialog = false
                                onSignOut()
                            }
                        ) {
                            Text("Sign Out")
                        }
                    },
                    dismissButton = {
                        TextButton(
                            onClick = { showSignOutDialog = false }
                        ) {
                            Text("Cancel")
                        }
                    }
                )
            }
            
            // Leave household dialog
            if (showLeaveDialog) {
                AlertDialog(
                    onDismissRequest = { showLeaveDialog = false },
                    title = { Text("Leave Household?") },
                    text = { Text("Are you sure you want to leave this household? You will lose access to all chores and data related to this household.") },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                selectedHousehold?.let { household ->
                                    household.id?.let { householdId ->
                                        householdViewModel.leaveHousehold(householdId) { hasHouseholds ->
                                            showLeaveDialog = false
                                            // If user has no households left, navigate to welcome screen
                                            if (!hasHouseholds) {
                                                onNavigateToWelcome?.invoke()
                                            }
                                        }
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
}

@Composable
fun HouseholdSettingsContent(
    household: Household,
    isCreator: Boolean,
    onLeaveHousehold: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
    ) {
        Text(
            text = "Household Information",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
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
                    text = "Household Name: ${household.name}",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    text = "Created On: ${household.createdAt}",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface,
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
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(bottom = 16.dp)
                )

                ElevatedButton(
                    onClick = onLeaveHousehold,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Leave Household")
                }
            }
        }
    }
}

/**
 * A composable that displays a statistic item with an icon, label, and value.
 */
@Composable
fun StatisticItem(
    icon: ImageVector,
    iconBackground: Color,
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.padding(horizontal = 8.dp)
    ) {
        // Icon with background
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(iconBackground)
                .padding(8.dp),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                modifier = Modifier.size(24.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Value
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        // Label
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * A composable that displays a settings item with an icon and title.
 */
@Composable
fun SettingsItem(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .padding(vertical = 12.dp)
        ) {
            // Icon
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Title
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.weight(1f))
        }
        
        // Divider
        HorizontalDivider(
            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f),
            thickness = 1.dp
        )
    }
}
