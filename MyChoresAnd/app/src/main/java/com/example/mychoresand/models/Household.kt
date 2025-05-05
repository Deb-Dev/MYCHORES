package com.example.mychoresand.models

import com.google.firebase.firestore.DocumentId
import java.util.Date

/**
 * Represents a household group of users sharing chores
 */
data class Household(
    @DocumentId var id: String? = null,
    var name: String = "",
    var ownerUserId: String = "",
    var memberUserIds: List<String> = emptyList(),
    var inviteCode: String = "",
    var createdAt: Date = Date()
) {
    companion object {
        // Sample household for preview and testing
        val sample = Household(
            id = "sample_household_id",
            name = "Smith Family",
            ownerUserId = "sample_user_id",
            memberUserIds = listOf("sample_user_id", "sample_user_id_2"),
            inviteCode = "SMITH123",
            createdAt = Date()
        )
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Household
        // Two households are considered equal if they have the same ID
        return id == other.id
    }

    override fun hashCode(): Int {
        return id?.hashCode() ?: 0
    }
}
