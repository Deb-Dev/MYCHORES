package com.example.mychoresand.utils

import com.example.mychoresand.models.Chore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.QueryDocumentSnapshot
import com.google.firebase.firestore.QuerySnapshot

/**
 * Helper class to convert between Firestore data and model objects with proper enum handling
 */
object FirestoreEnumConverter {

    /**
     * Convert a Firestore document to a Chore object with proper enum handling
     * @param document The Firestore document
     * @return The converted Chore object
     */
    fun toChore(document: QueryDocumentSnapshot): Chore {
        val data = document.data
        
        // Extract basic fields
        val id = document.id
        val title = data["title"] as? String ?: ""
        val description = data["description"] as? String ?: ""
        val householdId = data["householdId"] as? String ?: ""
        val assignedToUserId = data["assignedToUserId"] as? String
        val createdByUserId = data["createdByUserId"] as? String
        val isCompleted = data["isCompleted"] as? Boolean ?: false
        val pointValue = (data["pointValue"] as? Number)?.toInt() ?: 1
        val isRecurring = data["isRecurring"] as? Boolean ?: false
        
        // Extract dates
        val createdAt = (data["createdAt"] as? com.google.firebase.Timestamp)?.toDate() ?: java.util.Date()
        val dueDate = (data["dueDate"] as? com.google.firebase.Timestamp)?.toDate()
        val completedAt = (data["completedAt"] as? com.google.firebase.Timestamp)?.toDate()
        val recurrenceEndDate = (data["recurrenceEndDate"] as? com.google.firebase.Timestamp)?.toDate()
        val nextOccurrenceDate = (data["nextOccurrenceDate"] as? com.google.firebase.Timestamp)?.toDate()
        
        // Handle completedByUserId
        val completedByUserId = data["completedByUserId"] as? String
        
        // Handle enum field - convert to proper enum value
        val recurrenceTypeStr = data["recurrenceType"] as? String
        val recurrenceType = if (recurrenceTypeStr != null) {
            try {
                Chore.RecurrenceType.valueOf(recurrenceTypeStr.uppercase())
            } catch (e: IllegalArgumentException) {
                when (recurrenceTypeStr.lowercase()) {
                    "daily" -> Chore.RecurrenceType.DAILY
                    "weekly" -> Chore.RecurrenceType.WEEKLY
                    "monthly" -> Chore.RecurrenceType.MONTHLY
                    else -> null
                }
            }
        } else null
        
        // Handle numeric fields
        val recurrenceInterval = (data["recurrenceInterval"] as? Number)?.toInt()
        val recurrenceDayOfMonth = (data["recurrenceDayOfMonth"] as? Number)?.toInt()
        
        // Handle List<Int> field
        @Suppress("UNCHECKED_CAST")
        val recurrenceDaysOfWeek = (data["recurrenceDaysOfWeek"] as? List<*>)?.mapNotNull { 
            (it as? Number)?.toInt() 
        }
        
        return Chore(
            id = id,
            title = title,
            description = description,
            householdId = householdId,
            assignedToUserId = assignedToUserId,
            createdByUserId = createdByUserId,
            dueDate = dueDate,
            isCompleted = isCompleted,
            createdAt = createdAt,
            completedAt = completedAt,
            completedByUserId = completedByUserId,
            pointValue = pointValue,
            isRecurring = isRecurring,
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval,
            recurrenceDaysOfWeek = recurrenceDaysOfWeek,
            recurrenceDayOfMonth = recurrenceDayOfMonth,
            recurrenceEndDate = recurrenceEndDate,
            nextOccurrenceDate = nextOccurrenceDate
        )
    }
    
    /**
     * Convert a QuerySnapshot to a list of Chore objects with proper enum handling
     * @param snapshot The Firestore query snapshot
     * @return List of Chore objects
     */
    fun toChoreList(snapshot: QuerySnapshot): List<Chore> {
        return snapshot.documents.mapNotNull { 
            try {
                if (it is QueryDocumentSnapshot) {
                    toChore(it)
                } else {
                    null
                }
            } catch (e: Exception) {
                android.util.Log.e("FirestoreEnumConverter", "Error converting document to Chore: ${e.message}", e)
                null
            }
        }
    }
}
