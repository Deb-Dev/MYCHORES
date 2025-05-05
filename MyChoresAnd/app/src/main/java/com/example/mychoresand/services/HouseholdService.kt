package com.example.mychoresand.services

import com.example.mychoresand.models.Household
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.tasks.await
import java.util.Date
import java.util.UUID

/**
 * Service handling household data operations
 */
class HouseholdService {
    private val auth = FirebaseAuth.getInstance()
    private val firestore = FirebaseFirestore.getInstance()
    private val householdsCollection = firestore.collection("households")
    private val usersCollection = firestore.collection("users")
    
    /**
     * Get households for the current user
     * @return Flow emitting list of households
     */
    fun getUserHouseholds(): Flow<List<Household>> = flow {
        val uid = auth.currentUser?.uid ?: run {
            emit(emptyList())
            return@flow
        }
        
        try {
            // Get the user to find their household IDs
            val userDoc = usersCollection.document(uid).get().await()
            val householdIds = userDoc.get("householdIds") as? List<String> ?: emptyList()
            
            if (householdIds.isEmpty()) {
                emit(emptyList())
                return@flow
            }
            
            // Fetch all the households
            val snapshot = householdsCollection.whereIn("id", householdIds).get().await()
            val households = snapshot.documents.mapNotNull { it.toObject(Household::class.java) }
            emit(households)
        } catch (e: Exception) {
            emit(emptyList())
        }
    }
    
    /**
     * Get a household by ID
     * @param householdId The household ID to fetch
     * @return Flow emitting the household data or null
     */
    fun getHousehold(householdId: String): Flow<Household?> = flow {
        try {
            val snapshot = householdsCollection.document(householdId).get().await()
            val household = snapshot.toObject(Household::class.java)
            emit(household)
        } catch (e: Exception) {
            emit(null)
        }
    }
    
    /**
     * Create a new household
     * @param name Name of the household
     * @return Result containing the created household if successful
     */
    suspend fun createHousehold(name: String): Result<Household> {
        val uid = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        
        return try {
            // Generate a unique invite code
            val inviteCode = generateInviteCode()
            
            // Create the household
            val household = Household(
                name = name,
                ownerUserId = uid,
                memberUserIds = listOf(uid),
                inviteCode = inviteCode,
                createdAt = Date()
            )
            
            // Add to Firestore
            val docRef = householdsCollection.document()
            val householdWithId = household.copy(id = docRef.id)
            docRef.set(householdWithId).await()
            
            // Add household to user's list
            val userRef = usersCollection.document(uid)
            val userDoc = userRef.get().await()
            val currentHouseholds = userDoc.get("householdIds") as? List<String> ?: emptyList()
            val updatedHouseholds = currentHouseholds + docRef.id
            
            userRef.update("householdIds", updatedHouseholds).await()
            
            Result.success(householdWithId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Join a household using its invite code
     * @param inviteCode The household's invite code
     * @return Result containing the joined household if successful
     */
    suspend fun joinHousehold(inviteCode: String): Result<Household> {
        val uid = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        
        return try {
            // Find the household by invite code
            val snapshot = householdsCollection.whereEqualTo("inviteCode", inviteCode).get().await()
            
            if (snapshot.isEmpty) {
                return Result.failure(Exception("Invalid invite code"))
            }
            
            val householdDoc = snapshot.documents.first()
            val household = householdDoc.toObject(Household::class.java)
                ?: return Result.failure(Exception("Error loading household data"))
            
            // Check if user is already a member
            if (household.memberUserIds.contains(uid)) {
                return Result.success(household)
            }
            
            // Add user to household
            val updatedMembers = household.memberUserIds + uid
            householdsCollection.document(householdDoc.id).update("memberUserIds", updatedMembers).await()
            
            // Add household to user's list
            val userRef = usersCollection.document(uid)
            val userDoc = userRef.get().await()
            val currentHouseholds = userDoc.get("householdIds") as? List<String> ?: emptyList()
            val updatedHouseholds = currentHouseholds + householdDoc.id
            
            userRef.update("householdIds", updatedHouseholds).await()
            
            val updatedHousehold = household.copy(memberUserIds = updatedMembers)
            Result.success(updatedHousehold)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Leave a household
     * @param householdId The ID of the household to leave
     * @return Result indicating success or failure
     */
    suspend fun leaveHousehold(householdId: String): Result<Unit> {
        val uid = auth.currentUser?.uid ?: return Result.failure(Exception("User not logged in"))
        
        return try {
            // Get the household
            val householdDoc = householdsCollection.document(householdId).get().await()
            val household = householdDoc.toObject(Household::class.java)
                ?: return Result.failure(Exception("Household not found"))
            
            // Check if user is the owner
            if (household.ownerUserId == uid && household.memberUserIds.size > 1) {
                return Result.failure(Exception("Owner cannot leave a household with other members"))
            }
            
            // If user is the only member, delete the household
            if (household.memberUserIds.size == 1 && household.memberUserIds.contains(uid)) {
                householdsCollection.document(householdId).delete().await()
            } else {
                // Remove user from household
                val updatedMembers = household.memberUserIds.filter { it != uid }
                householdsCollection.document(householdId).update("memberUserIds", updatedMembers).await()
            }
            
            // Remove household from user's list
            val userRef = usersCollection.document(uid)
            val userDoc = userRef.get().await()
            val currentHouseholds = userDoc.get("householdIds") as? List<String> ?: emptyList()
            val updatedHouseholds = currentHouseholds.filter { it != householdId }
            
            userRef.update("householdIds", updatedHouseholds).await()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Generate a unique invite code for a new household
     * @return A 6-character alphanumeric code
     */
    private suspend fun generateInviteCode(): String {
        // Generate a random 6-character alphanumeric code
        val charPool: List<Char> = ('A'..'Z') + ('0'..'9')
        
        // Try up to 5 times to generate a unique code
        for (attempt in 1..5) {
            val code = (1..6)
                .map { charPool.random() }
                .joinToString("")
            
            // Check if code is already in use
            val snapshot = householdsCollection.whereEqualTo("inviteCode", code).get().await()
            if (snapshot.isEmpty) {
                return code
            }
        }
        
        // If we couldn't generate a unique code after 5 attempts, use a UUID-based fallback
        return UUID.randomUUID().toString().take(6).toUpperCase()
    }
}
