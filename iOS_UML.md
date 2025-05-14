@startuml
'skinparam linetype ortho

package "Models" {
  class User {
    +id: String?
    +name: String
    +email: String
    +photoURL: String?
    +householdIds: [String]
    +fcmToken: String?
    +createdAt: Date
    +totalPoints: Int
    +weeklyPoints: Int
    +monthlyPoints: Int
    +earnedBadges: [String]
    +privacySettings: UserPrivacySettings
  }

  class Chore {
    +id: String?
    +title: String
    +description: String
    +householdId: String
    +assignedToUserId: String?
    +createdByUserId: String?
    +dueDate: Date?
    +isCompleted: Bool
    +createdAt: Date
    +completedAt: Date?
    +completedByUserId: String?
    +pointValue: Int
    +isRecurring: Bool
    +recurrenceType: RecurrenceType?
    +nextOccurrenceDate: Date?
  }

  enum RecurrenceType {
    daily
    weekly
    monthly
  }

  class Household {
    +id: String?
    +name: String
    +ownerUserId: String
    +memberUserIds: [String]
    +inviteCode: String
    +createdAt: Date
  }

  class Badge {
    +id: String?
    +badgeKey: String
    +name: String
    +description: String
    +iconName: String
    +colorName: String
    +requiredTaskCount: Int?
  }
}

package "Services" {
  interface AuthServiceProtocol {
    +currentUser: User?
    +isAuthenticated: Bool
    +authState: AuthState
    +errorMessage: String?
    +signIn(email: String, password: String)
    +signUp(name: String, email: String, password: String)
    +signOut()
    +resetPassword(for email: String)
    +refreshCurrentUser()
    +getCurrentUserId() -> String?
    +ensureCurrentProfileExists()
    +updateUserPrivacySettings(...)
    +updateUserName(newName: String)
  }

  class AuthService implements AuthServiceProtocol {
    +shared: AuthService
    -userService: UserServiceProtocol
    +currentUser: User?
    +isAuthenticated: Bool
    +authState: AuthState
    +errorMessage: String?
  }
  AuthService ..> UserServiceProtocol : uses

  interface UserServiceProtocol {
    +createUser(id: String, name: String, email: String)
    +fetchUser(withId id: String)
    +updateUser(_ user: User)
    +deleteUser(withId id: String)
  }
  class UserService implements UserServiceProtocol {
    +shared: UserService
  }

  interface ChoreServiceProtocol {
    +createChore(...)
    +fetchChore(withId id: String)
    +fetchChores(forHouseholdId householdId: String, ...)
    +fetchChores(forUserId userId: String, ...)
  }
  class ChoreService implements ChoreServiceProtocol {
     +shared: ChoreService
  }

  interface HouseholdServiceProtocol {
    +createHousehold(name: String, ownerUserId: String)
    +fetchHousehold(withId id: String)
    +fetchHouseholds(forUserId userId: String)
    +findHousehold(byInviteCode inviteCode: String)
  }
  class HouseholdService implements HouseholdServiceProtocol {
     +shared: HouseholdService
  }

   class NotificationService {
    +requestNotificationPermission()
    +scheduleChoreReminder(...)
    +cancelChoreReminder(...)
  }
}

package "ViewModels" {
  class AuthViewModel {
    +authState: AuthState
    +currentUser: User?
    +isLoading: Bool
    +errorMessage: String?
    -authService: AuthServiceProtocol
    +signIn(...)
    +signUp(...)
    +signOut()
    +resetPassword(...)
  }
  AuthViewModel --> AuthServiceProtocol : uses

  class ChoreViewModel {
    +chores: [Chore]
    +selectedChore: Chore?
    +isLoading: Bool
    -choreService: ChoreServiceProtocol
    -householdId: String
    +fetchChores()
    +addChore(...)
    +updateChore(...)
    +deleteChore(...)
    +completeChore(...)
  }
  ChoreViewModel --> ChoreServiceProtocol : uses
  ChoreViewModel ..> Chore : manages

  class HouseholdViewModel {
    +households: [Household]
    +selectedHousehold: Household?
    +householdMembers: [User]
    +currentUser: User?
    -householdService: HouseholdServiceProtocol
    -userService: UserServiceProtocol
    +fetchHouseholds()
    +fetchHouseholdDetails()
    +createHousehold(...)
    +joinHousehold(...)
    +leaveHousehold(...)
    +inviteMember(...)
  }
  HouseholdViewModel --> HouseholdServiceProtocol : uses
  HouseholdViewModel --> UserServiceProtocol : uses
  HouseholdViewModel ..> Household : manages
  HouseholdViewModel ..> User : manages

  class LeaderboardViewModel {
    +weeklyLeaderboard: [User]
    +monthlyLeaderboard: [User]
    +isLoading: Bool
    -userService: UserServiceProtocol
    -householdId: String
    +fetchLeaderboard()
  }
  LeaderboardViewModel --> UserServiceProtocol : uses
  LeaderboardViewModel ..> User : displays

  class AchievementsViewModel {
    +allBadges: [Badge]
    +earnedBadges: [Badge]
    +unearnedBadges: [Badge]
    -userService: UserServiceProtocol
    -userId: String
    +fetchAchievements()
  }
  AchievementsViewModel --> UserServiceProtocol : uses
  AchievementsViewModel ..> Badge : manages
}

