package com.example.mychoresand.utils

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Utility class for date-related operations
 */
object DateUtils {
    /**
     * Format date in a similar way to iOS implementation
     * Shows relative dates like "Today", "Tomorrow", or day of week for dates within a week
     */
    fun formatRelativeDate(date: Date): String {
        val now = Date()
        val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
        
        // Create calendars for comparison
        val dateCalendar = Calendar.getInstance()
        dateCalendar.time = date
        
        val todayCalendar = Calendar.getInstance()
        todayCalendar.time = now
        
        // Check if today
        if (dateCalendar.get(Calendar.YEAR) == todayCalendar.get(Calendar.YEAR) &&
            dateCalendar.get(Calendar.DAY_OF_YEAR) == todayCalendar.get(Calendar.DAY_OF_YEAR)) {
            return "Today, ${timeFormat.format(date)}"
        }
        
        // Check if tomorrow
        val tomorrowCalendar = Calendar.getInstance()
        tomorrowCalendar.time = now
        tomorrowCalendar.add(Calendar.DAY_OF_YEAR, 1)
        
        if (dateCalendar.get(Calendar.YEAR) == tomorrowCalendar.get(Calendar.YEAR) &&
            dateCalendar.get(Calendar.DAY_OF_YEAR) == tomorrowCalendar.get(Calendar.DAY_OF_YEAR)) {
            return "Tomorrow, ${timeFormat.format(date)}"
        }
        
        // Within the next week
        val weekCalendar = Calendar.getInstance()
        weekCalendar.time = now
        weekCalendar.add(Calendar.DAY_OF_YEAR, 7)
        
        if (date.before(weekCalendar.time)) {
            val dayFormat = SimpleDateFormat("EEEE", Locale.getDefault())
            return dayFormat.format(date)
        }
        
        // Otherwise, standard date format
        val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
        return dateFormat.format(date)
    }

    /**
     * Check if two dates are on the same day
     */
    fun isSameDay(date1: Date, date2: Date): Boolean {
        val cal1 = Calendar.getInstance()
        cal1.time = date1
        val cal2 = Calendar.getInstance()
        cal2.time = date2
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
               cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }
}
