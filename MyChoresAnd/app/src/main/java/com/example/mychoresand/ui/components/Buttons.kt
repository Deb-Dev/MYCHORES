package com.example.mychoresand.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * Primary button with optional icon
 * 
 * @param text Button text
 * @param onClick Click handler
 * @param modifier Modifier for customizing the layout
 * @param icon Optional icon to display before the text
 * @param enabled Whether the button is enabled
 * @param isLoading Whether to show a loading indicator instead of content
 * @param isFullWidth Whether the button should take full available width
 * @param contentPadding Padding values for the button content
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    isFullWidth: Boolean = false,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding
) {
    Button(
        onClick = onClick,
        modifier = if (isFullWidth) modifier.fillMaxWidth() else modifier,
        enabled = enabled && !isLoading,
        contentPadding = contentPadding
    ) {
        ButtonContent(text, icon, isLoading)
    }
}

/**
 * Secondary (outlined) button with optional icon
 * 
 * @param text Button text
 * @param onClick Click handler
 * @param modifier Modifier for customizing the layout
 * @param icon Optional icon to display before the text
 * @param enabled Whether the button is enabled
 * @param isLoading Whether to show a loading indicator instead of content
 * @param isFullWidth Whether the button should take full available width
 * @param contentPadding Padding values for the button content
 */
@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    isFullWidth: Boolean = false,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding
) {
    OutlinedButton(
        onClick = onClick,
        modifier = if (isFullWidth) modifier.fillMaxWidth() else modifier,
        enabled = enabled && !isLoading,
        contentPadding = contentPadding
    ) {
        ButtonContent(text, icon, isLoading)
    }
}

/**
 * Text button with optional icon
 * 
 * @param text Button text
 * @param onClick Click handler
 * @param modifier Modifier for customizing the layout
 * @param icon Optional icon to display before the text
 * @param enabled Whether the button is enabled
 * @param isLoading Whether to show a loading indicator instead of content
 * @param contentPadding Padding values for the button content
 */
@Composable
fun TextActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    contentPadding: PaddingValues = ButtonDefaults.TextButtonContentPadding
) {
    TextButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled && !isLoading,
        contentPadding = contentPadding
    ) {
        ButtonContent(text, icon, isLoading)
    }
}

/**
 * Helper function for button content
 */
@Composable
private fun RowScope.ButtonContent(
    text: String, 
    icon: ImageVector?, 
    isLoading: Boolean
) {
    if (isLoading) {
        LoadingIndicator(
            color = Color.White,
            modifier = Modifier.size(18.dp)
        )
    } else {
        icon?.let {
            Icon(
                imageVector = it,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
        }
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            textAlign = TextAlign.Center
        )
    }
}
