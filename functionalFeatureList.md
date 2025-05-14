## MyChores: Detailed Functional Feature List

**1. User Account Management & Authentication**

*   **1.1. User Registration (Sign Up):**
    *   Allow new users to create an account using an email address and password.
    *   Collect user's display name during registration.
    *   Automatically create a corresponding user profile in Firestore upon successful registration.
    *   Provide feedback on successful registration or reasons for failure (e.g., email already exists, weak password).
*   **1.2. User Login (Sign In):**
    *   Allow existing users to log in using their email and password.
    *   Provide feedback on successful login or reasons for failure (e.g., incorrect credentials, user not found).
    *   Maintain user session persistence (user remains logged in across app launches until explicitly logged out).
*   **1.3. User Logout (Sign Out):**
    *   Allow logged-in users to sign out of their account.
    *   Clear user session and return to the login/registration screen.
*   **1.4. Password Reset:**
    *   Allow users who have forgotten their password to request a password reset link via their registered email address.
*   **1.5. Profile Management (ProfileView - Placeholder):**
    *   (Future) Allow users to view and edit their profile information (name, photoURL).
    *   (Future) Allow users to update their email or password.
*   **1.6. Privacy Settings:**
    *   Allow users to control the visibility of their profile information.
    *   Allow users to control the visibility of their achievements.
    *   Allow users to control whether their activity is shared (e.g., on leaderboards).

**2. Household Management**

*   **2.1. Create Household:**
    *   Allow a logged-in user to create a new household.
    *   Require a name for the new household.
    *   Automatically set the creator as the household owner.
    *   Automatically add the creator as a member of the household.
    *   Generate a unique, shareable invite code for the household.
*   **2.2. Join Household:**
    *   Allow users to join an existing household by entering a valid invite code.
    *   Add the user to the household's member list upon successful joining.
    *   Provide feedback on success or failure (e.g., invalid invite code).
*   **2.3. View Household Details:**
    *   Display the name of the selected household.
    *   List all members of the current household (displaying their names/avatars).
*   **2.4. Invite Members:**
    *   Display the household's unique invite code for easy sharing.
*   **2.5. Leave Household:**
    *   Allow a member (who is not the sole owner) to leave a household.
    *   Remove the user from the household's member list.
    *   (Consideration: Logic for transferring ownership if the owner leaves or deleting the household if it becomes empty).
*   **2.6. Switch Between Households (Implicit):**
    *   If a user is a member of multiple households, allow them to select which household's chores and data they are currently viewing/managing.
*   **2.7. Household Onboarding:**
    *   For new users or users not yet part of any household, provide a clear onboarding flow to either create a new household or join an existing one.

**3. Chore Management**

*   **3.1. Create Chore (AddChoreView):**
    *   Allow users to create new chores within their selected household.
    *   Input fields for:
        *   Title (mandatory).
        *   Description (optional).
        *   Assignee (optional, select from household members).
        *   Due Date (optional, with a date picker; defaults to tomorrow).
        *   Point Value (default to 1, configurable).
        *   Recurrence (toggle for recurring chores).
*   **3.2. View Chore List (ChoresView, ChoreListView):**
    *   Display a list of chores for the currently selected household.
    *   Each chore in the list (`ChoreRowView`) should display key information:
        *   Title.
        *   Assigned user (if any).
        *   Due date (if any, with visual cues for overdue).
        *   Point value.
        *   Completion status (e.g., checkbox, visual indicator).
        *   Recurrence icon (if applicable).
*   **3.3. View Chore Details (ChoreDetailView):**
    *   Allow users to tap on a chore to see its full details.
    *   Display all chore properties (title, description, assignee, due date, points, creator, creation date, completion status, completion date, completer).
*   **3.4. Edit Chore:**
    *   (Future or via ChoreDetailView) Allow users (likely creator or assignee) to edit the properties of an existing chore.
*   **3.5. Delete Chore:**
    *   Allow users (likely creator or household admin) to delete a chore.
    *   Provide a confirmation prompt before deletion.
*   **3.6. Complete/Uncomplete Chore:**
    *   Allow assigned users (or any household member, depending on rules) to mark a chore as complete.
    *   Update the chore's status, `completedAt` date, and `completedByUserId`.
    *   Award points to the completing user.
    *   Trigger potential badge earning logic.
    *   Allow users to unmark a chore as complete (if rules permit), reverting points and completion status.
*   **3.7. Chore Filtering (FilterControlsView):**
    *   Allow users to filter the chore list based on criteria such as:
        *   All chores.
        *   Chores assigned to the current user.
        *   Unassigned chores.
        *   Completed chores.
        *   Overdue chores.
