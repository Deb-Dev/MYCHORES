The primary classes used in the MyChores iOS app, along with a short description of their purpose:

### Models

*   **`User`**: Represents a user of the application, storing profile information, household associations, points, and badges.
*   **`Chore`**: Represents a task to be done, including its title, description, assigned user, due date, completion status, and point value.
*   **`Household`**: Represents a group of users (e.g., a family or roommates) who share chores. It includes a name, invite code, and member list.
*   **`Badge`**: Represents an achievement or recognition a user can earn, typically based on points or completed chores.
*   **`UserPrivacySettings`**: Encapsulates a user's preferences regarding the visibility of their profile, achievements, and activity.

### Services

*   **`AuthService`**: Manages user authentication processes, including sign-up, sign-in, sign-out, and tracking the current authentication state with Firebase Authentication.
*   **`ChoreService`**: Handles all data operations related to chores, such as creating, reading, updating, deleting, and completing chores in Firestore.
*   **`HouseholdService`**: Manages household-related data operations, including creating households, joining/leaving households, and fetching household details and members from Firestore.
*   **`UserService`**: Responsible for managing user data in Firestore, such as creating new user records, updating user profiles, and fetching user information.

### ViewModels

*   **`AuthViewModel`**: Acts as an intermediary between authentication-related views and the `AuthService`. It holds the authentication state and user data for the UI.
*   **`HouseholdViewModel`**: Manages the state and logic for views related to households. It interacts with `HouseholdService` and `UserService` to fetch and present household data and member information.

### Views (Key Examples)

*   **`MyChoresApp`**: The main entry point of the SwiftUI application, setting up the initial environment and view hierarchy.
*   **`MainView`**: A container view that likely handles the primary navigation structure, switching between authenticated and unauthenticated states.
*   **`HomeView`**: The main screen displayed after login, typically showing a list of chores, user's progress, and navigation to other sections.
*   **`AddChoreView`**: A view used for creating new chores, allowing users to input chore details and assign them.
*   **`ChoreDetailView`**: A view that displays the detailed information of a specific chore and allows actions like marking it complete or deleting it.
*   **`HouseholdView`**: A view for displaying and managing household information, such as members and settings.
*   **`ProfileView`**: A view where users can see and edit their profile information and settings.
*   **`EmptyStateView`**: A reusable SwiftUI view to display when there is no data to show (e.g., no chores, no households).

### Others

*   **`AppDelegate`**: The application delegate, responsible for handling app lifecycle events, and setting up services like Firebase and push notifications.
*   **`Theme`**: A utility struct or class that defines the application's visual styling, including colors, typography, and layout dimensions, ensuring a consistent look and feel.