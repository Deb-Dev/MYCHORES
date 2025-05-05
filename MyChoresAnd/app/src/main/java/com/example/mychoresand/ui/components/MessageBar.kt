package com.example.mychoresand.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.example.mychoresand.ui.theme.Error
import com.example.mychoresand.ui.theme.Success

/**
 * Message types for the MessageBar
 */
enum class MessageType {
    ERROR,
    SUCCESS
}

/**
 * A message bar for displaying error and success messages
 * 
 * @param message The message to display (null to hide)
 * @param type The type of message (error or success)
 * @param onDismiss Optional handler for when the message is dismissed
 * @param modifier Modifier for customizing the layout
 */
@Composable
fun MessageBar(
    message: String?,
    type: MessageType,
    onDismiss: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = !message.isNullOrEmpty(),
        enter = fadeIn() + slideInVertically { -it },
        exit = fadeOut() + slideOutVertically { -it }
    ) {
        val backgroundColor = when (type) {
            MessageType.ERROR -> Error.copy(alpha = 0.8f)
            MessageType.SUCCESS -> Success.copy(alpha = 0.8f)
        }
        
        val textColor = Color.White
        
        val icon = when (type) {
            MessageType.ERROR -> Icons.Default.Error
            MessageType.SUCCESS -> Icons.Default.Info
        }
        
        Box(
            modifier = modifier
                .fillMaxWidth()
                .background(backgroundColor)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = textColor
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Text(
                    text = message ?: "",
                    color = textColor,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.weight(1f)
                )
                
                if (onDismiss != null) {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Dismiss",
                            tint = textColor
                        )
                    }
                }
            }
        }
    }
}
