package com.example.mychoresand.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * A reusable loading indicator component
 * 
 * @param modifier Modifier for customizing the layout
 * @param color Color of the loading indicator, defaults to primary color
 * @param fullscreen Whether to center the indicator in the full screen
 */
@Composable
fun LoadingIndicator(
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.primary,
    fullscreen: Boolean = false
) {
    if (fullscreen) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(48.dp),
                color = color
            )
        }
    } else {
        CircularProgressIndicator(
            modifier = modifier.size(36.dp),
            color = color
        )
    }
}
