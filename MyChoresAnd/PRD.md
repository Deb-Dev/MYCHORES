Here’s the tailored PRD for the MVP version of your chore-sharing app, rewritten specifically for Android development:

⸻

Product Requirements Document (PRD) – Android MVP

⸻

1. User Accounts & Household Setup
	•	Authentication: Use Firebase Authentication with email/password (MVP) or sign in with Google (for Android convenience). Handles unique user identity.
	•	Household Group:
	•	On first login, a user can either:
	•	Create a new household (generates invite code/link).
	•	Join an existing household using a shared invite code/link.
	•	Member Profiles:
	•	Each user sets a display name.
	•	Optional avatar (use placeholder drawable for MVP).
	•	Group Management:
	•	No public search or discovery.
	•	Any member can add tasks.
	•	No remove/kick/admin roles in MVP.

⸻

2. Task Creation & Assignment
	•	Attributes:
	•	Title (mandatory), description (optional), due date/time (optional), assignee (required), point value (optional, default = 1).
	•	Recurrence:
	•	Support basic recurrence: daily, weekly.
	•	Automatically reschedule task on completion.
	•	Use WorkManager or backend logic to create next instance.
	•	Task List View:
	•	Shared view showing all household tasks.
	•	Tabs/filters for:
	•	Pending
	•	Completed
	•	Overdue (highlighted in red).
	•	Editing/Deleting:
	•	Anyone can edit/delete (MVP simplicity).
	•	Use real-time Firestore listeners for sync.
	•	Completion Logic:
	•	Assignee marks task complete.
	•	Points awarded instantly.
	•	Task marked as complete and removed from active view.
	•	If recurring, next instance scheduled.

⸻

3. Points System
	•	Awarding Points:
	•	Each completed task grants points to user.
	•	Default = 1 point unless overridden.
	•	Tracking:
	•	Total points per user maintained in Firestore.
	•	Real-time sync for visibility.
	•	History:
	•	Store record of completed tasks with timestamp and user ID.
	•	No UI history view for MVP.

⸻

4. Leaderboard
	•	Views:
	•	Weekly (Mon–Sun)
	•	Monthly (calendar month)
	•	(Optional) All-time view in user profile.
	•	UI:
	•	RecyclerView showing user name, avatar, and points.
	•	Highlight top scorer (e.g., gold trophy icon).
	•	Sorting:
	•	Primary: points
	•	Secondary: user name (tie-break)
	•	Sync:
	•	Real-time update via Firestore listeners.

⸻

5. Badge System
	•	Trigger Criteria:
	•	1st Task: “First Chore Done”
	•	10 Tasks: “10 Tasks Completed”
	•	50 Tasks: “Task Master”
	•	Notification:
	•	In-app toast/snackbar or dialog congratulating user.
	•	Firebase Cloud Messaging (optional).
	•	UI:
	•	Badge screen showing unlocked badges (colored) and future ones (greyed out).
	•	Simple vector drawable icons (use Material Icons).

⸻

6. Reminders & Push Notifications
	•	Reminder Logic:
	•	Reminder sent at due time (or default 1hr before).
	•	Applies to each recurrence.
	•	Push Implementation:
	•	Firebase Cloud Messaging (FCM).
	•	Device token registered on login and stored in Firestore.
	•	Backend Scheduler:
	•	Firebase Cloud Function checks tasks due within 15 mins and sends notifications.
	•	Alternatively, use WorkManager for device-local scheduling, if app was used to create the task.
	•	Overdue/Upcoming UI:
	•	Highlight upcoming and overdue tasks in UI.
	•	Settings: Notification settings and standdard options

⸻

Tech Stack – Android MVP
	•	Language: Kotlin
	•	Architecture: MVVM
	•	UI: Jetpack Compose
	•	Database: Firebase Firestore (real-time sync)
	•	Authentication: Firebase Auth (email/password, Google Sign-In)
	•	Notifications: Firebase Cloud Messaging
	•	Task Scheduling: WorkManager (client), Cloud Functions (server)
	•	Dependency Injection: Hilt (optional but recommended)
	•	Image Loading: Coil
	•	State Management: LiveData / StateFlow

⸻

