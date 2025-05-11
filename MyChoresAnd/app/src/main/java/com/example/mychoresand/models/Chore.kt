package com.example.mychoresand.models

import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName // Import PropertyName
import java.util.Date
import java.util.Calendar

/**
 * Represents a chore task within a household
 */
data class Chore(
    @DocumentId var id: String? = null,
    var title: String = "",
    var description: String = "",
    var householdId: String = "",
    var assignedToUserId: String? = null,
    var createdByUserId: String? = null,
    var dueDate: Date? = null,

    @get:PropertyName("isCompleted") @set:PropertyName("isCompleted") // Ensure Firestore uses "isCompleted"
    var isCompleted: Boolean = false,

    var createdAt: Date = Date(),
    var completedAt: Date? = null,
    var completedByUserId: String? = null,
    var pointValue: Int = 1,

    @get:PropertyName("isRecurring") @set:PropertyName("isRecurring") // Ensure Firestore uses "isRecurring"
    var isRecurring: Boolean = false, // Correct field name
    var recurrenceType: RecurrenceType? = null,
    var recurrenceInterval: Int? = null,
    var recurrenceDaysOfWeek: List<Int>? = null, // Stores Calendar.DAY_OF_WEEK values (1=Sun, 7=Sat)
    var recurrenceDayOfMonth: Int? = null,
    var recurrenceEndDate: Date? = null,
    var nextOccurrenceDate: Date? = null
) {
    /**
     * Types of recurrence patterns
     */
    enum class RecurrenceType(val displayName: String) { // Added displayName
        DAILY("Daily"),
        WEEKLY("Weekly"),
        MONTHLY("Monthly");

        companion object {
            fun fromString(value: String): RecurrenceType? {
                return when (value.lowercase()) {
                    "daily" -> DAILY
                    "weekly" -> WEEKLY
                    "monthly" -> MONTHLY
                    else -> null
                }
            }
        }

        // Used by Firestore serialization to get the lowercase representation
        override fun toString(): String {
            return name.lowercase()
        }
    }
    
    /**
     * Check if the chore is overdue
     */
    @get:Exclude // Prevent Firestore from trying to serialize this getter as a field "overdue"
    val isOverdue: Boolean
        get() = !isCompleted && dueDate?.before(Date()) == true
    
    /**
     * Create next occurrence of a recurring chore
     * @return The next occurrence of this chore, or null if it shouldn't recur
     */
    fun createNextOccurrence(): Chore? {
        val TAG = "Chore.createNextOccurrence"
        android.util.Log.d(TAG, "🔄 Creating next occurrence for chore: $id, title: $title")
        
        if (!isRecurring) {
            android.util.Log.d(TAG, "⚠️ Cannot create next occurrence: Chore is not recurring")
            return null
        }
        
        if (recurrenceType == null) {
            android.util.Log.d(TAG, "⚠️ Cannot create next occurrence: Missing recurrence type")
            return null
        }
        
        if (recurrenceInterval == null) {
            android.util.Log.d(TAG, "⚠️ Cannot create next occurrence: Missing recurrence interval")
            return null
        }
        
        android.util.Log.d(TAG, "📋 Recurrence info - type: $recurrenceType, interval: $recurrenceInterval")
        
        val calendar = Calendar.getInstance()
        var nextDate: Date? = null
        val occurrenceDate = nextOccurrenceDate ?: dueDate
        
        if (occurrenceDate == null) {
            android.util.Log.d(TAG, "⚠️ Cannot create next occurrence: No due date or next occurrence date")
            return null
        }
        
        android.util.Log.d(TAG, "📆 Base date for calculation: $occurrenceDate")
        
        when (recurrenceType) {
            RecurrenceType.DAILY -> {
                calendar.time = occurrenceDate
                calendar.add(Calendar.DAY_OF_MONTH, recurrenceInterval!!)
                nextDate = calendar.time
                android.util.Log.d(TAG, "📆 DAILY: Next date calculated: $nextDate")
            }
            
            RecurrenceType.WEEKLY -> {
                if (!recurrenceDaysOfWeek.isNullOrEmpty()) {
                    // Calculate next occurrence based on days of week
                    android.util.Log.d(TAG, "📆 WEEKLY with days: ${recurrenceDaysOfWeek?.joinToString()}")
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.DAY_OF_MONTH, 1)
                    
                    // Find the next day that matches our recurrence pattern
                    for (i in 0 until 7 * recurrenceInterval!!) {
                        val weekday = calendar.get(Calendar.DAY_OF_WEEK) - 1 // 0-indexed
                        android.util.Log.d(TAG, "📆 Checking day ${calendar.time}, weekday: $weekday")
                        if (recurrenceDaysOfWeek!!.contains(weekday)) {
                            nextDate = calendar.time
                            android.util.Log.d(TAG, "📆 Found matching day: $nextDate")
                            break
                        }
                        calendar.add(Calendar.DAY_OF_MONTH, 1)
                    }
                } else {
                    // Simple weekly recurrence
                    android.util.Log.d(TAG, "📆 Simple WEEKLY recurrence (no specific days)")
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.WEEK_OF_YEAR, recurrenceInterval!!)
                    nextDate = calendar.time
                    android.util.Log.d(TAG, "📆 Next date calculated: $nextDate")
                }
            }
            
            RecurrenceType.MONTHLY -> {
                if (recurrenceDayOfMonth != null) {
                    // Get the base next month date
                    android.util.Log.d(TAG, "📆 MONTHLY with day of month: $recurrenceDayOfMonth")
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.MONTH, recurrenceInterval!!)
                    
                    // Set to the specified day of month
                    val maxDays = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                    val day = minOf(recurrenceDayOfMonth!!, maxDays)
                    android.util.Log.d(TAG, "📆 Target day: $day (max: $maxDays)")
                    calendar.set(Calendar.DAY_OF_MONTH, day)
                    nextDate = calendar.time
                    android.util.Log.d(TAG, "📆 Next date calculated: $nextDate")
                } else {
                    // Just use same day next month
                    android.util.Log.d(TAG, "📆 Simple MONTHLY recurrence (same day)")
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.MONTH, recurrenceInterval!!)
                    nextDate = calendar.time
                    android.util.Log.d(TAG, "📆 Next date calculated: $nextDate")
                }
            }
            
            else -> { 
                android.util.Log.d(TAG, "⚠️ Unsupported recurrence type: $recurrenceType")
            }
        }
        
        // Check if we've passed the end date
        if (recurrenceEndDate != null && nextDate != null) {
            android.util.Log.d(TAG, "📆 Checking end date: $recurrenceEndDate vs next date: $nextDate")
            if (nextDate.after(recurrenceEndDate)) {
                android.util.Log.d(TAG, "⛔ Next date is after end date, no more occurrences")
                return null
            }
        }
        
        // Create the next occurrence
        return nextDate?.let {
            android.util.Log.d(TAG, "✅ Creating next occurrence with due date: $it")
            val newChore = this.copy(
                id = null,
                isCompleted = false,
                completedAt = null,
                completedByUserId = null,
                dueDate = it,
                nextOccurrenceDate = it,
                createdAt = Date()
            )
            android.util.Log.d(TAG, "🆕 New chore created: ${newChore.title}, dueDate: ${newChore.dueDate}")
            newChore
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        
        other as Chore
        
        // If both have IDs, compare IDs
        if (id != null && other.id != null) {
            return id == other.id
        }
        
        // Otherwise compare critical properties
        return title == other.title &&
                description == other.description &&
                householdId == other.householdId &&
                pointValue == other.pointValue &&
                assignedToUserId == other.assignedToUserId &&
                dueDate == other.dueDate &&
                isCompleted == other.isCompleted
    }
    
    override fun hashCode(): Int {
        var result = id?.hashCode() ?: 0
        if (result == 0) {
            result = 31 * result + title.hashCode()
            result = 31 * result + description.hashCode()
            result = 31 * result + householdId.hashCode()
            result = 31 * result + pointValue.hashCode()
            result = 31 * result + (assignedToUserId?.hashCode() ?: 0)
            result = 31 * result + (dueDate?.hashCode() ?: 0)
            result = 31 * result + isCompleted.hashCode()
        }
        return result
    }
    
    companion object {
        val samples = listOf(
            Chore(
                id = "sample_chore_1",
                title = "Clean kitchen",
                description = "Wash dishes, wipe counters, and mop floor",
                householdId = "sample_household_id",
                assignedToUserId = "sample_user_id",
                dueDate = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, 1) }.time,
                isCompleted = false,
                createdAt = Date(),
                pointValue = 3
            ),
            Chore(
                id = "sample_chore_2",
                title = "Take out trash",
                description = "Don't forget to separate recycling",
                householdId = "sample_household_id",
                assignedToUserId = "sample_user_id_2",
                dueDate = Calendar.getInstance().apply { add(Calendar.HOUR, -3) }.time,
                isCompleted = true,
                createdAt = Date(System.currentTimeMillis() - 86400000),
                completedAt = Calendar.getInstance().apply { add(Calendar.HOUR, -1) }.time,
                completedByUserId = "sample_user_id_2",
                pointValue = 1
            ),
            Chore(
                id = "sample_chore_3",
                title = "Mow the lawn",
                description = "Cut the grass in the front and back yard",
                householdId = "sample_household_id",
                assignedToUserId = "sample_user_id",
                dueDate = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, 2) }.time,
                isCompleted = false,
                createdAt = Date(System.currentTimeMillis() - 86400000 * 2),
                pointValue = 5,
                isRecurring = true,
                recurrenceType = RecurrenceType.WEEKLY,
                recurrenceInterval = 2,
                recurrenceDaysOfWeek = listOf(6) // Saturday
            ),
            Chore(
                id = "sample_chore_4",
                title = "Buy groceries",
                description = "Milk, eggs, bread, fruits, and vegetables",
                householdId = "sample_household_id",
                dueDate = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, -1) }.time,
                isCompleted = false,
                createdAt = Date(System.currentTimeMillis() - 86400000 * 3),
                pointValue = 2
            )
        )
    }
}
