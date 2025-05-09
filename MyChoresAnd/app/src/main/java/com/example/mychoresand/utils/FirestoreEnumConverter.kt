package com.example.mychoresand.utils

import com.example.mychoresand.models.Chore
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.QuerySnapshot
import java.util.Date

/**
 * Helper class to convert between Firestore data and model objects with proper enum handling
 */
object FirestoreEnumConverter {
    private const val TAG = "FirestoreEnumConverter"

    /**
     * Convert a Firestore document to a Chore object
     * @param document The Firestore document
     * @return The converted Chore object, or null if data is missing
     */
    fun toChore(document: DocumentSnapshot): Chore? {
        try {
            // Data validation - ensure document exists and has data
            if (!document.exists()) {
                android.util.Log.e(TAG, "❌ Document doesn't exist: ${document.id}")
                return null
            }
            
            val data = document.data
            if (data == null) {
                android.util.Log.e(TAG, "❌ Document has no data: ${document.id}")
                return null
            }
            
            // Log the document data for debugging
            android.util.Log.d(TAG, "📄 Converting document: ${document.id}")
            
            // Extract basic fields with validation
            val id = document.id
            val title = data["title"] as? String ?: ""
            if (title.isBlank()) {
                android.util.Log.w(TAG, "⚠️ Document has blank title: $id")
            }
            
            val householdId = data["householdId"] as? String ?: ""
            if (householdId.isBlank()) {
                android.util.Log.w(TAG, "⚠️ Document has blank householdId: $id")
            }
            
            val description = data["description"] as? String ?: ""
            val assignedToUserId = data["assignedToUserId"] as? String
            val createdByUserId = data["createdByUserId"] as? String
            val isCompleted = data["isCompleted"] as? Boolean ?: false
            val pointValue = (data["pointValue"] as? Number)?.toInt() ?: 1
            val isRecurring = data["isRecurring"] as? Boolean ?: false
            
            // Extract dates with validation
            val createdAt = try {
                (data["createdAt"] as? com.google.firebase.Timestamp)?.toDate() ?: Date()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing createdAt: ${e.message}")
                Date()
            }
            
            val dueDate = try {
                (data["dueDate"] as? com.google.firebase.Timestamp)?.toDate()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing dueDate: ${e.message}")
                null
            }
            
            val completedAt = try {
                (data["completedAt"] as? com.google.firebase.Timestamp)?.toDate()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing completedAt: ${e.message}")
                null
            }
            
            val recurrenceEndDate = try {
                (data["recurrenceEndDate"] as? com.google.firebase.Timestamp)?.toDate()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing recurrenceEndDate: ${e.message}")
                null
            }
            
            val nextOccurrenceDate = try {
                (data["nextOccurrenceDate"] as? com.google.firebase.Timestamp)?.toDate()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing nextOccurrenceDate: ${e.message}")
                null
            }
            
            // Handle completedByUserId
            val completedByUserId = data["completedByUserId"] as? String

            // Handle enum field - convert to proper enum value with detailed logging
            val recurrenceTypeStr = data["recurrenceType"] as? String
            android.util.Log.d(TAG, "📊 Raw recurrenceType from Firestore: $recurrenceTypeStr")
            
            val recurrenceType = if (recurrenceTypeStr != null) {
                try {
                    val enumValue = Chore.RecurrenceType.valueOf(recurrenceTypeStr.uppercase())
                    android.util.Log.d(TAG, "✅ Converted recurrenceType to enum: $enumValue")
                    enumValue
                } catch (e: IllegalArgumentException) {
                    android.util.Log.w(TAG, "⚠️ Could not convert recurrenceType directly, trying fallback: $recurrenceTypeStr")
                    when (recurrenceTypeStr.lowercase()) {
                        "daily" -> {
                            android.util.Log.d(TAG, "✅ Fallback matched: DAILY")
                            Chore.RecurrenceType.DAILY
                        }
                        "weekly" -> {
                            android.util.Log.d(TAG, "✅ Fallback matched: WEEKLY")
                            Chore.RecurrenceType.WEEKLY
                        }
                        "monthly" -> {
                            android.util.Log.d(TAG, "✅ Fallback matched: MONTHLY")
                            Chore.RecurrenceType.MONTHLY
                        }
                        else -> {
                            android.util.Log.e(TAG, "❌ Unrecognized recurrenceType: $recurrenceTypeStr")
                            null
                        }
                    }
                }
            } else {
                android.util.Log.d(TAG, "ℹ️ No recurrenceType found in document")
                null
            }
            
            // Handle numeric fields with validation
            val recurrenceInterval = try {
                (data["recurrenceInterval"] as? Number)?.toInt()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing recurrenceInterval: ${e.message}")
                null
            }
            
            val recurrenceDayOfMonth = try {
                (data["recurrenceDayOfMonth"] as? Number)?.toInt()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing recurrenceDayOfMonth: ${e.message}")
                null
            }

            // Handle List<Int> field with validation
            val recurrenceDaysOfWeek = try {
                @Suppress("UNCHECKED_CAST")
                (data["recurrenceDaysOfWeek"] as? List<*>)?.mapNotNull {
                    (it as? Number)?.toInt()
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error parsing recurrenceDaysOfWeek: ${e.message}")
                null
            }
            
            // Create and return the Chore object
            val chore = Chore(
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
            
            android.util.Log.d(TAG, "✅ Successfully converted document to Chore: ${chore.id}, title: ${chore.title}")
            return chore
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "❌ Unexpected error converting document to Chore: ${e.message}", e)
            return null
        }
    }

    /**
     * Convert a QuerySnapshot to a list of Chore objects with proper enum handling
     * @param snapshot The Firestore query snapshot
     * @return List of Chore objects
     */
    fun toChoreList(snapshot: QuerySnapshot): List<Chore> {
        android.util.Log.d(TAG, "Converting QuerySnapshot with ${snapshot.size()} documents")
        
        if (snapshot.isEmpty) {
            android.util.Log.d(TAG, "QuerySnapshot is empty, returning empty list")
            return emptyList()
        }
        
        // Map document snapshots to Chore objects, filtering out nulls
        val chores = snapshot.documents.mapIndexedNotNull { index, document -> 
            try {
                val chore = toChore(document)
                if (chore == null) {
                    android.util.Log.w(TAG, "⚠️ Document at index $index could not be converted to Chore: ${document.id}")
                }
                chore
            } catch (e: Exception) {
                android.util.Log.e(TAG, "❌ Error converting document at index $index: ${e.message}", e)
                null
            }
        }
        
        android.util.Log.d(TAG, "✅ Converted ${chores.size} documents to Chore objects out of ${snapshot.size()} total")
        
        // Log any warning if documents were dropped during conversion
        if (chores.size < snapshot.size()) {
            android.util.Log.w(TAG, "⚠️ ${snapshot.size() - chores.size} documents could not be converted to Chore objects")
        }
        
        return chores
    }
}
