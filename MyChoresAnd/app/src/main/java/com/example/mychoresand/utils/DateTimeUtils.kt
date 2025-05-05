package com.example.mychoresand.utils

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Utility class for date and time operations
 */
object DateTimeUtils {
    
    /**
     * Format a date with the specified pattern
     */
    fun formatDate(date: Date?, pattern: String = "MMM dd, yyyy"): String {
        if (date == null) return ""
        val dateFormat = SimpleDateFormat(pattern, Locale.getDefault())
        return dateFormat.format(date)
    }
    
    /**
     * Format a date for short display (e.g., "Mar 5")
     */
    fun formatShortDate(date: Date?): String {
        return formatDate(date, "MMM d")
    }
    
    /**
     * Format time for display (e.g., "3:30 PM")
     */
    fun formatTime(date: Date?): String {
        return formatDate(date, "h:mm a")
    }
    
    /**
     * Get the start of the current week (Monday at 00:00:00)
     */
    fun startOfWeek(): Date {
        val calendar = Calendar.getInstance()
        calendar.firstDayOfWeek = Calendar.MONDAY
        calendar.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Get the start of the current month (1st at 00:00:00)
     */
    fun startOfMonth(): Date {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Get the start date of the week containing the specified date
     */
    fun getWeekStartDate(date: Date): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.firstDayOfWeek = Calendar.MONDAY
        calendar.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Get the start date of the month containing the specified date
     */
    fun getMonthStartDate(date: Date): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Get the start of tomorrow (00:00:00)
     */
    fun startOfTomorrow(): Date {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }
    
    /**
     * Check if a date is today
     */
    fun isToday(date: Date?): Boolean {
        if (date == null) return false
        
        val today = Calendar.getInstance()
        val calendar = Calendar.getInstance()
        calendar.time = date
        
        return (today.get(Calendar.YEAR) == calendar.get(Calendar.YEAR) &&
                today.get(Calendar.DAY_OF_YEAR) == calendar.get(Calendar.DAY_OF_YEAR))
    }
    
    /**
     * Check if a date is overdue (before now)
     */
    fun isOverdue(date: Date?): Boolean {
        if (date == null) return false
        return date.before(Date())
    }
    
    /**
     * Get a human-readable relative date string (e.g. "Today", "Tomorrow", "Yesterday", "Next Monday")
     * Version for display purposes
     */
    @JvmStatic
    fun getRelativeDateString(date: Date?): String {
        if (date == null) return ""
        
        val today = Calendar.getInstance()
        val calendar = Calendar.getInstance()
        calendar.time = date
        
        // Check if today
        if (isToday(date)) {
            return "Today"
        }
        
        // Check if tomorrow
        val tomorrow = Calendar.getInstance()
        tomorrow.add(Calendar.DAY_OF_YEAR, 1)
        if (calendar.get(Calendar.YEAR) == tomorrow.get(Calendar.YEAR) &&
            calendar.get(Calendar.DAY_OF_YEAR) == tomorrow.get(Calendar.DAY_OF_YEAR)) {
            return "Tomorrow"
        }
        
        // Check if yesterday
        val yesterday = Calendar.getInstance()
        yesterday.add(Calendar.DAY_OF_YEAR, -1)
        if (calendar.get(Calendar.YEAR) == yesterday.get(Calendar.YEAR) &&
            calendar.get(Calendar.DAY_OF_YEAR) == yesterday.get(Calendar.DAY_OF_YEAR)) {
            return "Yesterday"
        }
        
        // If within the next 7 days
        val nextWeek = Calendar.getInstance()
        nextWeek.add(Calendar.DAY_OF_YEAR, 7)
        if (date.before(nextWeek.time) && date.after(today.time)) {
            val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
            return when (dayOfWeek) {
                Calendar.MONDAY -> "Monday"
                Calendar.TUESDAY -> "Tuesday"
                Calendar.WEDNESDAY -> "Wednesday"
                Calendar.THURSDAY -> "Thursday"
                Calendar.FRIDAY -> "Friday"
                Calendar.SATURDAY -> "Saturday"
                Calendar.SUNDAY -> "Sunday"
                else -> formatShortDate(date)
            }
        }
        
        // Default to short date format
        return formatShortDate(date)
    }
    
    /**
     * Calculate next occurrence date based on recurrence pattern
     */
    fun calculateNextOccurrence(
        currentDate: Date,
        recurrenceType: String,
        interval: Int = 1,
        daysOfWeek: List<Int>? = null,
        dayOfMonth: Int? = null
    ): Date {
        val calendar = Calendar.getInstance()
        calendar.time = currentDate
        
        when (recurrenceType.uppercase()) {
            "DAILY" -> {
                calendar.add(Calendar.DAY_OF_MONTH, interval)
            }
            "WEEKLY" -> {
                calendar.add(Calendar.WEEK_OF_YEAR, interval)
            }
            "MONTHLY" -> {
                if (dayOfMonth != null && dayOfMonth > 0) {
                    // Set to the specified day of month
                    calendar.add(Calendar.MONTH, interval)
                    val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                    calendar.set(Calendar.DAY_OF_MONTH, minOf(dayOfMonth, maxDay))
                } else {
                    // Just add months
                    calendar.add(Calendar.MONTH, interval)
                }
            }
        }
        
        return calendar.time
    }
    
    /**
     * Get a user-friendly relative date string (Today, Tomorrow, etc.)
     * Alternative implementation to avoid conflicts
     */
    @Deprecated("Use getRelativeDateString instead", ReplaceWith("getRelativeDateString(date)"))
    fun getFormattedRelativeDate(date: Date?): String {
        return getRelativeDateString(date)
    }
}
