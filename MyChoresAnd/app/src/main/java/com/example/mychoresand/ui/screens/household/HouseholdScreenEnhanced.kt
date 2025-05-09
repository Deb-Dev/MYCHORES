package com.example.mychoresand.ui.screens.household

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.CopyAll
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.graphics.Color as ComposeColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.models.Household
import com.example.mychoresand.models.User
import com.example.mychoresand.ui.components.LoadingIndicator
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import java.util.EnumMap

/**
 * Enhanced household screen matching iOS implementation
 */
@Composable
fun HouseholdScreenEnhanced(
    selectedHouseholdId: String?,
    onHouseholdSelected: (String) -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.householdViewModel
    val currentUser by viewModel.currentUser.collectAsState()
    val selectedHousehold by viewModel.selectedHousehold.collectAsState()
    val householdMembers by viewModel.householdMembers.collectAsState()
    val households by viewModel.households.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    
    var showingInviteSheet by remember { mutableStateOf(false) }
    var showingLeaveAlert by remember { mutableStateOf(false) }
    var showingCreateHousehold by remember { mutableStateOf(false) }
    var showingJoinHousehold by remember { mutableStateOf(false) }
    var showHouseholdDropdown by remember { mutableStateOf(false) }
    
    // Load current household on appearance
    LaunchedEffect(selectedHouseholdId) {
        if (selectedHouseholdId != null) {
            viewModel.fetchHousehold(selectedHouseholdId)
        }
    }
    
    // Update selected household ID when view model's selection changes
    LaunchedEffect(selectedHousehold) {
        if (selectedHousehold != null && selectedHousehold?.id != selectedHouseholdId) {
            onHouseholdSelected(selectedHousehold!!.id!!)
        }
    }
    
    // Error dialog
    if (errorMessage != null) {
        AlertDialog(
            onDismissRequest = { viewModel.clearErrorMessage() },
            title = { Text("Error") },
            text = { Text(errorMessage!!) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearErrorMessage() }) {
                    Text("OK")
                }
            }
        )
    }
    
    // Leave household confirmation dialog
    if (showingLeaveAlert) {
        AlertDialog(
            onDismissRequest = { showingLeaveAlert = false },
            title = { Text("Leave Household") },
            text = { Text("Are you sure you want to leave this household? You will need to be invited again to rejoin.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        selectedHousehold?.id?.let { viewModel.leaveHousehold(it) }
                        showingLeaveAlert = false
                    }
                ) {
                    Text("Leave", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showingLeaveAlert = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Invite code sheet
    if (showingInviteSheet && selectedHousehold != null) {
        InviteCodeDialog(
            inviteCode = selectedHousehold!!.inviteCode,
            onDismiss = { showingInviteSheet = false }
        )
    }
    
    // Create household dialog
    if (showingCreateHousehold) {
        CreateHouseholdDialog(
            onDismiss = { showingCreateHousehold = false },
            onCreated = { newHouseholdId ->
                showingCreateHousehold = false
                if (newHouseholdId != null) {
                    onHouseholdSelected(newHouseholdId)
                }
            }
        )
    }
    
    // Join household dialog
    if (showingJoinHousehold) {
        JoinHouseholdDialog(
            onDismiss = { showingJoinHousehold = false },
            onJoined = { joinedHouseholdId ->
                showingJoinHousehold = false
                if (joinedHouseholdId != null) {
                    onHouseholdSelected(joinedHouseholdId)
                }
            }
        )
    }
    
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        if (isLoading) {
            LoadingIndicator(fullscreen = true)
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Header section
                Text(
                    text = "Household",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold
                )
                
                // Household picker (if user belongs to multiple households)
                if (currentUser != null && (currentUser?.householdIds?.size ?: 0) > 1) {
                    Box(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f)
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Home,
                                    contentDescription = "Household"
                                )
                                
                                Spacer(modifier = Modifier.width(12.dp))
                                
                                Column(
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(
                                        text = "Current Household",
                                        style = MaterialTheme.typography.labelMedium
                                    )
                                    Text(
                                        text = selectedHousehold?.name ?: "None",
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                }
                                
                                IconButton(onClick = { showHouseholdDropdown = true }) {
                                    Icon(
                                        imageVector = Icons.Default.Settings,
                                        contentDescription = "Change Household"
                                    )
                                    
                                    DropdownMenu(
                                        expanded = showHouseholdDropdown,
                                        onDismissRequest = { showHouseholdDropdown = false }
                                    ) {
                                        households.forEach { household ->
                                            DropdownMenuItem(
                                                text = { Text(household.name) },
                                                onClick = {
                                                    onHouseholdSelected(household.id!!)
                                                    showHouseholdDropdown = false
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Current household info
                if (selectedHousehold != null) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        elevation = CardDefaults.cardElevation(
                            defaultElevation = 2.dp
                        ),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = selectedHousehold!!.name,
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold
                            )
                            
                            if (selectedHousehold!!.description.isNotEmpty()) {
                                Text(
                                    text = selectedHousehold!!.description,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Group,
                                    contentDescription = "Members",
                                    modifier = Modifier.size(18.dp)
                                )
                                
                                Spacer(modifier = Modifier.width(8.dp))
                                
                                Text(
                                    text = "${householdMembers.size} members",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                
                                Spacer(modifier = Modifier.weight(1f))
                                
                                Text(
                                    text = if (selectedHousehold!!.ownerUserId == currentUser?.id)
                                        "Owner"
                                    else
                                        "Member",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (selectedHousehold!!.ownerUserId == currentUser?.id)
                                        MaterialTheme.colorScheme.primary
                                    else
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            
                            Divider(modifier = Modifier.padding(vertical = 8.dp))
                            
                            Button(
                                onClick = { showingInviteSheet = true },
                                modifier = Modifier.align(Alignment.End)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.QrCode,
                                    contentDescription = "Invite Code",
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Invite Code")
                            }
                        }
                    }
                }
                
                // Members section
                if (householdMembers.isNotEmpty()) {
                    Column(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = "Members",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surface
                            ),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Column(
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                householdMembers.forEachIndexed { index, member ->
                                    MemberRow(
                                        member = member,
                                        isOwner = member.id == selectedHousehold?.ownerUserId,
                                        isCurrentUser = member.id == currentUser?.id
                                    )
                                    
                                    if (index < householdMembers.size - 1) {
                                        Divider(
                                            modifier = Modifier.padding(horizontal = 16.dp),
                                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Actions section
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Actions",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(bottom = 4.dp)
                    )
                    
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            ActionButton(
                                icon = Icons.Default.Add,
                                label = "Create New Household",
                                onClick = { showingCreateHousehold = true }
                            )
                            
                            Divider(
                                modifier = Modifier.padding(horizontal = 16.dp),
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
                            )
                            
                            ActionButton(
                                icon = Icons.Default.Group,
                                label = "Join Existing Household",
                                onClick = { showingJoinHousehold = true }
                            )
                            
                            if (selectedHousehold != null && selectedHousehold?.ownerUserId != currentUser?.id) {
                                Divider(
                                    modifier = Modifier.padding(horizontal = 16.dp),
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
                                )
                                
                                ActionButton(
                                    icon = Icons.Default.ExitToApp,
                                    label = "Leave Household",
                                    onClick = { showingLeaveAlert = true },
                                    isDestructive = true
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun MemberRow(
    member: User,
    isOwner: Boolean,
    isCurrentUser: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // User avatar or initials
        val initials = remember(member) {
            member.name.split(" ")
                .mapNotNull { it.firstOrNull()?.toString() }
                .take(2)
                .joinToString("")
        }
        
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = initials,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = member.name + if (isCurrentUser) " (You)" else "",
                style = MaterialTheme.typography.titleMedium
            )
            
            Text(
                text = member.email,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        if (isOwner) {
            Text(
                text = "Owner",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun ActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit,
    isDestructive: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
            .clip(RoundedCornerShape(8.dp))
            .clickable { onClick() },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Text(
            text = label,
            style = MaterialTheme.typography.titleMedium,
            color = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun InviteCodeDialog(
    inviteCode: String,
    onDismiss: () -> Unit
) {
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Invite Members",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Share this QR code or invite code to invite others to your household.",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // QR Code
                val qrBitmap = remember(inviteCode) {
                    generateQRCode(inviteCode, 300)
                }
                
                if (qrBitmap != null) {
                    Image(
                        bitmap = qrBitmap.asImageBitmap(),
                        contentDescription = "QR Code",
                        modifier = Modifier
                            .size(200.dp)
                            .clip(RoundedCornerShape(8.dp))
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Invite code display
                OutlinedTextField(
                    value = inviteCode,
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Invite Code") },
                    modifier = Modifier.fillMaxWidth(),
                    trailingIcon = {
                        IconButton(onClick = {
                            clipboardManager.setText(AnnotatedString(inviteCode))
                            // Show toast - in a real app we would show a snackbar or toast
                        }) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = "Copy"
                            )
                        }
                    }
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Close button
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Close")
                }
            }
        }
    }
}

@Composable
private fun CreateHouseholdDialog(
    onDismiss: () -> Unit,
    onCreated: (String?) -> Unit
) {
    var householdName by remember { mutableStateOf("") }
    var householdDescription by remember { mutableStateOf("") }
    var isCreating by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val viewModel = AppContainer.householdViewModel
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Create Household",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                OutlinedTextField(
                    value = householdName,
                    onValueChange = { householdName = it },
                    label = { Text("Household Name") },
                    modifier = Modifier.fillMaxWidth(),
                    isError = errorMessage != null && householdName.isBlank()
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = householdDescription,
                    onValueChange = { householdDescription = it },
                    label = { Text("Description (Optional)") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                if (errorMessage != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = errorMessage!!,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = {
                            if (householdName.isBlank()) {
                                errorMessage = "Please enter a household name"
                                return@Button
                            }
                            
                            isCreating = true
                            viewModel.createHousehold(
                                name = householdName,
                                description = householdDescription
                            ) { result ->
                                isCreating = false
                                if (result.isSuccess) {
                                    onCreated(result.getOrNull())
                                } else {
                                    errorMessage = result.exceptionOrNull()?.message ?: "Failed to create household"
                                }
                            }
                        },
                        enabled = !isCreating,
                        modifier = Modifier.weight(1f)
                    ) {
                        if (isCreating) {
                            LoadingIndicator(modifier = Modifier.size(24.dp))
                        } else {
                            Text("Create")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun JoinHouseholdDialog(
    onDismiss: () -> Unit,
    onJoined: (String?) -> Unit
) {
    var inviteCode by remember { mutableStateOf("") }
    var isJoining by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val viewModel = AppContainer.householdViewModel
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Join Household",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Enter the invite code shared with you",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                OutlinedTextField(
                    value = inviteCode,
                    onValueChange = { inviteCode = it },
                    label = { Text("Invite Code") },
                    modifier = Modifier.fillMaxWidth(),
                    isError = errorMessage != null && inviteCode.isBlank()
                )
                
                if (errorMessage != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = errorMessage!!,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    TextButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = {
                            if (inviteCode.isBlank()) {
                                errorMessage = "Please enter an invite code"
                                return@Button
                            }
                            
                            isJoining = true
                            viewModel.joinHousehold(inviteCode) { result ->
                                isJoining = false
                                if (result.isSuccess) {
                                    onJoined(result.getOrNull())
                                } else {
                                    errorMessage = result.exceptionOrNull()?.message 
                                        ?: "Failed to join household. Make sure the code is correct."
                                }
                            }
                        },
                        enabled = !isJoining,
                        modifier = Modifier.weight(1f)
                    ) {
                        if (isJoining) {
                            LoadingIndicator(modifier = Modifier.size(24.dp))
                        } else {
                            Text("Join")
                        }
                    }
                }
            }
        }
    }
}

/**
 * Generate a QR code bitmap from a string
 */
private fun generateQRCode(content: String, size: Int): Bitmap? {
    try {
        val hints = EnumMap<EncodeHintType, Any>(EncodeHintType::class.java)
        hints[EncodeHintType.MARGIN] = 1
        
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(
            content,
            BarcodeFormat.QR_CODE,
            size,
            size,
            hints
        )
        
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        
        for (x in 0 until size) {
            for (y in 0 until size) {
                bitmap.setPixel(
                    x,
                    y,
                    if (bitMatrix[x, y]) Color.BLACK else Color.WHITE
                )
            }
        }
        
        return bitmap
    } catch (e: Exception) {
        e.printStackTrace()
        return null
    }
}
