package com.example.mychoresand.ui.screens.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assignment
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import com.example.mychoresand.ui.screens.achievements.AchievementsScreen
import com.example.mychoresand.ui.screens.chores.ChoresScreen
import com.example.mychoresand.ui.screens.household.HouseholdScreen
import com.example.mychoresand.ui.screens.leaderboard.LeaderboardScreen
import com.example.mychoresand.ui.screens.profile.ProfileScreen
import androidx.compose.ui.unit.dp

/**
 * Tabs for the main navigation
 */
enum class HomeTab(val title: String, val icon: ImageVector) {
    CHORES("Chores", Icons.Default.Assignment),
    HOUSEHOLD("Household", Icons.Default.People),
    ACHIEVEMENTS("Achievements", Icons.Default.EmojiEvents),
    PROFILE("Profile", Icons.Default.Person)
}

/**
 * Main home screen with bottom navigation
 */
@Composable
fun HomeScreen(
    onSignOut: () -> Unit,
    onNavigateToWelcome: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    var currentTab by remember { mutableStateOf(HomeTab.CHORES) }
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                HomeTab.values().forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                        selected = currentTab == tab,
                        onClick = { currentTab = tab }
                    )
                }
            }
        },
        modifier = modifier
    ) { paddingValues ->
        Box(
            modifier = Modifier.padding(paddingValues)
        ) {
            when (currentTab) {
                HomeTab.CHORES -> ChoresScreen()
                HomeTab.HOUSEHOLD -> HouseholdScreen(
                    onSignOut = onSignOut,
                    onNavigateToWelcome = onNavigateToWelcome
                )
                HomeTab.ACHIEVEMENTS -> AchievementsScreen()
                HomeTab.PROFILE -> ProfileScreen(
                    onSignOut = onSignOut,
                    onNavigateToWelcome = onNavigateToWelcome
                )
            }
        }
    }
}

/**
 * Placeholder for screens that are not yet implemented
 */
@Composable
fun ScreenPlaceholder(
    title: String,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = "$title Screen",
            style = MaterialTheme.typography.headlineMedium, // Updated typography for better hierarchy
            color = MaterialTheme.colorScheme.onBackground, // Ensure proper contrast
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(vertical = 16.dp)
        )
        
        Text(
            text = "This screen is under construction",
            style = MaterialTheme.typography.bodyLarge, // Updated typography for better readability
            color = MaterialTheme.colorScheme.onSurface, // Ensure proper contrast
            textAlign = TextAlign.Center
        )
    }
}
