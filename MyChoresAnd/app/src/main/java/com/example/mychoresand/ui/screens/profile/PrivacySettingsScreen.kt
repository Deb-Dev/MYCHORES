package com.example.mychoresand.ui.screens.profile

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.User
import com.example.mychoresand.models.UserPrivacySettings
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacySettingsScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.householdViewModel
    val currentUser by viewModel.currentUser.collectAsState()
    val coroutineScope = rememberCoroutineScope()

    // Local copy of settings
    var settings by remember { mutableStateOf(currentUser?.privacySettings ?: UserPrivacySettings()) }
    var isSaving by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Privacy Settings") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
        ) {
            SettingToggle(
                title = "Show Profile",
                checked = settings.showProfile,
                onCheckedChange = { settings = settings.copy(showProfile = it) }
            )

            SettingToggle(
                title = "Show Achievements",
                checked = settings.showAchievements,
                onCheckedChange = { settings = settings.copy(showAchievements = it) }
            )

            SettingToggle(
                title = "Share Activity",
                checked = settings.shareActivity,
                onCheckedChange = { settings = settings.copy(shareActivity = it) }
            )

            Spacer(Modifier.weight(1f))

            Button(
                onClick = {
                    if (currentUser != null) {
                        isSaving = true
                        coroutineScope.launch {
                            val updated = currentUser!!.copy(privacySettings = settings)
                            AppContainer.userService.updateUserProfile(updated)
                            viewModel.loadCurrentUser()
                            isSaving = false
                            onBack()
                        }
                    }
                },
                enabled = !isSaving,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isSaving) "Saving..." else "Save")
            }
        }
    }
}

@Composable
private fun SettingToggle(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(title, style = MaterialTheme.typography.bodyLarge)
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}
