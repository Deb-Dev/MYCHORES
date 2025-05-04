# MyChores System Design Document

## 1. System Overview

MyChores is a task management application designed for households to track and gamify chore completion. The app employs a points-based system, leaderboards, and achievements to encourage task completion through positive reinforcement and friendly competition.

### 1.1 Core Features

- User accounts and household management
- Chore creation, assignment, and tracking
- Points system and leaderboards
- Achievement badges
- Notifications and reminders

### 1.2 Target Platform

iOS devices using SwiftUI and following MVVM architecture.

## 2. Architecture

The application follows the Model-View-ViewModel (MVVM) architectural pattern:

```
┌─────────────┐     ┌───────────────┐     ┌──────────────┐     ┌─────────────┐
│     View    │◄────┤   ViewModel   │◄────┤    Service   │◄────┤    Model    │
│  (SwiftUI)  │     │  (Observable) │     │   (Logic)    │     │   (Data)    │
└─────────────┘     └───────────────┘     └──────────────┘     └─────────────┘
```

### 2.1 Architectural Components

#### 2.1.1 Models

Data structures that represent the core entities of the application:
- `User`: Represents a user with personal details, household memberships, points, and badges
- `Household`: Represents a group of users sharing chores and leaderboards
- `Chore`: Represents a task with properties like title, description, due date, assignee, etc.
- `Badge`: Represents an achievement that users can earn

#### 2.1.2 Views

SwiftUI views responsible for rendering the user interface:
- Auth views (login, registration)
- Household management views
- Chore list and detail views
- Leaderboard views
- Achievement views

#### 2.1.3 ViewModels

Intermediaries between Views and Services, implementing business logic and state management:
- `AuthViewModel`: Manages authentication state
- `ChoreViewModel`: Handles chore operations and filtering
- `HouseholdViewModel`: Manages household data
- `LeaderboardViewModel`: Computes leaderboard rankings
- `AchievementsViewModel`: Tracks and displays achievements

#### 2.1.4 Services

Handle data operations and external service integrations:
- `AuthService`: Firebase Authentication integration
- `ChoreService`: Chore CRUD operations
- `UserService`: User management and point tracking
- `HouseholdService`: Household management
- `NotificationService`: Push notification handling

## 3. Database Design

The application uses Firebase Firestore as its primary database, with the following collections:

### 3.1 Collections

#### 3.1.1 Users Collection

```
users/{userId}
{
  id: string,              // Document ID (matches Firebase Auth UID)
  name: string,            // Display name
  email: string,           // Email address
  photoURL: string?,       // Profile picture URL
  householdIds: string[],  // List of household IDs the user belongs to
  fcmToken: string?,       // Firebase Cloud Messaging token for notifications
  createdAt: timestamp,    // User creation date
  totalPoints: number,     // All-time points
  weeklyPoints: number,    // Points for current week
  monthlyPoints: number,   // Points for current month
  currentWeekStartDate: timestamp?,  // Start of current week for points reset
  currentMonthStartDate: timestamp?, // Start of current month for points reset
  earnedBadges: string[]   // List of badge keys earned
}
```

#### 3.1.2 Households Collection

```
households/{householdId}
{
  id: string,              // Document ID
  name: string,            // Household name
  createdByUserId: string, // User who created the household
  inviteCode: string,      // Code for others to join
  memberUserIds: string[], // List of user IDs in the household
  createdAt: timestamp     // Creation date
}
```

#### 3.1.3 Chores Collection

```
chores/{choreId}
{
  id: string,              // Document ID
  title: string,           // Chore title
  description: string,     // Description
  householdId: string,     // Household this chore belongs to
  assignedToUserId: string?, // User assigned to complete the chore
  createdByUserId: string?,  // User who created the chore
  dueDate: timestamp?,     // When the chore is due
  isCompleted: boolean,    // Whether the chore is completed
  createdAt: timestamp,    // Creation date
  completedAt: timestamp?, // When the chore was completed
  completedByUserId: string?, // User who completed the chore
  pointValue: number,      // Points awarded for completion
  isRecurring: boolean,    // Whether this is a recurring chore
  recurrenceType: string?, // Daily, weekly, or monthly
  recurrenceInterval: number?, // Interval between recurrences
  recurrenceDaysOfWeek: number[]?, // For weekly recurrence
  recurrenceDayOfMonth: number?,   // For monthly recurrence
  recurrenceEndDate: timestamp?,   // End date for recurrence
  nextOccurrenceDate: timestamp?   // Date of next occurrence
}
```

#### 3.1.4 Badges (Predefined in App)

Badges are stored directly in the app code as predefined constants for simplicity in the MVP:

```
static let predefinedBadges = [
  {
    badgeKey: "first_chore",
    name: "First Step",
    description: "Completed your first chore",
    iconName: "1.circle.fill",
    colorName: "Primary",
    requiredTaskCount: 1
  },
  // More badges...
]
```

### 3.2 Security Rules

Firestore security rules enforce:
- User authentication for all operations
- Users can read all household members' data but only edit their own
- Chores can only be accessed by members of the associated household
- Data validation for required fields and value constraints

## 4. External Services & APIs

### 4.1 Firebase Services

- **Firebase Authentication**: User authentication and management
- **Firestore**: NoSQL database for application data
- **Firebase Cloud Messaging (FCM)**: Push notifications
- **Firebase Cloud Functions**: Server-side notification delivery and scheduled tasks

