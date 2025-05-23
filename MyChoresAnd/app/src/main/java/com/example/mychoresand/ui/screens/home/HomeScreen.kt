package com.example.mychoresand.ui.screens.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assignment
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Leaderboard
import androidx.compose.material.icons.filled.People
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
import androidx.compose.ui.unit.dp
/**
 * Tabs for the main navigation
 */
enum class HomeTab(val title: String, val icon: ImageVector) {
    CHORES("Chores", Icons.Default.Assignment),
    HOUSEHOLD("Household", Icons.Default.People),
    LEADERBOARD("Leaderboard", Icons.Default.Leaderboard),
    ACHIEVEMENTS("Achievements", Icons.Default.EmojiEvents)
}

/**
 * Main home screen with bottom navigation
 */
@Composable
fun HomeScreen(
    onSignOut: () -> Unit,
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
                HomeTab.HOUSEHOLD -> HouseholdScreen(onSignOut = onSignOut)
                HomeTab.LEADERBOARD -> LeaderboardScreen()
                HomeTab.ACHIEVEMENTS -> AchievementsScreen()
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
            style = MaterialTheme.typography.headlineMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(vertical = 16.dp)
        )
        
        Text(
            text = "This screen is under construction",
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center
        )
    }
}
