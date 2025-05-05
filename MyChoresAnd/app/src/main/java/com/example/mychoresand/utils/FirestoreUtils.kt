package com.example.mychoresand.utils

import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Utility class for Firestore operations
 */
object FirestoreUtils {
    
    /**
     * Convert a DocumentSnapshot to an object of type T
     */
    inline fun <reified T : Any> DocumentSnapshot.toObject(): T? {
        return this.toObject(T::class.java)
    }
    
    /**
     * Get a document as a Flow that updates in real-time
     */
    fun <T> DocumentReference.getAsFlow(converter: (DocumentSnapshot) -> T?): Flow<T?> = callbackFlow {
        val listener = this@getAsFlow.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }
            
            try {
                val item = snapshot?.let(converter)
                trySend(item)
            } catch (e: Exception) {
                close(e)
                return@addSnapshotListener
            }
        }
        
        awaitClose { listener.remove() }
    }
    
    /**
     * Get a query as a Flow that updates in real-time
     */
    fun <T> Query.getAsFlow(converter: (DocumentSnapshot) -> T?): Flow<List<T>> = callbackFlow {
        val listener = this@getAsFlow.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }
            
            try {
                val items = snapshot?.documents?.mapNotNull(converter) ?: emptyList()
                trySend(items)
            } catch (e: Exception) {
                close(e)
                return@addSnapshotListener
            }
        }
        
        awaitClose { listener.remove() }
    }
    
    /**
     * Create or update a document with the given ID
     * @param collection Collection name
     * @param id Document ID (null or empty for new documents)
     * @param data Data to save (must be compatible with Firestore)
     * @return Document ID
     */
    suspend fun <T : Any> FirebaseFirestore.createOrUpdate(
        collection: String,
        id: String?,
        data: T
    ): String {
        return if (id.isNullOrEmpty()) {
            // Create new document
            val docRef = collection(collection).add(data).await()
            docRef.id
        } else {
            // Update existing document
            collection(collection).document(id).set(data, SetOptions.merge()).await()
            id
        }
    }
    
    /**
     * Get all documents from a collection that match a field value
     */
    suspend inline fun <reified T : Any> FirebaseFirestore.getWhere(
        collection: String,
        field: String,
        value: Any
    ): List<T> {
        val snapshot = collection(collection)
            .whereEqualTo(field, value)
            .get()
            .await()
        
        return snapshot.documents.mapNotNull { doc ->
            doc.toObject(T::class.java)?.apply {
                if (this is FirestoreModel) {
                    this.id = doc.id
                }
            }
        }
    }
    
    /**
     * Delete a document by ID
     */
    suspend fun FirebaseFirestore.deleteDocument(
        collection: String,
        id: String
    ): Boolean {
        return try {
            collection(collection).document(id).delete().await()
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Interface for models that can be stored in Firestore
     */
    interface FirestoreModel {
        var id: String?
    }
}
