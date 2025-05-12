package com.example.mychoresand

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.ui.screens.auth.AuthScreen
import com.example.mychoresand.ui.screens.home.HomeScreen
import com.example.mychoresand.ui.screens.household.CreateHouseholdScreen
import com.example.mychoresand.ui.screens.household.JoinHouseholdScreen
import com.example.mychoresand.ui.screens.welcome.WelcomeScreen
import com.example.mychoresand.ui.theme.MyChoresTheme
import com.example.mychoresand.ui.screens.profile.PrivacySettingsScreen
import com.example.mychoresand.viewmodels.AuthState
import androidx.compose.material3.Text

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            MyChoresTheme(
                dynamicColor = true // Enable dynamic theming
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MyChoresApp()
                }
            }
        }
    }
}

/**
 * Main navigation for the app
 */
@Composable
fun MyChoresApp() {
    val navController = rememberNavController()
    val authViewModel = AppContainer.authViewModel
    val householdViewModel = AppContainer.householdViewModel
    val authState by authViewModel.authState.collectAsState()
    val households by householdViewModel.households.collectAsState(initial = emptyList())
    // Track whether households are still loading to avoid premature navigation
    val isLoadingHouseholds by householdViewModel.isLoading.collectAsState(initial = true)
    
    // Determine if user previously selected a household
    val savedHouseholdId = AppContainer.preferencesManager.getSelectedHouseholdId()
    // Define start destination based on auth state and saved household
    val startDestination = when {
        authState is AuthState.Authenticated && !savedHouseholdId.isNullOrEmpty() -> "home"
        authState is AuthState.Authenticated -> "welcome"
        else -> "auth"
    }
    
    NavHost(navController = navController, startDestination = startDestination) {
        composable("auth") {
            AuthScreen(
                onAuthSuccess = {
                    navController.navigate("home") {
                        popUpTo("auth") { inclusive = true }
                    }
                }
            )
        }
        
        composable("welcome") {
            WelcomeScreen(
                onCreateHousehold = {
                    navController.navigate("create_household")
                },
                onJoinHousehold = {
                    navController.navigate("join_household")
                }
            )
        }
        
        composable("create_household") {
            CreateHouseholdScreen(
                onBack = { navController.navigateUp() },
                onHouseholdCreated = {
                    navController.navigate("home") {
                        popUpTo("welcome") { inclusive = true }
                    }
                }
            )
        }
        
        composable("join_household") {
            JoinHouseholdScreen(
                onBack = { navController.navigateUp() },
                onHouseholdJoined = {
                    navController.navigate("home") {
                        popUpTo("welcome") { inclusive = true }
                    }
                }
            )
        }
        // Privacy Settings
        composable("privacy_settings") {
            PrivacySettingsScreen(
                onBack = { navController.navigateUp() }
            )
        }
        
        composable("home") {
            // Only navigate to welcome after households finish loading and no household exists
            if (!isLoadingHouseholds && households.isEmpty()) {
                LaunchedEffect(Unit) {
                    navController.navigate("welcome") {
                        popUpTo("home") { inclusive = true }
                    }
                }
            } else {
                HomeScreen(
                    onSignOut = {
                        authViewModel.signOut()
                        navController.navigate("auth") {
                            popUpTo("home") { inclusive = true }
                        }
                    },
                    onNavigateToWelcome = {
                        navController.navigate("welcome") {
                            popUpTo("home") { inclusive = true }
                        }
                    },
                    onNavigateToPrivacy = {
                        navController.navigate("privacy_settings")
                    }
                )
            }
        }
    }
}