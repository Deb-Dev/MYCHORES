<!-- filepath: /Users/debchow/Documents/coco/MyChores/SYSTEM_DESIGN.md -->
# MyChores System Design Document

## 1. System Overview

MyChores is a task management application designed for households to track and gamify chore completion. The app employs a points-based system, leaderboards, and achievements to encourage task completion through positive reinforcement and friendly competition.

### 1.1 Core Features

- User accounts and household management (Authentication via Firebase Auth)
- Chore creation, assignment, and tracking (Data stored in Firestore)
- Points system and leaderboards (Calculated from chore completion, stored in Firestore)
- Achievement badges (Based on user activity, definitions stored with app, user achievements in Firestore)
- Notifications and reminders (Using Firebase Cloud Messaging and UserNotifications framework)

### 1.2 Target Platform

iOS devices using SwiftUI and following MVVM architecture.

## 2. Architecture

The application follows the Model-View-ViewModel (MVVM) architectural pattern, with a distinct Service layer for business logic and backend communication.

```
┌─────────────┐     ┌───────────────┐     ┌──────────────┐     ┌─────────────┐     ┌────────────────┐
│     View    │◄────┤   ViewModel   │◄────┤    Service   │◄────┤    Model    │     │    Firebase    │
│  (SwiftUI)  │     │  (Observable) │     │   (Logic &   │     │   (Data     │     │   (Backend)    │
│ (UI Layer)  │     │ (Presentation │     │  API Calls)  │     │ Structures) │     │ (Auth, DB,    │
│             │     │    Logic)     │     │              │     │             │     │ Notifications) │
└─────────────┘     └───────────────┘     └──────────────┘     └─────────────┘     └────────────────┘
        ▲                   │                     │                     │                   │
        │                   │                     │                     │                   │
        └───────────────────┴─────────────────────┴─────────────────────┴───────────────────┘
              User Interaction          Data Binding &         Business Logic      Data Definition   Persistence &
                                        Action Handling        & API Interface                       Cloud Services
```

### 2.1 Architectural Components

#### 2.1.1 Models

Data structures that represent the core entities of the application. These are typically `struct`s conforming to `Codable` for easy serialization/deserialization with Firestore.

Key Models (as per UML):
-   `User`: Represents a user with personal details (name, email, photoURL), household memberships (`householdIds`), points (total, weekly, monthly), earned badges (`earnedBadges`), FCM token, and privacy settings.
-   `Household`: Represents a group of users (`memberUserIds`) sharing chores, with a name, owner (`ownerUserId`), and a unique `inviteCode`.
-   `Chore`: Represents a task with properties like title, description, `householdId`, `assignedToUserId`, `createdByUserId`, `dueDate`, completion status (`isCompleted`, `completedAt`, `completedByUserId`), `pointValue`, and recurrence details (`isRecurring`, `recurrenceType`, `nextOccurrenceDate`).
-   `Badge`: Represents an achievement (`badgeKey`, name, description, icon, color) that users can earn, often tied to `requiredTaskCount`.
-   `RecurrenceType`: An `enum` defining how chores can recur (e.g., `daily`, `weekly`, `monthly`).

#### 2.1.2 Views (SwiftUI)

The UI layer of the application, responsible for presenting data to the user and capturing user input. Views are typically lightweight and delegate business logic to ViewModels.

Key Views (as per UML and project structure):
-   `MyChoresApp`: The main application entry point, sets up the `AppDelegate` and initial `AuthViewModel`.
-   `AppDelegate`: Handles app lifecycle events, including Firebase initialization and push notification setup.
-   `MainView`: Root view that observes `AuthViewModel` to switch between authentication flow (`AuthView` - not explicitly in UML but implied) and the main app content (`HomeView`).
-   `HomeView`: Main container view after authentication, likely hosting `ChoresView`, `HouseholdView`, `LeaderboardView`, `AchievementsView`, and `ProfileView`.
-   `ChoresView`: Displays and manages lists of chores, allows adding new chores.
    -   `ChoreListView`: A dedicated list for displaying chores.
    -   `ChoreRowView`: Represents a single chore in a list.
    -   `AddChoreView`: Form for creating new chores.
    -   `ChoreDetailView`: Shows details of a specific chore.
    -   `FilterControlsView`: UI for filtering chores.
