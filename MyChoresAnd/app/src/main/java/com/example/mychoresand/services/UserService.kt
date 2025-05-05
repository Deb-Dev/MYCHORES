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
     * Get a user by ID
     * @param userId The user ID to fetch
     * @return Flow emitting the user data or null
     */
    fun getUser(userId: String): Flow<User?> = flow {
        try {
            val snapshot = usersCollection.document(userId).get().await()
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
     * @param userId User ID
     * @param badgeKey The badge key/identifier
     * @return Boolean indicating if the badge was newly awarded
     */
    suspend fun awardBadge(userId: String, badgeKey: String): Boolean {
        try {
            // Get the current user to check if they already have the badge
            val userDoc = usersCollection.document(userId).get().await()
            val user = userDoc.toObject(User::class.java) ?: throw IllegalStateException("User not found")
            
            // Check if user already has this badge
            if (user.earnedBadgeIds.contains(badgeKey)) {
                return false
            }
            
            // Award the new badge
            usersCollection.document(userId).update(
                "earnedBadgeIds", FieldValue.arrayUnion(badgeKey)
            ).await()
            
            return true
        } catch (e: Exception) {
            throw IllegalStateException("Failed to award badge: ${e.message}")
        }
    }
    
    /**
     * Get users in a household for the leaderboard
     * @param householdId The household ID
     * @return Flow emitting list of users in the household
     */
    fun getHouseholdUsers(householdId: String): Flow<List<User>> = flow {
        try {
            val snapshot = usersCollection.whereArrayContains("householdIds", householdId).get().await()
            val users = snapshot.documents.mapNotNull { it.toObject(User::class.java) }
            emit(users)
        } catch (e: Exception) {
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
    private suspend fun checkAndAwardBadges(userId: String, totalPoints: Int, currentBadges: List<String>) {
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