package "Views" {
  class MyChoresApp {
    +delegate: AppDelegate
    +authViewModel: AuthViewModel
  }
  MyChoresApp --> AuthViewModel

  class AppDelegate {
    +application(...)
    +messaging(...)
  }

  class MainView {
    +authViewModel: AuthViewModel
  }
  MainView --> AuthViewModel : observes

  class HomeView {
    +authViewModel: AuthViewModel
    +householdViewModel: HouseholdViewModel
    +choreViewModel: ChoreViewModel
  }
  HomeView ..> AuthViewModel
  HomeView ..> HouseholdViewModel
  HomeView ..> ChoreViewModel

  class ChoresView {
    +viewModel: ChoreViewModel
    +showingAddChore: Bool
    +showingChoreDetail: Chore?
  }
  ChoresView --> ChoreViewModel : uses

  class ChoreListView {
    +viewModel: ChoreViewModel
  }
  ChoreListView --> ChoreViewModel : uses

  class ChoreDetailView {
    +chore: Chore
  }
  ChoreDetailView ..> Chore

  class AddChoreView {
    +viewModel: ChoreViewModel
  }
  AddChoreView --> ChoreViewModel : uses

  class HouseholdView {
    +viewModel: HouseholdViewModel
  }
  HouseholdView --> HouseholdViewModel : uses

  class LeaderboardView {
    +viewModel: LeaderboardViewModel
  }
  LeaderboardView --> LeaderboardViewModel : uses

  class AchievementsView {
    +viewModel: AchievementsViewModel
  }
  AchievementsView --> AchievementsViewModel : uses

  package "Components" {
    class EmptyStateView {}
    class CardView {}
    class ErrorAlertView {}
    class ShimmeringView {}
    class ToastManager {}
  }
}

' Relationships between major components
MyChoresApp ..> MainView : displays
MainView ..> HomeView : navigates (when authenticated)
MainView ..> AuthView : navigates (when unauthenticated)

HomeView ..> ChoresView : contains
HomeView ..> HouseholdView : contains
HomeView ..> LeaderboardView : contains
HomeView ..> AchievementsView : contains

User "1" -- "*" Chore : can be assigned to / created by
Household "1" -- "*" Chore : contains
Household "1" -- "*" User : has members
User "1" -- "*" Badge : earns

' Service dependencies
AuthService ..> User : manages
UserService ..> User : CRUD
ChoreService ..> Chore : CRUD
HouseholdService ..> Household : CRUD
NotificationService ..> User : sends to
NotificationService ..> Chore : reminds for

' ViewModel to Model relationships
AuthViewModel ..> User
ChoreViewModel ..> Chore
HouseholdViewModel ..> Household
HouseholdViewModel ..> User
LeaderboardViewModel ..> User
AchievementsViewModel ..> Badge
AchievementsViewModel ..> User

' View to ViewModel relationships
ChoresView ..> ChoreViewModel
ChoreListView ..> ChoreViewModel
AddChoreView ..> ChoreViewModel
HouseholdView ..> HouseholdViewModel
LeaderboardView ..> LeaderboardViewModel
AchievementsView ..> AchievementsViewModel

' General UI components might be used by many views
ChoresView ..> EmptyStateView : uses
ChoresView ..> CardView : uses
LeaderboardView ..> EmptyStateView : uses

@enduml