-   `HouseholdView`: Manages household settings, members, and joining/creating households.
    -   `InviteCodeView`: Displays household invite code.
    -   `CreateHouseholdView`, `JoinHouseholdView`: Forms for household management.
-   `LeaderboardView`: Displays user rankings based on points.
    -   `UserAvatarView`: Component for displaying user avatars.
-   `AchievementsView`: Displays user's earned and unearned badges.
    -   `BadgeCardView`, `BadgeDetailView`: Components for displaying badge information.
-   `ProfileView`: (Placeholder) For user profile management.
-   Reusable Components: `EmptyStateView`, `CardView`, `ErrorAlertView`, `ToastManager`, `AnimatedView`, `ShimmeringView`.

#### 2.1.3 ViewModels (ObservableObjects)

Act as intermediaries between Views and Services. They fetch and prepare data from Services for display in Views, and they handle user actions from Views by invoking Service methods. ViewModels are `ObservableObject`s, allowing Views to subscribe to their changes.

Key ViewModels (as per UML):
-   `AuthViewModel`: Manages authentication state (`authState`, `currentUser`), handles sign-in, sign-up, sign-out, and password reset logic by interacting with `AuthService`.
-   `ChoreViewModel`: Manages chore data (`chores`, `selectedChore`) for a specific household, handles fetching, adding, updating, completing, and deleting chores via `ChoreService`.
-   `HouseholdViewModel`: Manages household data (`households`, `selectedHousehold`, `householdMembers`), handles fetching household details, creating/joining/leaving households, and inviting members through `HouseholdService` and `UserService`.
-   `LeaderboardViewModel`: Fetches and prepares leaderboard data (`weeklyLeaderboard`, `monthlyLeaderboard`) from `UserService` for a specific household.
-   `AchievementsViewModel`: Fetches and manages user achievement data (`allBadges`, `earnedBadges`, `unearnedBadges`) via `UserService`.

#### 2.1.4 Services

Encapsulate business logic, data manipulation, and communication with external systems like Firebase. They provide a clean API for ViewModels to interact with. Services are typically singletons or injected dependencies.

Key Services (Protocols & Implementations, as per UML):
-   `AuthServiceProtocol` / `AuthService`: Handles all authentication-related operations with Firebase Auth (sign-in, sign-up, sign-out, password reset, current user state). Also coordinates with `UserService` to create/fetch user profiles in Firestore upon authentication.
-   `UserServiceProtocol` / `UserService`: Manages user data in Firestore (creating, fetching, updating user profiles, including points and badges).
-   `ChoreServiceProtocol` / `ChoreService`: Manages chore data in Firestore (creating, fetching, updating, deleting chores for households or users).
-   `HouseholdServiceProtocol` / `HouseholdService`: Manages household data in Firestore (creating, fetching, updating households, managing members, handling invite codes).
-   `NotificationServiceProtocol` / `NotificationService`: Handles requesting notification permissions, scheduling local chore reminders, and potentially interacting with Firebase Cloud Messaging for remote notifications.

### 2.2 Utilities

-   `Theme`: Defines the app's color palette, typography, and dimensions for consistent styling.
-   `DateExtensions`: Provides convenience methods for date manipulation.

## 3. Data Flow Examples

### 3.1 User Login

