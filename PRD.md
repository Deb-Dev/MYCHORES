Feature Requirements


1 User Accounts & Household Setup
	•	Authentication: Users create an account (using Firebase Authentication) with email/password (or sign in with Apple, etc. – email/password for MVP). This allows individual tracking of points and tasks.
	•	Household Group: Upon first login, a user can create a new household group or join an existing one (via invite link or code). All task and competition data is private to that household group – only members can view/participate.
	•	Member Profiles: Users have a profile with a display name (e.g., their first name or nickname) and an avatar (optional for MVP, could be a default icon). Display names will be used in task assignments and leaderboards.
	•	Group Management: The creator of a household can invite others (MVP: share an invite code or link manually). There is no public discovery of groups – joining is by invitation only. For MVP, minimal admin features: any member can add tasks; removing members or transferring ownership is out-of-scope (assuming trust among initial group).

2 Task Creation & Assignment

Users can create chores (tasks) and assign them to themselves or another member of the household:
	•	Task Attributes: Each task has a title (required), an optional description (details of the chore), a due date/time (optional), and an assignee (one household member responsible). Optionally, a point value can be set per task (if not set, a default value like 1 point is used for all tasks in MVP).
	•	Recurrence Options: The creator can mark a task as recurring with a fixed interval. MVP will support basic recurrence such as daily or weekly repeats (e.g., a task due every week on Monday). When a recurring task is completed, the app should automatically schedule the next occurrence of that task for the next interval. Implementation detail: the system will either duplicate the task for the next due date or reset its status/date; this ensures recurring chores continuously reappear without manual re-entry.
	•	Task List View: All household tasks are visible in a shared list or dashboard. Users can filter or view: “Pending” tasks (incomplete, sorted by upcoming due date) and “Completed” tasks (for reference/history). By default, the main view shows pending tasks.
	•	Assignment & Visibility: Each task clearly displays its assignee and due date. This way, everyone knows who is responsible for each chore. Unassigned tasks (if allowed) would be visible to all for anyone to take, but MVP will assume each task is assigned to someone for clarity.
	•	Edit & Delete: The task creator (or assignee, in MVP any household member for simplicity) can edit a task’s details or delete the task if it’s no longer needed. Edits should update for all users in real-time. Deleting a task removes it from the list (we won’t retain deleted tasks in history for MVP).
	•	Completion Marking: The assigned user (or any member, depending on group norms – MVP assumption: assignee marks it) can mark a task as “Completed” when done. Marking complete should:
	•	Instantly award the configured points to the completer’s score.
	•	Move the task to a “completed” state (and off the active list).
	•	If the task was recurring, trigger the creation/scheduling of the next instance (next due date).
	•	Overdue Tasks: If a task passes its due date without completion, it is flagged as overdue (e.g., highlighted in red or shown in an “Overdue” section). Overdue tasks remain available to complete for full points (no automatic point reduction in MVP). The intent is to remind users but not to penalize in this version.

3 Points System for Task Completion

A core gamification element is a points system that rewards users for completing tasks:
	•	Point Allocation: Each task completion grants a certain number of points to the user who completed it. By default, all tasks could be equal (e.g., 1 point each) or tasks can have custom point values set at creation (MVP supports at least a simple custom value). This allows weighting chores by effort (e.g., “cleaning the garage” could be 5 points, whereas “taking out trash” might be 1 point).
	•	Tracking Points: The app maintains a running total of points for each user in the household. Every time a task is marked completed, the system adds the task’s points to that user’s total. Points are stored in the database and update in real-time for all members.
	•	Visibility: Users can view their own points and others’ points via the leaderboard (see 3.4). Points serve as the basis for rankings and earning badges.
	•	Points History (Backend): Each completed task record logs who completed it and how many points were earned (for potential future features like detailed history, though not necessarily exposed in MVP UI beyond the leaderboard and badges).
	•	No Point Deductions in MVP: There’s no concept of losing points in MVP – only positive reinforcement. (Negative points or penalties for overdue tasks are out-of-scope to keep the system encouraging.)

4 Leaderboard (Weekly & Monthly Rankings)

