package com.example.mychoresand.services

import com.example.mychoresand.models.Badge
import com.example.mychoresand.models.User
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.tasks.await
import java.util.Calendar
import java.util.Date

/**
 * Service handling user data operations
 */
class UserService {
    private val auth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()
    private val usersCollection = firestore.collection("users")
    
    /**
     * Get the current user from Firestore
     * @return Flow emitting the current user data or null
     */
    fun getCurrentUser(): Flow<User?> = flow {
        val uid = auth.currentUser?.uid ?: run {
            emit(null)
            return@flow
        }
        
        try {
            val snapshot = usersCollection.document(uid).get().await()
            val user = snapshot.toObject(User::class.java)
            emit(user)
        } catch (e: Exception) {
            emit(null)
        }
    }
    
    /**
     * Get the current user ID from Firebase Auth
     * @return The current user ID or null if not authenticated
     */
    fun getCurrentUserId(): String? {
        return auth.currentUser?.uid
    }

    /**
     * Get a user by ID
     * @param userId The user ID to fetch
     * @return Flow emitting the user data or null
     */
    fun getUserById(userId: String): Flow<User?> = flow {
        try {
            val snapshot = usersCollection.document(userId).get().await()
            val user = snapshot.toObject(User::class.java)
            // Set the ID from the document ID if it was loaded
            if (user != null && user.id == null) {
                user.id = snapshot.id
            }
            emit(user)
        } catch (e: Exception) {
            emit(null)
        }
    }

    /**
     * Get a user by ID from Firestore
     * @param uid User ID to retrieve
     * @return Flow emitting the user data or null
     */
    fun getUser(uid: String): Flow<User?> = flow {
        try {
            val snapshot = usersCollection.document(uid).get().await()
            val user = snapshot.toObject(User::class.java)
            emit(user)
        } catch (e: Exception) {
            emit(null)
        }
    }

    /**
     * Get users by IDs
     * @param userIds List of user IDs to fetch
     * @return Flow emitting list of users
     */
    fun getUsers(userIds: List<String>): Flow<List<User>> = flow {
        if (userIds.isEmpty()) {
            emit(emptyList())
            return@flow
        }
        
        try {
            val snapshot = usersCollection.whereIn("id", userIds).get().await()
            val users = snapshot.documents.mapNotNull { it.toObject(User::class.java) }
            emit(users)
        } catch (e: Exception) {
            emit(emptyList())
        }
    }
    
    /**
     * Update a user's profile information
     * @param user The updated user object
     * @return Result indicating success or failure
     */
    suspend fun updateUserProfile(user: User): Result<Unit> {
        val uid = user.id ?: auth.currentUser?.uid ?: return Result.failure(Exception("User ID not found"))
        
        return try {
            usersCollection.document(uid).set(user, SetOptions.merge()).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Add points to a user from completing a chore
     * @param userId The ID of the user earning points
     * @param points The number of points to add
     * @return Result indicating success or failure
     */
    suspend fun addPoints(userId: String, points: Int): Result<Unit> {
        if (points <= 0) {
            return Result.failure(Exception("Points must be positive"))
        }
        
        return try {
            // Get current user data
            val userDoc = usersCollection.document(userId).get().await()
            val user = userDoc.toObject(User::class.java) ?: return Result.failure(Exception("User not found"))
            
            // Check if we need to reset weekly/monthly points
            val calendar = Calendar.getInstance()
            val now = Date()
            var weeklyPoints = user.weeklyPoints
            var monthlyPoints = user.monthlyPoints
            
            // Reset weekly points if needed
            val currentWeekStart = getCurrentWeekStart()
            if (user.currentWeekStartDate == null || (user.currentWeekStartDate as Date).before(currentWeekStart)) {
                weeklyPoints = points
            } else {
                weeklyPoints += points
            }
            
            // Reset monthly points if needed
            val currentMonthStart = getCurrentMonthStart()
            if (user.currentMonthStartDate == null || (user.currentMonthStartDate as Date).before(currentMonthStart)) {
                monthlyPoints = points
            } else {
                monthlyPoints += points
            }
            
            // Update points in Firestore
            val updates = hashMapOf<String, Any>(
                "totalPoints" to (user.totalPoints + points),
                "weeklyPoints" to weeklyPoints,
                "monthlyPoints" to monthlyPoints,
                "currentWeekStartDate" to currentWeekStart,
                "currentMonthStartDate" to currentMonthStart
            )
            
            usersCollection.document(userId).update(updates).await()
            
            // Check if user earned any badges
            checkAndAwardBadges(userId, user.totalPoints + points, user.earnedBadgeIds)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Award a badge to a user
     * @param userId The user ID to award the badge to
     * @param badgeKey The badge key to award
     * @return True if successful, false otherwise
     */
    suspend fun awardBadge(userId: String, badgeKey: String): Boolean {
        return try {
            usersCollection.document(userId).update(
                "earnedBadgeIds", FieldValue.arrayUnion(badgeKey),
                "updatedAt", Date()
            ).await()
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Get users in a household for the leaderboard
     * @param householdId The household ID
     * @return Flow emitting list of users in the household
     */
    fun getHouseholdUsers(householdId: String): Flow<List<User>> = flow {
        try {
            android.util.Log.d("UserService", "Fetching users for household: $householdId")
            val snapshot = usersCollection.whereArrayContains("householdIds", householdId).get().await()
            android.util.Log.d("UserService", "Fetched ${snapshot.size()} users from Firestore")
            
            val users = snapshot.documents.mapNotNull { 
                try {
                    it.toObject(User::class.java)?.also { user ->
                        // Ensure ID is set
                        if (user.id == null) {
                            user.id = it.id
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("UserService", "Error converting user document: ${e.message}", e)
                    null
                }
            }
            android.util.Log.d("UserService", "Successfully converted ${users.size} user objects")
            emit(users)
        } catch (e: Exception) {
            android.util.Log.e("UserService", "Error fetching household users: ${e.message}", e)
            // Emit empty list instead of re-throwing the exception to prevent Flow cancellation
            emit(emptyList())
        }
    }
    
    /**
     * Get current week's start date
     */
    private fun getCurrentWeekStart(): Date {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.DAY_OF_WEEK, calendar.firstDayOfWeek)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Get current month's start date
     */
    private fun getCurrentMonthStart(): Date {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Check if user has earned any badges and award them
     * @param userId The user's ID
     * @param totalPoints The user's updated total points
     * @param currentBadges The user's current badges
     */
    suspend fun checkAndAwardBadges(userId: String, totalPoints: Int, currentBadges: List<String>) {
        // Get eligible badges based on task completion count
        val eligibleBadges = Badge.predefinedBadges.filter { badge ->
            val requiredCount = badge.requiredTaskCount
            requiredCount != null && 
            totalPoints >= requiredCount && 
            !currentBadges.contains(badge.badgeKey)
        }
        
        // Award any newly earned badges
        for (badge in eligibleBadges) {
            awardBadge(userId, badge.badgeKey)
        }
    }
}
