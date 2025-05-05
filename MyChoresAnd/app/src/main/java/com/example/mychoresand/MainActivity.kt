package com.example.mychoresand

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.mychoresand.di.AppContainer
import com.example.mychoresand.ui.screens.auth.AuthScreen
import com.example.mychoresand.ui.screens.home.HomeScreen
import com.example.mychoresand.ui.theme.MyChoresTheme
import com.example.mychoresand.viewmodels.AuthState

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            MyChoresTheme {
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
    val authState by authViewModel.authState.collectAsState()
    
    // Define start destination based on auth state
    val startDestination = when (authState) {
        is AuthState.Authenticated -> "home"
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
        
        composable("home") {
            HomeScreen(
                onSignOut = {
                    authViewModel.signOut()
                    navController.navigate("auth") {
                        popUpTo("home") { inclusive = true }
                    }
                }
            )
        }
    }
}