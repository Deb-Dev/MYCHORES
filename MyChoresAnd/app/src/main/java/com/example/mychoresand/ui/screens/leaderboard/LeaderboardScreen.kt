package com.example.mychoresand.ui.screens.leaderboard

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator

/**
 * Screen that displays the leaderboard with weekly and monthly tabs
 */
@Composable
fun LeaderboardScreen(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxSize().padding(top = 16.dp, start = 16.dp, end = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ){
        Text(
            text = "Leaderboard",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        LeaderboardContent(modifier = Modifier.fillMaxSize())
    }
}

/**
 * Composable that contains the actual leaderboard content (Tabs, lists, etc.)
 * This can be reused in HouseholdScreen.
 */
@Composable
fun LeaderboardContent(modifier: Modifier = Modifier) {
    val viewModel = AppContainer.leaderboardViewModel
    val weeklyLeaderboard by viewModel.weeklyLeaderboard.collectAsState(initial = emptyList())
    val monthlyLeaderboard by viewModel.monthlyLeaderboard.collectAsState(initial = emptyList())
    val allTimeLeaderboard by viewModel.allTimeLeaderboard.collectAsState(initial = emptyList())
    val isLoading by viewModel.isLoading.collectAsState(initial = false)
    val currentUser by viewModel.currentUser.collectAsState(initial = null)

    // Make sure to load the leaderboard data for the current household
    LaunchedEffect(Unit) {
        // We need to get the current household ID from somewhere
        // For now, we'll assume it's available in the shared preferences or another source
        val householdId = AppContainer.preferencesManager.getCurrentHouseholdId()
        if (!householdId.isNullOrEmpty()) {
            viewModel.loadLeaderboard(householdId)
        }
    }

    var selectedTabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("Weekly", "Monthly", "All Time")

    Column(
        modifier = modifier // Use the passed modifier
    ) {
        TabRow(selectedTabIndex = selectedTabIndex) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    text = { Text(title) },
                    selected = selectedTabIndex == index,
                    onClick = { selectedTabIndex = index }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (isLoading) {
            LoadingIndicator(fullscreen = true)
        } else {
            val leaderboardData = when (selectedTabIndex) {
                0 -> weeklyLeaderboard
                1 -> monthlyLeaderboard
                else -> allTimeLeaderboard
            }

            if (leaderboardData.isEmpty()) {
                EmptyLeaderboard(selectedTabIndex)
            } else {
                // Show top 3 users in a special way
                if (leaderboardData.size >= 2) {
                    TopLeadersRow(
                        users = leaderboardData.take(3),
                        currentUserId = currentUser?.id
                    )

                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Show full list
                LeaderboardList(
                    users = leaderboardData,
                    currentUserId = currentUser?.id
                )
            }
        }
    }
}

@Composable
fun EmptyLeaderboard(tabIndex: Int) {
    val message = when (tabIndex) {
        0 -> "No points earned this week yet."
        1 -> "No points earned this month yet."
        else -> "No points earned yet."
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.EmojiEvents,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(64.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "Complete chores to earn points and climb the leaderboard!",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

@Composable
fun TopLeadersRow(
    users: List<User>,
    currentUserId: String?,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.Bottom
    ) {
        // If we have at least 3 users, show 2nd place on the left
        if (users.size >= 3) {
            TopLeaderItem(
                user = users[1],
                place = 2,
                isCurrentUser = users[1].id == currentUserId,
                modifier = Modifier.weight(1f)
            )
        } else {
            Spacer(modifier = Modifier.weight(1f))
        }

        // First place in the middle and larger
        if (users.isNotEmpty()) {
            TopLeaderItem(
                user = users[0],
                place = 1,
                isCurrentUser = users[0].id == currentUserId,
                modifier = Modifier.weight(1.2f)
            )
        } else {
            Spacer(modifier = Modifier.weight(1.2f))
        }

        // If we have at least 3 users, show 3rd place on the right
        if (users.size >= 3) {
            TopLeaderItem(
                user = users[2],
                place = 3,
                isCurrentUser = users[2].id == currentUserId,
                modifier = Modifier.weight(1f)
            )
        } else if (users.size == 2) {
            TopLeaderItem(
                user = users[1],
                place = 2,
                isCurrentUser = users[1].id == currentUserId,
                modifier = Modifier.weight(1f)
            )
        } else {
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun TopLeaderItem(
    user: User,
    place: Int,
    isCurrentUser: Boolean,
    modifier: Modifier = Modifier
) {
    val avatarSize = when (place) {
        1 -> 80.dp
        else -> 60.dp
    }

    val medalColor = when (place) {
        1 -> Color(0xFFFFD700) // Gold
        2 -> Color(0xFFC0C0C0) // Silver
        3 -> Color(0xFFCD7F32) // Bronze
        else -> MaterialTheme.colorScheme.primary
    }

    val backgroundColor = if (isCurrentUser) {
        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
    } else {
        Color.Transparent
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
            .padding(8.dp)
            .background(backgroundColor, MaterialTheme.shapes.medium)
            .padding(8.dp)
    ) {
        Box {
            // User avatar
            Surface(
                modifier = Modifier
                    .size(avatarSize)
                    .clip(CircleShape),
                color = MaterialTheme.colorScheme.primaryContainer
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(avatarSize * 0.6f)
                    )
                }
            }

            // Medal icon
            Surface(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .align(Alignment.BottomEnd),
                color = medalColor
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = place.toString(),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = user.displayName,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            maxLines = 1
        )

        Text(
            // Changed from user.points to user.totalPoints, weeklyPoints, or monthlyPoints based on the tab
            text = "${when (place) {
                1 -> user.totalPoints
                2 -> user.weeklyPoints
                3 -> user.monthlyPoints
                else -> user.totalPoints
            }} pts",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun LeaderboardList(
    users: List<User>,
    currentUserId: String?,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth()
        ) {
            itemsIndexed(users) { index, user ->
                val place = index + 1
                val isCurrentUser = user.id == currentUserId
                val backgroundColor = if (isCurrentUser) {
                    MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                } else {
                    Color.Transparent
                }

                // Skip the top 3 if we displayed them separately above
                if (users.size >= 3 && place <= 3) {
                    return@itemsIndexed
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(backgroundColor)
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                ) {
                    // Rank number
                    Text(
                        text = "$place",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.width(32.dp)
                    )

                    // User avatar
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

                    // User name
                    Text(
                        text = user.displayName,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = if (isCurrentUser) FontWeight.Bold else FontWeight.Normal,
                        modifier = Modifier.weight(1f)
                    )

                    // Points
                    Text(
                        // Changed from user.points to user.totalPoints
                        text = "${user.totalPoints} pts",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}
