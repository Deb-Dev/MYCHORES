package com.example.mychoresand.models

import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.Exclude
import java.util.Date

/**
 * Represents a household group of users sharing chores
 */
data class Household(
    @DocumentId @get:Exclude var documentId: String? = null,
    var id: String? = null,
    var name: String = "",
    var description: String = "",
    var ownerUserId: String = "",
    var memberUserIds: List<String> = emptyList(),
    var inviteCode: String = "",
    var createdAt: Date = Date()
) {
    companion object {
        // Sample household for preview and testing
        val sample = Household(
            documentId = "sample_household_id",
            id = "sample_household_id",
            name = "Smith Family",
            description = "Family household for managing chores",
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
        // First check the id field, then fallback to documentId
        return if (id != null && other.id != null) {
            id == other.id
        } else {
            documentId == other.documentId
        }
    }

    override fun hashCode(): Int {
        // Use id if available, otherwise documentId
        return id?.hashCode() ?: (documentId?.hashCode() ?: 0)
    }
}
