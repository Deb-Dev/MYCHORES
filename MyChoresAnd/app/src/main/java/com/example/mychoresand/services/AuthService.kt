package com.example.mychoresand.services

import com.example.mychoresand.models.User
import com.example.mychoresand.utils.PreferencesManager
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import java.util.Date

/**
 * Service handling user authentication operations
 */
class AuthService(private val preferencesManager: PreferencesManager) {
    private val auth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()
    private val usersCollection = firestore.collection("users")
    
    /**
     * Get the current authenticated user
     */
    val currentUser: FirebaseUser?
        get() = auth.currentUser
    
    /**
     * Check if a user is signed in
     */
    val isSignedIn: Boolean
        get() = auth.currentUser != null
    
    /**
     * Sign in with email and password
     * @param email User's email
     * @param password User's password
     * @return Result containing the Firebase user if successful
     */
    suspend fun signIn(email: String, password: String): Result<FirebaseUser> {
        return try {
            val authResult = auth.signInWithEmailAndPassword(email, password).await()
            val user = authResult.user!!
            
            // Save user info to preferences
            preferencesManager.saveUserId(user.uid)
            preferencesManager.saveString(PreferencesManager.KEY_USER_EMAIL, user.email ?: "", secure = true)
            
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Create a new account with email and password
     * @param email User's email
     * @param password User's password
     * @param name User's display name
     * @return Result containing the Firebase user if successful
     */
    suspend fun createAccount(email: String, password: String, name: String): Result<FirebaseUser> {
        return try {
            val authResult = auth.createUserWithEmailAndPassword(email, password).await()
            val user = authResult.user!!
            
            // Update display name
            val profileUpdates = com.google.firebase.auth.UserProfileChangeRequest.Builder()
                .setDisplayName(name)
                .build()
            
            user.updateProfile(profileUpdates).await()
            
            // Create user document in Firestore
            createUserDocument(user.uid, name, email)
            
            // Save user info to preferences
            preferencesManager.saveUserId(user.uid)
            preferencesManager.saveString(PreferencesManager.KEY_USER_EMAIL, email, secure = true)
            
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Sign out the current user
     */
    fun signOut() {
        // Clear saved preferences
        preferencesManager.remove(PreferencesManager.KEY_USER_ID, secure = true)
        preferencesManager.remove(PreferencesManager.KEY_USER_EMAIL, secure = true)
        preferencesManager.remove(PreferencesManager.KEY_AUTH_TOKEN, secure = true)
        preferencesManager.saveSelectedHouseholdId(null)
        
        // Sign out from Firebase
        auth.signOut()
    }
    
    /**
     * Send a password reset email
     * @param email The email address to send the reset link to
     * @return Result indicating success or failure
     */
    suspend fun sendPasswordResetEmail(email: String): Result<Unit> {
        return try {
            auth.sendPasswordResetEmail(email).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update the FCM token for the current user
     * @return Result indicating success or failure
     */
    suspend fun updateFcmToken(): Result<Unit> {
        val user = auth.currentUser ?: return Result.failure(Exception("User not logged in"))
        
        return try {
            val token = FirebaseMessaging.getInstance().token.await()
            usersCollection.document(user.uid)
                .update("fcmToken", token)
                .await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Create a user document in Firestore
     * @param uid User's Firebase Auth UID
     * @param name User's display name
     * @param email User's email address
     */
    private suspend fun createUserDocument(uid: String, name: String, email: String) {
        val user = User(
            id = uid,
            name = name,
            email = email,
            createdAt = Date(),
            totalPoints = 0,
            weeklyPoints = 0,
            monthlyPoints = 0,
            householdIds = emptyList(),
            earnedBadgeIds = emptyList() // Updated to earnedBadgeIds
        )
        
        usersCollection.document(uid).set(user).await()
    }
}
