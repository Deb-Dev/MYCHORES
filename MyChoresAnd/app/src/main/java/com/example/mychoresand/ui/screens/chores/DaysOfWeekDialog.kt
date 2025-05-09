/**
 * Helper class for extracting the days of week dialog composable
 * to avoid cluttering the main ChoreDetailScreen file.
 */
package com.example.mychoresand.ui.screens.chores

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Dialog for selecting days of the week for recurring chores
 */
@Composable
fun DaysOfWeekDialog(
    selectedDays: List<Int>,
    onDismissRequest: () -> Unit,
    onConfirm: (List<Int>) -> Unit
) {
    val TAG = "DaysOfWeekDialog"
    val tempSelectedDays = remember { mutableStateListOf<Int>().apply { addAll(selectedDays) } }
    
    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text("Select Days of Week") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                // Show a checkbox for each day of the week (0-6, Sunday-Saturday)
                for (dayIndex in 0..6) {
                    val dayName = getDayName(dayIndex)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = tempSelectedDays.contains(dayIndex),
                            onCheckedChange = { isChecked ->
                                android.util.Log.d(TAG, "Day $dayName toggled: $isChecked")
                                if (isChecked) {
                                    if (!tempSelectedDays.contains(dayIndex)) {
                                        tempSelectedDays.add(dayIndex)
                                    }
                                } else {
                                    tempSelectedDays.remove(dayIndex)
                                }
                            }
                        )
                        Text(text = dayName, modifier = Modifier.padding(start = 8.dp))
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    android.util.Log.d(TAG, "Confirming days selection: $tempSelectedDays")
                    onConfirm(tempSelectedDays.toList())
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismissRequest) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Get the name of a day from its index (0-6, Sunday-Saturday)
 */
fun getDayName(dayIndex: Int): String {
    // Create a map of day indexes to day names
    val dayNames = mapOf(
        0 to "Sunday",
        1 to "Monday",
        2 to "Tuesday",
        3 to "Wednesday",
        4 to "Thursday",
        5 to "Friday",
        6 to "Saturday"
    )
    
    // Return the day name or a default if not found
    return dayNames[dayIndex] ?: "Unknown Day"
}
