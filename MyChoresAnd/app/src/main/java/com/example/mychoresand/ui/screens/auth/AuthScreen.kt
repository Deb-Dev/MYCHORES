package com.example.mychoresand.ui.screens.auth

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.ui.components.LoadingIndicator
import com.example.mychoresand.ui.components.MessageBar
import com.example.mychoresand.ui.components.MessageType
import com.example.mychoresand.ui.components.PrimaryButton
import com.example.mychoresand.viewmodels.AuthState
import android.util.Patterns

/**
 * Authentication screen with login and register tabs
 */
@Composable
fun AuthScreen(
    onAuthSuccess: () -> Unit,
    modifier: Modifier = Modifier
) {
    val viewModel = AppContainer.authViewModel
    val authState by viewModel.authState.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    
    // Check if user is authenticated
    LaunchedEffect(authState) {
        if (authState is AuthState.Authenticated) {
            onAuthSuccess()
        }
    }
    
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Error message bar
            errorMessage?.let {
                MessageBar(
                    message = it,
                    type = MessageType.ERROR,
                    onDismiss = { viewModel.clearError() }
                )
            }
            
            // Authentication forms
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                if (authState is AuthState.Loading) {
                    LoadingIndicator(fullscreen = true)
                } else {
                    AuthContent(
                        onLogin = { email, password -> 
                            viewModel.signIn(email, password)
                        },
                        onRegister = { email, password, name ->
                            viewModel.createAccount(email, password, name)
                        }
                    )
                }
            }
        }
    }
}

/**
 * Content of the authentication screen with login and register tabs
 */
@Composable
private fun AuthContent(
    onLogin: (String, String) -> Unit,
    onRegister: (String, String, String) -> Unit,
    modifier: Modifier = Modifier
) {
    var tabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("Sign In", "Register")
    
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // App title
        Text(
            text = "MyChores",
            style = MaterialTheme.typography.displayMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        // Tabs
        TabRow(
            selectedTabIndex = tabIndex,
            modifier = Modifier.fillMaxWidth()
        ) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    text = { Text(title) },
                    selected = tabIndex == index,
                    onClick = { tabIndex = index }
                )
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Form content
        when (tabIndex) {
            0 -> LoginForm(onLogin = onLogin)
            1 -> RegisterForm(onRegister = onRegister)
        }
    }
}

/**
 * Validates an email address
 * @param email The email to validate
 * @return True if the email format is valid, false otherwise
 */
private fun isValidEmail(email: String): Boolean {
    return email.isNotBlank() && Patterns.EMAIL_ADDRESS.matcher(email).matches()
}

/**
 * Get appropriate email validation error message
 * @param email The email to validate
 * @return Error message or null if email is valid
 */
private fun getEmailValidationError(email: String): String? {
    if (email.isBlank()) return null // Don't show errors for empty field
    return if (!isValidEmail(email)) "Please enter a valid email address" else null
}

/**
 * Login form with email and password fields
 */
@Composable
private fun LoginForm(
    onLogin: (String, String) -> Unit,
    modifier: Modifier = Modifier
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var emailError by remember { mutableStateOf<String?>(null) }
    
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Email field
        OutlinedTextField(
            value = email,
            onValueChange = { 
                email = it
                // Real-time validation as user types
                emailError = getEmailValidationError(it)
            },
            label = { Text("Email") },
            leadingIcon = { 
                Icon(Icons.Default.Email, contentDescription = null) 
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            isError = emailError != null,
            supportingText = {
                emailError?.let { Text(it) }
            },
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Password field
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            leadingIcon = { 
                Icon(Icons.Default.Lock, contentDescription = null) 
            },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Login button
        PrimaryButton(
            text = "Sign In",
            onClick = { 
                // Check if email is valid before attempting to sign in
                val validationError = getEmailValidationError(email)
                if (validationError != null) {
                    emailError = validationError
                } else {
                    onLogin(email, password)
                }
            },
            isFullWidth = true,
            enabled = email.isNotBlank() && password.isNotBlank()
        )
    }
}

/**
 * Register form with name, email, and password fields
 */
@Composable
private fun RegisterForm(
    onRegister: (String, String, String) -> Unit,
    modifier: Modifier = Modifier
) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var emailError by remember { mutableStateOf<String?>(null) }
    
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Name field
        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            label = { Text("Name") },
            leadingIcon = { 
                Icon(Icons.Default.Person, contentDescription = null) 
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Next
            ),
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Email field
        OutlinedTextField(
            value = email,
            onValueChange = { 
                email = it
                // Real-time validation as user types
                emailError = getEmailValidationError(it)
            },
            label = { Text("Email") },
            leadingIcon = { 
                Icon(Icons.Default.Email, contentDescription = null) 
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            isError = emailError != null,
            supportingText = {
                emailError?.let { Text(it) }
            },
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Password field
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            leadingIcon = { 
                Icon(Icons.Default.Lock, contentDescription = null) 
            },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Register button
        PrimaryButton(
            text = "Register",
            onClick = { 
                // Check if email is valid before attempting to register
                val validationError = getEmailValidationError(email)
                if (validationError != null) {
                    emailError = validationError
                } else {
                    onRegister(email, password, name)
                }
            },
            isFullWidth = true,
            enabled = name.isNotBlank() && email.isNotBlank() && password.isNotBlank()
        )
    }
}
