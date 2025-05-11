package com.example.mychoresand.ui.screens.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Household
import com.example.mychoresand.ui.components.PrimaryButton

@Composable
fun ProfileScreen(
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val householdViewModel = AppContainer.householdViewModel
    val selectedHousehold by householdViewModel.selectedHousehold.collectAsState(initial = null)
    val currentUser by householdViewModel.currentUser.collectAsState(initial = null)
    var showLeaveDialog by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()), // Added for scrollability
        horizontalAlignment = Alignment.CenterHorizontally,
        // verticalArrangement = Arrangement.Center // Removed to allow content to flow from top
    ) {
        Text("Profile Screen", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(32.dp))

        // Display Household Settings if a household is selected
        selectedHousehold?.let {
            HouseholdSettingsContent( // New composable for household settings
                household = it,
                isCreator = it.ownerUserId == currentUser?.id,
                onLeaveHousehold = { showLeaveDialog = true }
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        Button(onClick = onSignOut) {
            Text("Sign Out")
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
                                household.id?.let { householdId ->
                                    householdViewModel.leaveHousehold(householdId)
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
                    text = "Household Name: ${household.name}",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Text(
                    text = "Created On: ${household.createdAt}",
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
                    modifier = Modifier.padding(bottom = 16.dp)
                )

                PrimaryButton(
                    text = "Leave Household",
                    onClick = onLeaveHousehold,
                    isFullWidth = true,
                    // Optional: Add error color styling to the button if desired
                )
            }
        }
    }
}