*   **3.8. Recurring Chores:**
    *   When creating a chore, allow users to specify recurrence patterns:
        *   Type: Daily, Weekly, Monthly.
        *   Interval (e.g., every 2 days, every 3 weeks).
        *   Specific days of the week (for weekly recurrence).
        *   Specific day of the month (for monthly recurrence).
        *   End date for recurrence (optional, otherwise indefinite).
    *   When a recurring chore is completed, automatically generate the next occurrence of the chore based on its recurrence rule and `nextOccurrenceDate`.
*   **3.9. Empty State Display:**
    *   When there are no chores matching the current filter or no chores in the household, display a user-friendly empty state message with an optional action (e.g., "Add your first chore!").

**4. Points & Gamification**

*   **4.1. Point Allocation:**
    *   Assign a point value to each chore.
    *   When a chore is marked as complete, automatically add the chore's point value to the `totalPoints`, `weeklyPoints`, and `monthlyPoints` of the user who completed it.
*   **4.2. Weekly Point Reset:**
    *   Automatically reset `weeklyPoints` for all users at the beginning of each week (e.g., Monday morning).
    *   Track `currentWeekStartDate` for each user.
*   **4.3. Monthly Point Reset:**
    *   Automatically reset `monthlyPoints` for all users at the beginning of each month.
    *   Track `currentMonthStartDate` for each user.

**5. Leaderboards (LeaderboardView)**

*   **5.1. View Leaderboards:**
    *   Display leaderboards for the current household.
*   **5.2. Time Period Selection:**
    *   Allow users to switch between viewing:
        *   Weekly Leaderboard (based on `weeklyPoints`).
        *   Monthly Leaderboard (based on `monthlyPoints`).
        *   (Future) All-Time Leaderboard (based on `totalPoints`).
*   **5.3. Leaderboard Display:**
    *   List users in descending order of their points for the selected period.
    *   Display user's name/avatar and their score.
*   **5.4. Empty State:**
    *   If no point data is available for the leaderboard, display an appropriate empty state message.
*   **5.5. Refresh Leaderboard:**
    *   Allow users to manually refresh the leaderboard data.

**6. Achievements & Badges (AchievementsView)**

*   **6.1. Predefined Badges:**
    *   The app includes a set of predefined badges with criteria for earning them (e.g., "Completed 1st chore," "Completed 10 chores").
*   **6.2. Earning Badges:**
    *   Automatically award badges to users when they meet the predefined criteria (e.g., based on `totalCompletedTasks` or other metrics).
    *   Store earned badge keys in the user's profile (`earnedBadges` array).
*   **6.3. View Achievements:**
    *   Allow users to view their achievements.
    *   Display:
        *   Badges they have earned.
        *   Badges they have not yet earned (potentially greyed out or with progress indicators).
*   **6.4. Badge Details (BadgeDetailView):**
    *   Allow users to tap on a badge to see its name, description, icon, and criteria for earning it.
*   **6.5. Badge Earned Notification/Toast:**
    *   Display a visual notification (e.g., a toast message) when a user earns a new badge.
*   **6.6. Stats Display:**
    *   Show relevant user statistics like "Total Tasks Completed."

**7. Notifications & Reminders**

*   **7.1. Notification Permission Request:**
    *   Prompt users to grant permission for push notifications at an appropriate time.
*   **7.2. Chore Due Date Reminders:**
    *   Schedule local notifications to remind users about chores that are due soon or overdue.
*   **7.3. (Future) Activity Notifications (via FCM):**
    *   Notify users about relevant household activity, such as:
        *   When a new chore is assigned to them.
        *   When a chore they created is completed by someone else.
        *   Updates on leaderboard positions (optional).
*   **7.4. FCM Token Management:**
    *   Register and store the user's FCM token for sending push notifications. Update it if it changes.

**8. UI/UX & General App Behavior**

*   **8.1. Loading States:**
    *   Display loading indicators (e.g., `ProgressView`, shimmer effects) when data is being fetched from the backend.
*   **8.2. Error Handling:**
    *   Display user-friendly error messages (e.g., via `ErrorAlertView` or `ToastManager`) when operations fail (e.g., network issues, validation errors).
*   **8.3. Toast Notifications:**
    *   Use toast messages for brief, non-intrusive feedback (e.g., "Chore added successfully," "Points earned!").
*   **8.4. Responsive UI:**
    *   Ensure the UI adapts well to different iOS device screen sizes.
*   **8.5. Consistent Theme:**
    *   Apply a consistent visual theme (colors, typography, dimensions) throughout the app as defined in Theme.swift.
*   **8.6. Animations:**
    *   Use subtle animations (`AnimatedView`) to enhance user experience and provide visual delight.
*   **8.7. Refresh Functionality:**
    *   Provide pull-to-refresh or manual refresh buttons for lists where data might change (e.g., Chores list, Leaderboard).
*   **8.8. Accessibility:**
    *   Ensure UI elements are accessible (e.g., proper labels for screen readers).
