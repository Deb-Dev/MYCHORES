package com.example.mychoresand.utils

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.mychoresand.R
import com.example.mychoresand.models.Chore
import com.example.mychoresand.models.User
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * RecyclerView adapter for displaying chores in a traditional Android UI (non-Compose)
 * This can be used as an alternative to Jetpack Compose if needed
 */
class ChoreAdapter(
    private val context: Context,
    private val onChoreClick: (Chore) -> Unit
) : ListAdapter<ChoreAdapter.ChoreWithAssignee, ChoreAdapter.ChoreViewHolder>(DIFF_CALLBACK) {
    
    /**
     * Data class that combines a chore with its assignee for display
     */
    data class ChoreWithAssignee(
        val chore: Chore,
        val assignee: User?
    )
    
    companion object {
        private val DIFF_CALLBACK = object : DiffUtil.ItemCallback<ChoreWithAssignee>() {
            override fun areItemsTheSame(oldItem: ChoreWithAssignee, newItem: ChoreWithAssignee): Boolean {
                return oldItem.chore.id == newItem.chore.id
            }
            
            override fun areContentsTheSame(oldItem: ChoreWithAssignee, newItem: ChoreWithAssignee): Boolean {
                return oldItem.chore == newItem.chore && oldItem.assignee?.id == newItem.assignee?.id
            }
        }
    }
    
    /**
     * ViewHolder for the chore item
     */
    inner class ChoreViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val titleTextView: TextView = itemView.findViewById(R.id.chore_title)
        private val descriptionTextView: TextView = itemView.findViewById(R.id.chore_description)
        private val assigneeTextView: TextView = itemView.findViewById(R.id.chore_assignee)
        private val pointsTextView: TextView = itemView.findViewById(R.id.chore_points)
        private val dueDateTextView: TextView = itemView.findViewById(R.id.chore_due_date)
        private val statusImageView: ImageView = itemView.findViewById(R.id.chore_status_icon)
        
        init {
            itemView.setOnClickListener {
                val position = adapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    onChoreClick(getItem(position).chore)
                }
            }
        }
        
        fun bind(choreWithAssignee: ChoreWithAssignee) {
            val chore = choreWithAssignee.chore
            val assignee = choreWithAssignee.assignee
            
            titleTextView.text = chore.title
            
            // Set description if available
            if (chore.description.isNotEmpty()) {
                descriptionTextView.visibility = View.VISIBLE
                descriptionTextView.text = chore.description
            } else {
                descriptionTextView.visibility = View.GONE
            }
            
            // Set assignee
            assigneeTextView.text = assignee?.displayName ?: "Unassigned"
            
            // Set points
            pointsTextView.text = "${chore.pointValue} ${if (chore.pointValue == 1) "pt" else "pts"}"
            
            // Set due date
            chore.dueDate?.let {
                dueDateTextView.visibility = View.VISIBLE
                dueDateTextView.text = DateTimeUtils.getRelativeDateString(it)
                
                
                // Check if overdue
                if (DateTimeUtils.isOverdue(it) && !chore.isCompleted) {
                    dueDateTextView.setTextColor(ContextCompat.getColor(context, android.R.color.holo_red_light))
                } else {
                    dueDateTextView.setTextColor(ContextCompat.getColor(context, android.R.color.darker_gray))
                }
            } ?: run {
                dueDateTextView.visibility = View.GONE
            }
            
            // Set status icon
            if (chore.isCompleted) {
                statusImageView.visibility = View.VISIBLE
                statusImageView.setImageResource(R.drawable.ic_check_circle)
                statusImageView.setColorFilter(ContextCompat.getColor(context, android.R.color.holo_green_dark))
            } else if (chore.dueDate != null && DateTimeUtils.isOverdue(chore.dueDate)) {
                statusImageView.visibility = View.VISIBLE
                statusImageView.setImageResource(R.drawable.ic_error)
                statusImageView.setColorFilter(ContextCompat.getColor(context, android.R.color.holo_red_light))
            } else {
                statusImageView.visibility = View.GONE
            }
        }
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ChoreViewHolder {
        val itemView = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_chore, parent, false)
        return ChoreViewHolder(itemView)
    }
    
    override fun onBindViewHolder(holder: ChoreViewHolder, position: Int) {
        holder.bind(getItem(position))
    }
    
    /**
     * Update the list of chores with their assignees
     */
    fun submitChoresWithAssignees(chores: List<Chore>, users: Map<String, User>) {
        val choresWithAssignees = chores.map { chore ->
            ChoreWithAssignee(
                chore = chore,
                assignee = chore.assignedToUserId?.let { users[it] }
            )
        }
        submitList(choresWithAssignees)
    }
}
