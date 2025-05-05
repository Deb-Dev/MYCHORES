package com.example.mychoresand.services

import com.example.mychoresand.models.Chore
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
            val query = choresCollection
                .whereEqualTo("householdId", householdId)
                .whereEqualTo("isCompleted", completed)
            
            val queryWithSort = if (!completed) {
                // For pending chores, sort by due date (earliest first)
                query.orderBy("dueDate", Query.Direction.ASCENDING)
            } else {
                // For completed chores, sort by completion date (most recent first)
                query.orderBy("completedAt", Query.Direction.DESCENDING)
            }
            
            val snapshot = queryWithSort.get().await()
            val chores = snapshot.documents.mapNotNull { it.toObject(Chore::class.java) }
            emit(chores)
        } catch (e: Exception) {
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
            
            val queryWithSort = if (!completed) {
                // For pending chores, sort by due date (earliest first)
                query.orderBy("dueDate", Query.Direction.ASCENDING)
            } else {
                // For completed chores, sort by completion date (most recent first)
                query.orderBy("completedAt", Query.Direction.DESCENDING)
            }
            
            val snapshot = queryWithSort.get().await()
            val chores = snapshot.documents.mapNotNull { it.toObject(Chore::class.java) }
            emit(chores)
        } catch (e: Exception) {
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
            val chore = snapshot.toObject(Chore::class.java)
            emit(chore)
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
