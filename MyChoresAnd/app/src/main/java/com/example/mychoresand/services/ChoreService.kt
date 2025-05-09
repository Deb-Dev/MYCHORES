package com.example.mychoresand.services

import com.example.mychoresand.models.Chore
import com.example.mychoresand.utils.FirestoreEnumConverter
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first // Added import for first()
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

    companion object {
        private const val TAG = "ChoreService"
    }
    
    /**
     * Get all chores for a household
     * @param householdId The household ID
     * @param completed Whether to fetch completed or pending chores
     * @return Flow emitting the list of chores
     */
    fun getHouseholdChores(householdId: String, completed: Boolean): Flow<List<Chore>> = flow {
        try {
            android.util.Log.d(TAG, "Fetching ${if (completed) "completed" else "pending"} chores for household: $householdId")
            // Match iOS implementation - don't use compound sorting that requires indexes
            val query = choresCollection
                .whereEqualTo("householdId", householdId)
                .whereEqualTo("isCompleted", completed)
            
            // Get all documents without sorting (for now) to avoid index requirements
            val snapshot = query.get().await()
            android.util.Log.d(TAG, "Fetched ${snapshot.size()} chores from Firestore")
            
            // Use custom converter to handle lowercase enum values from Firestore
            val chores = FirestoreEnumConverter.toChoreList(snapshot)
            android.util.Log.d(TAG, "Converted to ${chores.size} Chore objects")
            
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
            android.util.Log.e(TAG, "Error fetching chores: ${e.message}", e)
            // Emit empty list instead of re-throwing the exception to prevent Flow cancellation
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
            android.util.Log.w(TAG, "Cannot fetch user chores: No user logged in")
            emit(emptyList())
            return@flow
        }
        
        try {
            android.util.Log.d(TAG, "Fetching ${if (completed) "completed" else "pending"} chores for user: $uid")
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
            android.util.Log.e(TAG, "Error fetching user chores: ${e.message}", e)
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
            android.util.Log.d(TAG, "Fetching chore with ID: $choreId")
            val snapshot = choresCollection.document(choreId).get().await()
            if (snapshot.exists()) {
                android.util.Log.d(TAG, "Chore document exists, converting...")
                // Directly use FirestoreEnumConverter.toChore with DocumentSnapshot
                val chore = FirestoreEnumConverter.toChore(snapshot)
                android.util.Log.d(TAG, "Converted chore: $chore")
                emit(chore)
            } else {
                android.util.Log.w(TAG, "Chore document with ID $choreId does not exist.")
                emit(null)
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error fetching chore $choreId: ${e.message}", e)
            // Emit null instead of re-throwing the exception to prevent Flow cancellation
            emit(null)
        }
    }
    
    /**
     * Create a new chore
     * @param chore The chore to create
     * @return Result containing the created chore if successful
     */
    suspend fun createChore(chore: Chore): Result<Chore> {
        android.util.Log.d(TAG, "🚀 ChoreService.createChore called with chore. Title: ${chore.title}, HouseholdId: ${chore.householdId}")
        if (chore.householdId.isBlank()) {
            android.util.Log.e(TAG, "❌ Cannot create chore: Household ID is blank in received chore object. Title: ${chore.title}")
            return Result.failure(Exception("Cannot create chore: Household ID is blank"))
        }

        val uid = auth.currentUser?.uid
        if (uid == null) {
            android.util.Log.e(TAG, "❌ Cannot create chore: User not logged in. Title: ${chore.title}")
            return Result.failure(Exception("User not logged in"))
        }

        android.util.Log.d(TAG, "Creating chore in household: ${chore.householdId} by user: $uid")
        android.util.Log.d(TAG, "Chore details: Title='${chore.title}', Desc='${chore.description}', Points=${chore.pointValue}, Due='${chore.dueDate}', Recurring=${chore.isRecurring}")

        // Set/confirm creator user ID, creation date, and next occurrence date
        val finalChore = chore.copy(
            createdByUserId = uid, // Ensure current user is creator
            createdAt = Date(), // Set definitive creation timestamp
            // nextOccurrenceDate is already set by ViewModel, but ensure consistency:
            // if recurring and original due date was provided, it's the first next occurrence.
            nextOccurrenceDate = if (chore.isRecurring && chore.dueDate != null) chore.dueDate else null
        )

        return try {
            val docId = finalChore.id ?: choresCollection.document().id
            val choreWithId = finalChore.copy(id = docId)

            android.util.Log.d(TAG, "📝 Attempting to save chore with generated ID: $docId. Full chore data: $choreWithId")
            android.util.Log.d(TAG, "Saving to Firestore. HouseholdId being written: ${choreWithId.householdId}")

            val documentRef = choresCollection.document(docId)
            documentRef.set(choreWithId).await()
            android.util.Log.d(TAG, "✅ Firestore set() operation complete for chore ID: $docId")

            // The explicit update of the 'id' field might be redundant if @DocumentId works as expected,
            // but keeping it for now if it was part of a pattern to ensure field presence.
            // Consider removing if it causes issues or is confirmed unnecessary.
            // val updates = mapOf("id" to docId)
            // android.util.Log.d(TAG, "🔄 Updating document with explicit ID field (currently commented out for review)")
            // documentRef.update(updates).await()
            // android.util.Log.d(TAG, "✅ ID field update complete (currently commented out for review)")

            android.util.Log.d(TAG, "🔍 Verifying chore was saved by fetching it back: $docId")
            val verifiedChoreSnapshot = documentRef.get().await()
            
            if (verifiedChoreSnapshot.exists()) {
                android.util.Log.d(TAG, "📝 Verified snapshot data for $docId: ${verifiedChoreSnapshot.data}")
                val verifiedChore = FirestoreEnumConverter.toChore(verifiedChoreSnapshot)
                if (verifiedChore != null) {
                    android.util.Log.d(TAG, "✅ Chore created and verified: ${verifiedChore.id}, Title: ${verifiedChore.title}, Household: ${verifiedChore.householdId}")
                    Result.success(verifiedChore)
                } else {
                    android.util.Log.e(TAG, "❌ Failed to convert verified chore from snapshot for $docId. Snapshot data: ${verifiedChoreSnapshot.data}")
                    Result.failure(Exception("Failed to parse verified chore after creation"))
                }
            } else {
                android.util.Log.e(TAG, "❌ Failed to verify chore after creation: Document $docId does not exist after set().")
                Result.failure(Exception("Failed to verify chore after creation: Document not found"))
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Error creating chore: ${e.message}", e)
            e.printStackTrace()
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing chore
     * @param chore The chore with updated values
     * @return Result indicating success or failure
     */
    suspend fun updateChore(chore: Chore): Result<Unit> {
        val TAG = "ChoreService.updateChore"
        android.util.Log.d(TAG, "📝 Updating chore: ${chore.id}, title: ${chore.title}")
        
        // Ensure the chore has an ID
        val choreId = chore.id ?: return Result.failure(Exception("Chore has no ID"))
        android.util.Log.d(TAG, "🔍 Verified chore has ID: $choreId")

        // Ensure createdByUserId and createdAt are preserved if they exist
        // and only update them if they are not set (e.g. for older chores)
        val choreToUpdate = chore.copy(
            createdByUserId = chore.createdByUserId ?: auth.currentUser?.uid,
            createdAt = chore.createdAt ?: Date()
        )
        
        android.util.Log.d(TAG, "📊 Chore data to update: $choreToUpdate")

        return try {
            // Update the chore in Firestore
            android.util.Log.d(TAG, "💾 Saving updated chore to Firestore...")
            choresCollection.document(choreId).set(choreToUpdate).await()
            
            // Verify the update was successful
            android.util.Log.d(TAG, "🔍 Verifying chore was updated correctly")
            val updatedChoreDoc = choresCollection.document(choreId).get().await()
            
            if (!updatedChoreDoc.exists()) {
                android.util.Log.e(TAG, "❌ Verification failed: Chore document not found after update")
                return Result.failure(Exception("Failed to verify chore update"))
            }
            
            android.util.Log.d(TAG, "✅ Chore updated successfully")
            Result.success(Unit)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Failed to update chore: ${e.message}", e)
            Result.failure(e)
        }
    }
    
    /**
     * Delete a chore
     * @param choreId The ID of the chore to delete
     * @return Result indicating success or failure
     */
    suspend fun deleteChore(choreId: String): Result<Unit> {
        val TAG = "ChoreService.deleteChore"
        android.util.Log.d(TAG, "🗑️ Deleting chore with ID: $choreId")
        
        return try {
            // Verify the chore exists before attempting to delete
            val choreDoc = choresCollection.document(choreId).get().await()
            if (!choreDoc.exists()) {
                android.util.Log.e(TAG, "❌ Cannot delete chore: Document not found in Firestore")
                return Result.failure(Exception("Chore not found"))
            }
            
            android.util.Log.d(TAG, "🔥 Chore found, proceeding with deletion")
            choresCollection.document(choreId).delete().await()
            
            // Verify the deletion was successful
            val verifySnapshot = choresCollection.document(choreId).get().await()
            if (verifySnapshot.exists()) {
                android.util.Log.e(TAG, "❌ Verification failed: Chore not deleted from Firestore")
                return Result.failure(Exception("Failed to verify chore deletion"))
            }
            
            android.util.Log.d(TAG, "✅ Chore deleted successfully and verified")
            Result.success(Unit)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Exception in deleteChore: ${e.message}", e)
            Result.failure(e)
        }
    }
    
    /**
     * Mark a chore as completed
     * @param choreId The ID of the chore to mark as completed
     * @return Result containing the completed chore if successful
     */
    suspend fun completeChore(choreId: String): Result<Chore> {
        android.util.Log.d(TAG, "🔔 completeChore called with ID: $choreId")
        
        val uid = auth.currentUser?.uid
        if (uid == null) {
            android.util.Log.e(TAG, "❌ completeChore failed: User not logged in")
            return Result.failure(Exception("User not logged in"))
        }
        
        android.util.Log.d(TAG, "👤 Current user ID: $uid")

        return try {
            // Get the chore
            android.util.Log.d(TAG, "🔍 Fetching chore document with ID: $choreId")
            val choreDoc = choresCollection.document(choreId).get().await()
            
            if (!choreDoc.exists()) {
                android.util.Log.e(TAG, "❌ completeChore failed: Chore document not found in Firestore")
                return Result.failure(Exception("Chore not found"))
            }
            
            android.util.Log.d(TAG, "📄 Chore document data: ${choreDoc.data}")
            
            val chore = FirestoreEnumConverter.toChore(choreDoc)
            if (chore == null) {
                android.util.Log.e(TAG, "❌ completeChore failed: Could not convert Firestore data to Chore object")
                return Result.failure(Exception("Chore data could not be parsed"))
            }
            
            android.util.Log.d(TAG, "📊 Original chore: $chore")

            // Mark as completed
            val completedChore = chore.copy(
                isCompleted = true,
                completedAt = Date(),
                completedByUserId = uid
            )
            
            android.util.Log.d(TAG, "✏️ Updated chore (completed): $completedChore")

            // Convert to Map to ensure all fields are included in the update
            // Using Firestore Timestamp to ensure proper data type in Firestore
            val completedDate = completedChore.completedAt ?: Date()
            val seconds = completedDate.time / 1000
            val nanoseconds = ((completedDate.time % 1000) * 1000000).toInt()
            
            val choreData = mapOf(
                "isCompleted" to true,
                "completedAt" to com.google.firebase.Timestamp(seconds, nanoseconds),
                "completedByUserId" to completedChore.completedByUserId
            )
            
            // Debug all the fields we're updating
            android.util.Log.d(TAG, "🔧 Updating with fields: isCompleted=${true}, completedAt=${completedChore.completedAt}, completedByUserId=${completedChore.completedByUserId}")
            
            // Update in Firestore using update instead of set to only change specific fields
            android.util.Log.d(TAG, "💾 Updating chore completion status in Firestore...")
            choresCollection.document(choreId).update(choreData).await()
            
            // Verify the update was successful by fetching the chore again
            android.util.Log.d(TAG, "🔍 Verifying chore was updated correctly")
            val updatedChoreDoc = choresCollection.document(choreId).get().await()
            if (!updatedChoreDoc.exists()) {
                android.util.Log.e(TAG, "❌ Verification failed: Chore document not found after update")
                return Result.failure(Exception("Failed to verify chore update"))
            }
            
            // Log raw document data for debugging
            android.util.Log.d(TAG, "📄 Updated chore document data: ${updatedChoreDoc.data}")
            
            val updatedChore = FirestoreEnumConverter.toChore(updatedChoreDoc)
            if (updatedChore == null) {
                android.util.Log.e(TAG, "❌ Verification failed: Could not convert updated chore document")
                return Result.failure(Exception("Failed to verify chore completion conversion"))
            }
            
            android.util.Log.d(TAG, "📊 Converted updatedChore: $updatedChore, isCompleted=${updatedChore.isCompleted}")
            
            if (!updatedChore.isCompleted) {
                android.util.Log.e(TAG, "❌ Verification failed: Chore not properly marked as completed, isCompleted=${updatedChore.isCompleted}")
                return Result.failure(Exception("Failed to verify chore completion status"))
            }
            
            android.util.Log.d(TAG, "✅ Chore marked as completed in Firestore and verified")

            // Award points to the user who completed it
            android.util.Log.d(TAG, "🏆 Awarding ${chore.pointValue} points to user $uid")
            userService.addPoints(uid, chore.pointValue)
            android.util.Log.d(TAG, "✅ Points awarded successfully")

            // Fetch the updated user data to get current points and badges
            android.util.Log.d(TAG, "🔄 Fetching updated user data for badge check")
            val userSnapshot = userService.getUser(uid).first() 
            if (userSnapshot != null) {
                android.util.Log.d(TAG, "👤 User data fetched: totalPoints=${userSnapshot.totalPoints}, badges=${userSnapshot.earnedBadgeIds?.size}")
                userService.checkAndAwardBadges(uid, userSnapshot.totalPoints ?: 0, userSnapshot.earnedBadgeIds ?: emptyList())
                android.util.Log.d(TAG, "🏅 Badge check completed")
            } else {
                android.util.Log.w(TAG, "⚠️ Could not fetch user data for badge check after completing chore")
            }

            // Create next occurrence if this is a recurring chore
            if (chore.isRecurring) {
                android.util.Log.d(TAG, "🔄 Chore is recurring, creating next occurrence")
                val nextChore = chore.createNextOccurrence()
                if (nextChore != null) {
                    android.util.Log.d(TAG, "📅 Next occurrence calculated: due=${nextChore.dueDate}")
                    // Ensure the next chore has a null ID so Firestore generates a new one
                    val nextChoreToCreate = nextChore.copy(id = null)
                    android.util.Log.d(TAG, "🆕 Creating new chore for next occurrence")
                    
                    // Validate the next chore has all required fields before creating
                    if (nextChoreToCreate.title.isBlank()) {
                        android.util.Log.e(TAG, "❌ Next occurrence has blank title, using original title")
                        nextChoreToCreate.title = chore.title
                    }
                    
                    if (nextChoreToCreate.householdId.isBlank()) {
                        android.util.Log.e(TAG, "❌ Next occurrence has blank householdId, using original householdId")
                        nextChoreToCreate.householdId = chore.householdId
                    }
                    
                    android.util.Log.d(TAG, "📊 Validated next chore: $nextChoreToCreate")
                    
                    val createResult = createChore(nextChoreToCreate)
                    createResult.fold(
                        onSuccess = { newChore ->
                            android.util.Log.d(TAG, "✅ Next occurrence created successfully with ID: ${newChore.id}")
                            
                            // Verify the new chore was saved by fetching it back
                            android.util.Log.d(TAG, "🔍 Verifying next occurrence was saved properly")
                            val verifiedNextChoreSnapshot = choresCollection.document(newChore.id!!).get().await()
                            if (verifiedNextChoreSnapshot.exists()) {
                                android.util.Log.d(TAG, "✅ Next occurrence verified in Firestore")
                            } else {
                                android.util.Log.e(TAG, "⚠️ Could not verify next occurrence in Firestore")
                            }
                        },
                        onFailure = { error ->
                            android.util.Log.e(TAG, "❌ Failed to create next occurrence: ${error.message}", error)
                        }
                    )
                } else {
                    android.util.Log.d(TAG, "ℹ️ No next occurrence to create (end of recurrence or invalid pattern)")
                }
            } else {
                android.util.Log.d(TAG, "ℹ️ Chore is not recurring, no next occurrence needed")
            }

            android.util.Log.d(TAG, "✅ completeChore operation successful")
            Result.success(completedChore)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Exception in completeChore: ${e.message}", e)
            e.printStackTrace()
            Result.failure(e)
        }
    }
}
