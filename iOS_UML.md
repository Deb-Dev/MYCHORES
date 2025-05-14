classDiagram
    direction LR

    class MyChoresApp {
        +AppDelegate delegate
        +AuthViewModel authViewModel
    }

    class AppDelegate {
        +FirebaseApp firebaseApp
        +Messaging messaging
        +UNUserNotificationCenter notificationCenter
        +application(didFinishLaunchingWithOptions)
        +messaging(didReceiveRegistrationToken)
        +userNotificationCenter(didReceive)
    }

    class AuthService {
        +User? currentUser
        +String errorMessage
        +signIn(email, password)
        +signUp(email, password, name)
        +signOut()
        +refreshCurrentUser()
    }

    class ChoreService {
        +addChore(Chore)
        +updateChore(Chore)
        +deleteChore(String)
        +completeChore(String)
        +fetchChores(String householdId)
    }

    class HouseholdService {
        +createHousehold(String name)
        +joinHousehold(String inviteCode)
        +leaveHousehold(String householdId)
        +fetchHousehold(String householdId)
        +fetchHouseholdMembers(String householdId)
    }

    class UserService {
        +createUser(String id, String name, String email)
        +updateUser(User)
        +fetchCurrentUser()
        +fetchUser(String userId)
    }

    class AuthViewModel {
        +AuthState authState
        +User? currentUser
        +String errorMessage
        +signIn(email, password)
        +signUp(email, password, name)
        +signOut()
        +refreshCurrentUser()
    }

    class HouseholdViewModel {
        +Household? selectedHousehold
        +User[] householdMembers
        +createHousehold(String name)
        +joinHousehold(String inviteCode)
        +leaveHousehold()
        +fetchHouseholdDetails()
    }

    class User {
        +String? id
        +String name
        +String email
        +String? photoURL
        +String[] householdIds
        +String? fcmToken
        +Date createdAt
        +Int totalPoints
        +Int weeklyPoints
        +Int monthlyPoints
        +Date? currentWeekStartDate
        +Date? currentMonthStartDate
        +String[] earnedBadges
        +UserPrivacySettings privacySettings
        +stableId() String
        +forceSetId(String)
    }

    class Chore {
        +String? id
        +String title
        +String description
        +String householdId
        +String? assignedToUserId
        +Date? dueDate
        +Bool isCompleted
        +Date createdAt
        +Date? completedAt
        +String? completedByUserId
        +Int pointValue
        +Bool isRecurring
        +isOverdue() Bool
    }

    class Household {
        +String? id
        +String name
        +String inviteCode
        +String createdByUserId
        +Date createdAt
    }

    class Badge {
        +String id
        +String name
        +String description
        +String imageURL
        +Int requiredPoints
    }

    class UserPrivacySettings {
        +Bool showProfile
        +Bool showAchievements
        +Bool shareActivity
    }

    class MainView {
        +AuthViewModel authViewModel
    }

    class HomeView {
        +AuthViewModel authViewModel
        +String? selectedHouseholdId
        +Int selectedTab
    }

    class AddChoreView {
        +String householdId
        +User[] availableUsers
        +ChoreService choreService
        +addChore()
    }

    class ChoreDetailView {
        +Chore chore
        +ChoreService choreService
        +onComplete()
        +onDelete()
    }

    class HouseholdView {
        +HouseholdViewModel viewModel
        +String? selectedHouseholdId
    }

    class ProfileView {
        +AuthViewModel authViewModel
    }

    class EmptyStateView {
        +String icon
        +String title
        +String message
        +Bool showActionButton
        +String actionButtonText
        +Function onActionTapped
    }

    class Theme {
        +Colors colors
        +Typography typography
        +Dimensions dimensions
    }

    MyChoresApp ..> AppDelegate : uses
    MyChoresApp *-- AuthViewModel : owns

    AuthViewModel ..> AuthService : uses
    HouseholdViewModel ..> HouseholdService : uses
    HouseholdViewModel ..> UserService : uses

    MainView ..> AuthViewModel : uses
    HomeView ..> AuthViewModel : uses
    HomeView ..> HouseholdView : navigates to
    HomeView ..> ProfileView : navigates to
    HomeView ..> AddChoreView : navigates to
    HomeView ..> ChoreDetailView : navigates to


    HouseholdView ..> HouseholdViewModel : uses
    AddChoreView ..> ChoreService : uses
    AddChoreView ..> UserService : uses
    ChoreDetailView ..> ChoreService : uses
    ChoreDetailView ..> UserService : uses


    AuthService ..> User : manages
    ChoreService ..> Chore : manages
    HouseholdService ..> Household : manages
    UserService ..> User : manages

    User "1" *-- "1" UserPrivacySettings : contains
    User "1" -- "0..*" Household : member of >
    User "1" -- "0..*" Chore : assigned to >
    User "1" -- "0..*" Badge : earns >

    Household "1" -- "0..*" Chore : contains >
    Household "1" -- "0..*" User : has members >

    HomeView ..> EmptyStateView : uses
    ChoreDetailView ..> Theme : uses
    AddChoreView ..> Theme : uses
    HomeView ..> Theme : uses
    HouseholdView ..> Theme : uses
    ProfileView ..> Theme : uses
    EmptyStateView ..> Theme : uses