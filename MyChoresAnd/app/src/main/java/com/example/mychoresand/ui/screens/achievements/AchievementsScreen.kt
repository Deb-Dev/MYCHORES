package com.example.mychoresand.ui.screens.achievements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Badge
import com.example.mychoresand.ui.components.LoadingIndicator

/**
 * Screen that displays user's achievements/badges
 */
@Composable
fun AchievementsScreen(
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.achievementsViewModel
    val earnedBadges by viewModel.earnedBadges.collectAsState()
    val availableBadges by viewModel.availableBadges.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
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
                text = "Achievements",
                style = MaterialTheme.typography.headlineLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            if (isLoading) {
                LoadingIndicator(fullscreen = true)
            } else {
                if (earnedBadges.isEmpty() && availableBadges.isEmpty()) {
                    Text(
                        text = "No badges available yet",
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 32.dp)
                    )
                } else {
                    Text(
                        text = "Earned Badges",
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(top = 8.dp, bottom = 8.dp)
                    )
                    
                    if (earnedBadges.isEmpty()) {
                        Text(
                            text = "Complete chores to earn badges!",
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    } else {
                        BadgeGrid(
                            badges = earnedBadges,
                            isEarned = true
                        )
                    }
                    
                    Text(
                        text = "Available Badges",
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(top = 24.dp, bottom = 8.dp)
                    )
                    
                    BadgeGrid(
                        badges = availableBadges,
                        isEarned = false
                    )
                }
            }
        }
    }
}

@Composable
fun BadgeGrid(
    badges: List<Badge>,
    isEarned: Boolean,
    modifier: Modifier = Modifier
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = PaddingValues(8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = modifier
    ) {
        items(badges) { badge ->
            BadgeItem(badge = badge, isEarned = isEarned)
        }
    }
}

@Composable
fun BadgeItem(
    badge: Badge,
    isEarned: Boolean,
    modifier: Modifier = Modifier
) {
    val cardColor = if (isEarned) {
        MaterialTheme.colorScheme.primaryContainer
    } else {
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    }
    
    val contentColor = if (isEarned) {
        MaterialTheme.colorScheme.onPrimaryContainer
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    }
    
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = cardColor,
            contentColor = contentColor
        )
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.EmojiEvents,
                contentDescription = badge.name,
                tint = if (isEarned) Color.Yellow else Color.Gray,
                modifier = Modifier.size(48.dp)
            )
            
            Text(
                text = badge.name,
                style = MaterialTheme.typography.titleMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            Text(
                text = badge.description,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
    }
}