1.  **View (`AuthView` or similar):** User enters credentials and taps "Login".
2.  **ViewModel (`AuthViewModel`):** `signIn(email:, password:)` method is called. ViewModel updates `isLoading` state.
3.  **Service (`AuthService`):** `signIn` method makes an asynchronous call to Firebase Authentication.
    *   On success, Firebase Auth returns a user object. `AuthService` then fetches/creates the corresponding user profile from Firestore via `UserService`.
    *   `AuthService` updates its `@Published` properties (`currentUser`, `authState`).
4.  **ViewModel (`AuthViewModel`):** Subscribed to `AuthService` changes, its `@Published` properties (`currentUser`, `authState`) update automatically. `isLoading` is set to false.
5.  **View (`MainView`):** Observes `AuthViewModel`. The change in `authState` triggers a UI update, navigating the user to `HomeView`.

### 3.2 Fetching Chores

1.  **View (`ChoresView`):** Appears on screen or user initiates a refresh.
2.  **ViewModel (`ChoreViewModel`):** `fetchChores()` method is called (e.g., in `onAppear` or on refresh action). ViewModel sets `isLoading` to true.
3.  **Service (`ChoreService`):** `fetchChores(forHouseholdId:)` method queries Firestore for chores belonging to the current household.
4.  **Service (`ChoreService`):** Receives chore data, decodes it into `[Chore]` models.
5.  **ViewModel (`ChoreViewModel`):** Receives the `[Chore]` array from the service, updates its `@Published var chores` property. `isLoading` is set to false.
6.  **View (`ChoresView` / `ChoreListView`):** Observes `ChoreViewModel`. The change to `chores` automatically updates the list displayed to the user.

## 4. Firebase Integration

MyChores leverages Firebase for its backend-as-a-service capabilities:

-   **Firebase Authentication:** Handles user sign-up, sign-in, password reset, and secure user session management.
-   **Firebase Firestore:** A NoSQL document database used to store all application data, including:
    -   `users`: Collection for user profiles.
    -   `households`: Collection for household groups.
    -   `chores`: Collection for tasks, often sub-collections of households or directly queried by `householdId`.
    -   (Data modeling will ensure efficient queries, e.g., using `householdId` on chores for easy fetching).
-   **Firebase Cloud Messaging (FCM):** Used for sending push notifications and reminders to users about due chores or other important events. The `AppDelegate` and `NotificationService` manage FCM token registration and message handling.
-   **Firebase Storage (Optional but common):** Could be used if profile pictures or other user-generated content storage is required. (Not explicitly detailed in current UML but a common extension).
-   **Firestore Security Rules:** Defined in `firestore.rules` to protect data integrity and ensure users can only access and modify data they are authorized to. These rules are crucial for production readiness.

## 5. Key Design Considerations & Future Enhancements

-   **Offline Support:** Currently, the app relies on an active internet connection. Future enhancements could include Firestore offline caching for a better user experience in low-connectivity scenarios.
-   **Scalability:** Firestore is designed for scalability. Data modeling choices (e.g., avoiding deeply nested data that requires complex queries) are important.
-   **Error Handling:** Robust error handling is implemented across ViewModel and Service layers, with errors propagated to the View for user feedback (e.g., via `ErrorAlertView` or `ToastManager`).
-   **Testing:** Unit tests for ViewModels and Services (using mock services like `MockAuthService`, `MockUserService`) are in place. UI tests ensure key user flows work as expected.
-   **Accessibility:** SwiftUI provides good accessibility features. Adherence to accessibility best practices is important.
-   **Real-time Updates:** Firestore provides real-time listeners. These are used (or can be easily integrated) to update UI instantly when data changes in the backend (e.g., a new chore added by another household member).
-   **Internationalization (i18n) / Localization (l10n):** For broader reach, string localization would be a future step.

## 6. Deployment

-   iOS app deployed via Apple App Store.
-   Firestore rules deployed using Firebase CLI (`firebase deploy --only firestore:rules`).

This document provides a high-level overview of the MyChores application's system design. It should be updated as the application evolves.