### 4.2 Apple Services

- **UserNotifications**: Local notifications for chore reminders
- **SwiftUI**: UI framework
- **Combine**: Reactive programming for data binding

## 5. Key Workflows

### 5.1 User Registration & Household Setup

1. User creates an account with email/password
2. Upon first login, user creates a new household or joins an existing one via invite code
3. User data and household membership are stored in Firestore

### 5.2 Chore Creation & Assignment

1. User creates a chore with title, description, due date, assignee
2. For recurring chores, recurrence pattern is specified
3. Chore is stored in Firestore with associated household ID
4. Notifications are scheduled based on due date

### 5.3 Chore Completion

1. User marks a chore as completed
2. Points are awarded to the completer's total, weekly, and monthly scores
3. If recurring, next occurrence is automatically created
4. Badge eligibility is checked and awarded if conditions are met
5. Leaderboards are updated automatically via Firestore listeners

### 5.4 Notification Flow

1. When a chore is created with a due date, local notifications are scheduled
2. Additionally, server-side notifications are registered via FCM
3. At the appropriate time, notifications are delivered to the assigned user
4. For recurring tasks, new notifications are scheduled when the next occurrence is created

## 6. State Management

### 6.1 SwiftUI Property Wrappers

- `@State`: For local component state
- `@StateObject`: For view-owned view models
- `@ObservedObject`: For view model dependencies
- `@Published`: For observable properties in view models
- `@Binding`: For passing writeable state between views

### 6.2 Data Flow

- One-way data flow from Services → ViewModels → Views
- User actions flow from Views → ViewModels → Services
- Real-time updates via Firestore listeners and @Published properties

## 7. Synchronization Strategy

### 7.1 Real-time Updates

- Firestore listeners provide real-time updates when data changes
- ViewModels expose @Published properties that automatically update the UI
- Critical operations use transactions to ensure data consistency

### 7.2 Offline Support

- Firestore provides offline persistence to allow app usage without network
- Changes are synchronized when connection is restored
- Local notifications work regardless of network status

## 8. Security Considerations

### 8.1 Authentication

- Firebase Authentication handles user identity
- Email/password authentication for MVP
- Secure storage of authentication tokens

### 8.2 Authorization

- Firestore rules restrict data access based on user and household relationships
- Client-side validation reinforced by server-side rules
- All operations verify appropriate permissions

### 8.3 Data Privacy

- User data is only visible to household members
- Points and achievements are only shared within households
- No external sharing in MVP

## 9. Performance Considerations

### 9.1 Database Queries

- Efficient querying with appropriate indexes
- Batch operations for multiple updates
- Pagination for large datasets (e.g., historical chores)

### 9.2 UI Performance

- LazyVStack/LazyHStack for list rendering
- Minimal view redraws using appropriate state scoping
- Image caching for profile pictures

### 9.3 Background Processing

- Notifications and reminders use Firebase Cloud Functions
- Point calculations and badge awarding happen server-side when possible
- Weekly/monthly point resets handled automatically

## 10. Extensibility Points

### 10.1 Future Features

- **Sign in with Apple/Google**: Additional authentication methods
- **Task Assignment Notifications**: Alert when assigned a new task
- **Complex Badges**: Based on streaks, particular chore types, etc.
- **Chore Categories**: Grouping chores by type or location
- **Chore Templates**: Pre-defined common chores for quick creation
- **Custom Reminder Times**: User preferences for notification timing
- **Household Chat**: In-app communication for household members

### 10.2 Extension Mechanisms

- Clear service interfaces allow new features without changing core structure
- Badge system designed for easy addition of new achievements
- Notification service supports multiple notification types

## 11. Testing Strategy

### 11.1 Unit Tests

- ViewModels: Business logic and state management
- Models: Data transformation and computed properties
- Services: API interactions (mocked)

### 11.2 Integration Tests

- Services: Interactions with Firebase (using emulators)
- ViewModels: Coordination with multiple services

### 11.3 UI Tests

- View navigation and interactions
- Data display correctness
- Accessibility testing

## 12. Deployment Process

### 12.1 Firebase Configuration

- Security rules deployment via script
- Cloud Functions deployment via Firebase CLI

### 12.2 App Store Submission

- App Store Connect configuration
- TestFlight distribution for beta testing
- App Store review guidelines compliance

## 13. Monitoring & Analytics

### 13.1 Error Handling

- Centralized error handling in services
- User-friendly error messages
- Logging for debugging

### 13.2 Analytics (Future)

- User engagement metrics
- Feature usage tracking
- Performance monitoring

## 14. Technical Debt & Limitations

### 14.1 Known Limitations

- Member removal and ownership transfer not implemented in MVP
- Basic badge system with limited types
- No complex notification customization in-app

### 14.2 Areas for Improvement

- Dependency injection pattern instead of singleton services
- More comprehensive error handling and recovery
- Enhanced offline capabilities

## 15. Glossary

- **Household**: A group of users sharing chores and leaderboards
- **Chore**: A task that needs to be completed, can be recurring
- **Badge**: An achievement awarded for completing certain milestones
- **Leaderboard**: A ranking of users based on points earned
- **Recurrence**: Pattern for automatically creating future instances of a chore

---

*This system design document was created on May 3, 2025, and reflects the MVP implementation of the MyChores app.*