To spark friendly competition, the app includes a leaderboard that ranks household members by points:
	•	Leaderboard Screen: Shows a ranked list of all household members with their point totals. The UI should highlight the top scorer and allow users to toggle between a weekly view and a monthly view of the competition.
	•	Weekly Leaderboard: Ranks users by the points they have earned in the current week. MVP defines a “week” as Monday through Sunday (configurable in future). The weekly tally resets at the start of each week (or is calculated for just the current week’s tasks). For example, on Monday it will start fresh at 0 for everyone. (The system will still retain total points historically, but the weekly view is just for recent competition.)
	•	Monthly Leaderboard: Similarly, ranks users by points earned in the current calendar month, resetting on the 1st of each month.
	•	All-Time Total (Optional): MVP focuses on weekly/monthly, but we may also display each user’s all-time points somewhere (perhaps on their profile or below their name). The main leaderboard views, however, are time-bounded to encourage regular participation.
	•	Display Details: Each entry shows the member’s name, avatar (if applicable), and points for that period. The top user might be visually emphasized (e.g., a trophy or crown icon for fun).
	•	Real-time Update: The leaderboard should update in real-time as tasks are completed. If one user marks a chore done, everyone else’s leaderboard view reflects the new point totals immediately (leveraging Firestore’s real-time data sync).
	•	Tie-breaking: If two users have the same points, they can share the rank (or the order can be by whoever reached it first – MVP can just sort by user name as secondary sort to keep order consistent, but we won’t complicate tie-breaking rules).
	•	No External Sharing: The leaderboard is visible only within the household group. There is no public or cross-household leaderboard in the MVP.

5 Badge Achievements System

To reward milestones and encourage continued participation, the app will award badges (achievements) for certain accomplishments:
	•	Badge Criteria (MVP Examples):
	•	Task Streak: “Completed 10 Tasks” – Earned when a user has completed 10 chores in total.
	•	Task Master: “Completed 50 Tasks” – Earned at 50 total completions (and perhaps more at higher numbers in future).
	•	First Task: “First Chore Done” – Earned when a user completes their first task (to onboard new users with a positive reward).
	•	(We keep the badge list small for MVP – primarily based on number of tasks completed. More complex badges like “completed all tasks this week” or “completed a task every day for a week” can be added later.)
	•	Earning Badges: The app checks a user’s actions against badge criteria. When a condition is met (e.g., user’s completed tasks count reaches 10), the corresponding badge is unlocked for that user. This check can happen immediately upon task completion (so the feedback is instant).
	•	Notification of Achievement: When a user earns a badge, they should be notified with a congratulatory message or in-app alert. For example, after marking the 10th task complete, they might see a popup: “🏆 Congratulations, you earned the 10 Tasks Completed badge!”. (Push notification can also be sent for badges, but in-app is primary since it happens while using the app.)
	•	Badge Display: Users can view the badges they’ve earned (and possibly those yet to earn). MVP will include a simple “Achievements” screen or section on the user’s profile listing badges. Each badge has an icon and title; earned badges are colored/enabled, whereas future badges could be greyed out or hidden until achieved (MVP could show just earned ones for simplicity).
	•	Basic Badge Icons: Use a set of simple, predesigned icons (e.g., a star or medal for 10 tasks, etc.). Custom badge design or large libraries of badges are not needed in MVP; just a few basic ones to illustrate the system.
	•	No Complex Levels: Aside from badges, we won’t have an XP or leveling system in MVP. Badges are one-time achievements, and points/leaderboard drive the competition loop.

6 Reminders & Push Notifications

Timely reminders will help users remember to do chores, leveraging iOS notifications:
	•	Due Date Reminders: If a task has a due date/time, the app sends a reminder notification to the assignee shortly before and/or at the due time. MVP will implement a single reminder at the due time (or perhaps a default lead time like 1 hour before). For example, if a task is due today at 6:00 PM, the assignee might get a push notification at 6:00 PM: “Reminder: Chore ‘Take out trash’ is due now.”
	•	Device Push Notifications: Use Firebase Cloud Messaging (FCM) for push delivery. When a reminder is triggered, an FCM push is sent to the relevant user’s device. FCM provides a reliable, battery-efficient delivery channel for notifications on iOS ￼. Users need to grant notification permission on install to receive these alerts.
	•	Task Assignment Alert (Future Consideration): In MVP, notifications primarily cover due reminders. (We may later add a notification when someone assigns you a new task, but that is optional and can be added if time permits. MVP scope can exclude it to focus on due reminders.)
	•	Recurring Task Reminders: For tasks that repeat, each occurrence should generate its own reminder. The system will schedule a new notification each time a recurring task’s next due date is set.
	•	Implementation Details: The app will register for push notifications and store each user’s device token (via Firebase). We’ll use a Cloud Function or scheduled job to trigger reminders at the right time. For example, a backend function could periodically check for tasks due soon and send notifications accordingly ￼. This ensures reminders go out even if the app isn’t open. (Alternatively or additionally, local notifications can be scheduled on the device when a task is created/assigned. MVP will likely rely on the backend approach for accuracy, as users might create tasks from different devices.)
	•	In-App Reminders: Overdue tasks or tasks due soon can also be highlighted within the app UI (e.g., a “Due soon” section), but the primary reminder mechanism is the push notification to bring users back into the app.
	•	Notification Settings: MVP will have notifications on by default when a user agrees to notifications. There won’t be a complex settings UI in-app for customizing reminder times or turning off specific notifications (beyond the global iOS notification settings). If a user wants to disable them, they can do so via iOS settings for the app.