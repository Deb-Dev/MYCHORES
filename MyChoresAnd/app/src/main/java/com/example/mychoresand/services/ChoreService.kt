package com.example.mychoresand.services

import com.example.mychoresand.models.Chore
import com.example.mychoresand.utils.FirestoreEnumConverter
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.tasks.await
import java.util.Date

/**
 * Service handling chore data operations
 */
class ChoreService(private val userService: UserService) {
    private val auth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()
    private val choresCollection = firestore.collection("chores")
    
    /**
     * Get all chores for a household
     * @param householdId The household ID
     * @param completed Whether to fetch completed or pending chores
     * @return Flow emitting the list of chores
     */
    fun getHouseholdChores(householdId: String, completed: Boolean): Flow<List<Chore>> = flow {
        try {
            // Match iOS implementation - don't use compound sorting that requires indexes
            val query = choresCollection
                .whereEqualTo("householdId", householdId)
                .whereEqualTo("isCompleted", completed)
            
            // Get all documents without sorting (for now) to avoid index requirements
            val snapshot = query.get().await()
            
            // Use custom converter to handle lowercase enum values from Firestore
            val chores = FirestoreEnumConverter.toChoreList(snapshot)
            
            // Sort locally after fetching the data
            val sortedChores = if (!completed) {
                // For pending chores, sort by due date (earliest first)
                chores.sortedBy { it.dueDate }
            } else {
                // For completed chores, sort by completion date (most recent first)
                chores.sortedByDescending { it.completedAt }
            }
            
            emit(sortedChores)
        } catch (e: Exception) {
            // Log the error
            android.util.Log.e("ChoreService", "Error fetching chores: ${e.message}", e)
            emit(emptyList())
        }
    }
    
    /**
     * Get chores assigned to the current user
     * @param completed Whether to fetch completed or pending chores
     * @return Flow emitting the list of chores
     */
    fun getUserChores(completed: Boolean): Flow<List<Chore>> = flow {
        val uid = auth.currentUser?.uid ?: run {
            emit(emptyList())
            return@flow
        }
        
        try {
            val query = choresCollection
                .whereEqualTo("assignedToUserId", uid)
                .whereEqualTo("isCompleted", completed)
            
            // Get all documents without sorting (for now) to avoid index requirements
            val snapshot = query.get().await()
            
            // Use custom converter to handle lowercase enum values from Firestore
            val chores = FirestoreEnumConverter.toChoreList(snapshot)
            
            // Sort locally after fetching the data
            val sortedChores = if (!completed) {
                // For pending chores, sort by due date (earliest first)
                chores.sortedBy { it.dueDate }
            } else {
                // For completed chores, sort by completion date (most recent first)
                chores.sortedByDescending { it.completedAt }
            }
            
            emit(sortedChores)
        } catch (e: Exception) {
            // Log the error
            android.util.Log.e("ChoreService", "Error fetching user chores: ${e.message}", e)
            emit(emptyList())
        }
    }
    
    /**
     * Get a single chore by ID
     * @param choreId The chore ID to fetch
     * @return Flow emitting the chore or null
     */
    fun getChore(choreId: String): Flow<Chore?> = flow {
        try {
            val snapshot = choresCollection.document(choreId).get().await()
            if (snapshot.exists()) {
                // Convert to QueryDocumentSnapshot for our converter to use
                val chore = if (snapshot is com.google.firebase.firestore.QueryDocumentSnapshot) {
                    FirestoreEnumConverter.toChore(snapshot)
                } else {
                    // Create a custom mapping for DocumentSnapshot if needed
                    val data = snapshot.data
                    if (data != null) {
                        // Handle the conversion manually for single document case
                        val recurrenceTypeStr = data["recurrenceType"] as? String
                        val recurrenceType = when (recurrenceTypeStr?.lowercase()) {
                            "daily" -> Chore.RecurrenceType.DAILY
                            "weekly" -> Chore.RecurrenceType.WEEKLY
                            "monthly" -> Chore.RecurrenceType.MONTHLY
                            else -> null
                        }
                        
                        // Create the Chore with properly parsed recurrenceType
                        snapshot.toObject(Chore::class.java)?.copy(
                            recurrenceType = recurrenceType
                        )
                    } else {
                        null
                    }
                }
                emit(chore)
            } else {
                emit(null)
            }
        } catch (e: Exception) {
            emit(null)
        }
    }
    
    /**
     * Create a new chore
     * @param chore The chore to create
     * @return Result containing the created chore if successful
     */
    suspend fun createChore(chore: Chore): Result<Chore> {
        val uid = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        
        // Set creator user ID if not already set
        val updatedChore = chore.copy(
            createdByUserId = chore.createdByUserId ?: uid,
            createdAt = Date()
        )
        
        return try {
            val docRef = choresCollection.document()
            val choreWithId = updatedChore.copy(id = docRef.id)
            docRef.set(choreWithId).await()
            
            Result.success(choreWithId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing chore
     * @param chore The chore with updated values
     * @return Result indicating success or failure
     */
    suspend fun updateChore(chore: Chore): Result<Unit> {
        // Ensure the chore has an ID
        val choreId = chore.id ?: return Result.failure(Exception("Chore has no ID"))
        
        return try {
            choresCollection.document(choreId).set(chore).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a chore
     * @param choreId The ID of the chore to delete
     * @return Result indicating success or failure
     */
    suspend fun deleteChore(choreId: String): Result<Unit> {
        return try {
            choresCollection.document(choreId).delete().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Mark a chore as completed
     * @param choreId The ID of the chore to mark as completed
     * @return Result containing the completed chore if successful
     */
    suspend fun completeChore(choreId: String): Result<Chore> {
        val uid = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        
        return try {
            // Get the chore
            val choreDoc = choresCollection.document(choreId).get().await()
            val chore = choreDoc.toObject(Chore::class.java)
                ?: return Result.failure(Exception("Chore not found"))
            
            // Mark as completed
            val completedChore = chore.copy(
                isCompleted = true,
                completedAt = Date(),
                completedByUserId = uid
            )
            
            // Update in Firestore
            choresCollection.document(choreId).set(completedChore).await()
            
            // Award points to the user who completed it
            userService.addPoints(uid, chore.pointValue)
            
            // Create next occurrence if this is a recurring chore
            if (chore.isRecurring) {
                chore.createNextOccurrence()?.let { nextChore ->
                    createChore(nextChore)
                }
            }
            
            Result.success(completedChore)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
