package com.example.mychoresand.models

import com.google.firebase.firestore.DocumentId
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
    var isCompleted: Boolean = false,
    var createdAt: Date = Date(),
    var completedAt: Date? = null,
    var completedByUserId: String? = null,
    var pointValue: Int = 1,
    var isRecurring: Boolean = false,
    var recurrenceType: RecurrenceType? = null,
    var recurrenceInterval: Int? = null,
    var recurrenceDaysOfWeek: List<Int>? = null,
    var recurrenceDayOfMonth: Int? = null,
    var recurrenceEndDate: Date? = null,
    var nextOccurrenceDate: Date? = null
) {
    /**
     * Types of recurrence patterns
     */
    enum class RecurrenceType {
        DAILY, WEEKLY, MONTHLY;
        
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
    }
    
    /**
     * Check if the chore is overdue
     */
    val isOverdue: Boolean
        get() = !isCompleted && dueDate?.before(Date()) == true
    
    /**
     * Create next occurrence of a recurring chore
     * @return The next occurrence of this chore, or null if it shouldn't recur
     */
    fun createNextOccurrence(): Chore? {
        if (!isRecurring || recurrenceType == null || recurrenceInterval == null) {
            return null
        }
        
        val calendar = Calendar.getInstance()
        var nextDate: Date? = null
        val occurrenceDate = nextOccurrenceDate ?: dueDate ?: return null
        
        when (recurrenceType) {
            RecurrenceType.DAILY -> {
                calendar.time = occurrenceDate
                calendar.add(Calendar.DAY_OF_MONTH, recurrenceInterval!!)
                nextDate = calendar.time
            }
            
            RecurrenceType.WEEKLY -> {
                if (!recurrenceDaysOfWeek.isNullOrEmpty()) {
                    // Calculate next occurrence based on days of week
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.DAY_OF_MONTH, 1)
                    
                    // Find the next day that matches our recurrence pattern
                    for (i in 0 until 7 * recurrenceInterval!!) {
                        val weekday = calendar.get(Calendar.DAY_OF_WEEK) - 1 // 0-indexed
                        if (recurrenceDaysOfWeek!!.contains(weekday)) {
                            nextDate = calendar.time
                            break
                        }
                        calendar.add(Calendar.DAY_OF_MONTH, 1)
                    }
                } else {
                    // Simple weekly recurrence
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.WEEK_OF_YEAR, recurrenceInterval!!)
                    nextDate = calendar.time
                }
            }
            
            RecurrenceType.MONTHLY -> {
                if (recurrenceDayOfMonth != null) {
                    // Get the base next month date
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.MONTH, recurrenceInterval!!)
                    
                    // Set to the specified day of month
                    val maxDays = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                    val day = minOf(recurrenceDayOfMonth!!, maxDays)
                    calendar.set(Calendar.DAY_OF_MONTH, day)
                    nextDate = calendar.time
                } else {
                    // Just use same day next month
                    calendar.time = occurrenceDate
                    calendar.add(Calendar.MONTH, recurrenceInterval!!)
                    nextDate = calendar.time
                }
            }
            
            else -> { /* No other types supported */ }
        }
        
        // Check if we've passed the end date
        if (recurrenceEndDate != null && nextDate != null && nextDate.after(recurrenceEndDate)) {
            return null
        }
        
        // Create the next occurrence
        return nextDate?.let {
            val newChore = this.copy(
                id = null,
                isCompleted = false,
                completedAt = null,
                completedByUserId = null,
                dueDate = it,
                nextOccurrenceDate = it,
                createdAt = Date()
            )
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
                householdId == other.householdId &&
                assignedToUserId == other.assignedToUserId &&
                dueDate == other.dueDate &&
                isCompleted == other.isCompleted
    }
    
    override fun hashCode(): Int {
        var result = id?.hashCode() ?: 0
        if (result == 0) {
            result = 31 * result + title.hashCode()
            result = 31 * result + householdId.hashCode()
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
