# MyChores Android App System Design Document

## 1. Architecture Overview

The MyChores Android app follows the **MVVM (Model-View-ViewModel)** architecture pattern with a Firebase backend. The app is built using modern Android development practices with Jetpack Compose for the UI layer.

### High-Level Architecture Diagram

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  UI Components  │◄────►│   ViewModels    │◄────►│    Services     │
│  (Compose UI)   │      │                 │      │                 │
│                 │      │                 │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
                                                         │
                                                         │
                                                         ▼
                                              ┌─────────────────────┐
                                              │                     │
                                              │  Firebase Backend   │
                                              │  - Firestore        │
                                              │  - Authentication   │
                                              │  - Cloud Messaging  │
                                              │                     │
                                              └─────────────────────┘
```

## 2. Core Components

### 2.1 Models Layer

The app has several data models representing core domain entities:

- [`User`](app/src/main/java/com/example/mychoresand/models/User.kt ) - User profile and authentication data
- [`Household`](app/src/main/java/com/example/mychoresand/models/Household.kt ) - Represents a group of users sharing chores
- [`Chore`](app/src/main/java/com/example/mychoresand/models/Chore.kt ) - Represents a task to be completed
- [`Badge`](app/src/main/java/com/example/mychoresand/models/Badge.kt ) - Achievement badges users can earn

### 2.2 Services Layer

Services act as repositories that interface with Firebase:

- [`UserService`](app/src/main/java/com/example/mychoresand/services/UserService.kt ) - Handles user data and operations
- [`ChoreService`](app/src/main/java/com/example/mychoresand/services/ChoreService.kt ) - Manages chore CRUD operations
- [`HouseholdService`](app/src/main/java/com/example/mychoresand/services/HouseholdService.kt ) - Manages household data
- [`AuthService`](app/src/main/java/com/example/mychoresand/services/AuthService.kt ) - Handles authentication
- [`NotificationService`](app/src/main/java/com/example/mychoresand/services/NotificationService.kt ) - Manages push notifications

### 2.3 ViewModel Layer

ViewModels manage UI state and business logic:

- [`ChoreViewModel`](app/src/main/java/com/example/mychoresand/viewmodels/ChoreViewModel.kt ) - Manages chore-related operations
- [`HouseholdViewModel`](app/src/main/java/com/example/mychoresand/viewmodels/HouseholdViewModel.kt ) - Manages household data
- [`LeaderboardViewModel`](app/src/main/java/com/example/mychoresand/viewmodels/LeaderboardViewModel.kt ) - Manages leaderboard data
- [`AchievementsViewModel`](app/src/main/java/com/example/mychoresand/viewmodels/AchievementsViewModelEnhanced.kt ) - Manages badges and achievements

### 2.4 UI Layer

The UI is built with Jetpack Compose and is organized into screens and reusable components:

- **Screens**: HouseholdScreen, ChoresScreen, ChoreDetailScreen, etc.
- **Components**: ChoreComponents, dialog components, etc.

### 2.5 Dependency Injection

The app uses a custom dependency injection mechanism through the [`AppContainer`](app/src/main/java/com/example/mychoresand/di/AppContainer.kt ) singleton, which initializes and provides access to services and ViewModels.

### 2.6 Utilities

Various utility classes provide helper functionality:

- [`FirestoreEnumConverter`](app/src/main/java/com/example/mychoresand/utils/FirestoreEnumConverter.kt ) - Handles Firestore enum conversions
- [`ChoreUtils`](app/src/main/java/com/example/mychoresand/ui/utils/ChoreUtils.kt ) - Utilities for chore operations

## 3. Data Flow

### 3.1 User Authentication Flow

1. User sign-in request → AuthService → Firebase Auth → StateFlow updates → UI updates
2. Authentication state changes are propagated through StateFlow to update UI components

### 3.2 Chore Management Flow

1. User creates a chore → ChoreEditForm component → ChoreViewModel.createChore() → ChoreService → Firestore
2. Chore updates are observed via StateFlow → UI components update automatically

### 3.3 Household Management Flow

#### Initial Household Setup
1. After authentication, the app checks if the user has any associated households
2. If no households, user is directed to the Welcome screen presenting options to create or join a household
3. Create Household flow: User enters household name → HouseholdViewModel.createHousehold() → HouseholdService → Firestore → User redirected to HomeScreen
4. Join Household flow: User enters invite code → HouseholdViewModel.joinHousehold() → HouseholdService → Firestore → User redirected to HomeScreen

#### Household Management
1. Household data is observed through StateFlow → UI components update automatically
2. User can view household details, members, and leaderboard

#### Household Transition Flow
1. User leaves household → HouseholdViewModel.leaveHousehold() → HouseholdService → Firestore
2. HouseholdViewModel checks if user has remaining households
3. If no households remain, user is redirected to Welcome screen
4. If households remain, user is shown their other household(s)

## 4. State Management

### 4.1 Reactive State with StateFlow

The app uses Kotlin's `StateFlow` for reactive state management throughout the application. Each ViewModel maintains multiple StateFlow objects that represent different aspects of the application state:

```kotlin
// Example from HouseholdViewModel
private val _households = MutableStateFlow<List<Household>>(emptyList())
val households: StateFlow<List<Household>> = _households

private val _selectedHousehold = MutableStateFlow<Household?>(null)
val selectedHousehold: StateFlow<Household?> = _selectedHousehold

private val _isLoading = MutableStateFlow(false)
val isLoading: StateFlow<Boolean> = _isLoading

private val _errorMessage = MutableStateFlow<String?>(null)
val errorMessage: StateFlow<String?> = _errorMessage
```

UI components observe these StateFlows using `collectAsState()` to automatically update the UI when the underlying data changes:

```kotlin
val households by viewModel.households.collectAsState(initial = emptyList())
val selectedHousehold by viewModel.selectedHousehold.collectAsState(initial = null)
val isLoading by viewModel.isLoading.collectAsState(initial = false)
```

### 4.2 State Flow Management Pattern

The app follows a consistent pattern for state management:

1. **Private MutableStateFlow**: Each piece of state is managed as a private `MutableStateFlow` that can only be modified by the ViewModel.

2. **Public StateFlow Exposure**: A public read-only `StateFlow` is exposed for UI components to observe.

3. **State Updates**: State is updated in the ViewModel, typically within coroutine scopes:

```kotlin
viewModelScope.launch {
    _isLoading.value = true
    try {
        // Perform operations
        _households.value = fetchedHouseholds
    } catch (e: Exception) {
        _errorMessage.value = "Error message"
    } finally {
        _isLoading.value = false
    }
}
```

### 4.3 Navigation State Management

Navigation state is managed using the Navigation Component, with decision points based on authentication and user state:

```kotlin
// Define start destination based on auth state
val startDestination = when (authState) {
    is AuthState.Authenticated -> "home"
    else -> "auth"
}

// Check if user has a household and navigate accordingly
if (households.isEmpty()) {
    LaunchedEffect(Unit) {
        navController.navigate("welcome")
    }
}
```

### 4.4 User Session State

The authentication state is managed through a sealed class that provides type safety and clarity:

```kotlin
sealed class AuthState {
    object Loading : AuthState()
    object Unauthenticated : AuthState()
    data class Authenticated(val user: FirebaseUser) : AuthState()
}
```

### 4.5 Callback-Based State Transitions

For critical state transitions like leaving a household, the app uses callbacks to coordinate between ViewModels and navigation:

```kotlin
// Example of using callbacks for state transitions
fun leaveHousehold(householdId: String, onComplete: ((hasHouseholds: Boolean) -> Unit)? = null) {
    // Implementation with callback for navigation coordination
}
```

### 4.6 Household State Diagram

The following diagram illustrates the state transitions for household management:

```
┌───────────────┐     ┌────────────────┐     ┌────────────────────┐
│               │     │                │     │                    │
│  Authentication ────►  Check Household ────►  Has Household(s)   │
│               │     │                │     │                    │
└───────────────┘     └────────────────┘     └──────────┬─────────┘
                             │                         │
                             │ No Households          │
                             ▼                         │
               ┌───────────────────────────┐          │
               │                           │          │
               │      Welcome Screen       │◄─────────┘
               │                           │    Leave Last Household
               └─────────────┬─────────────┘
                             │
             ┌───────────────┴───────────────┐
             │                               │
  ┌──────────▼──────────┐        ┌──────────▼──────────┐
  │                     │        │                     │
  │  Create Household   │        │   Join Household    │
  │                     │        │                     │
  └──────────┬──────────┘        └──────────┬──────────┘
             │                              │
             └──────────────┬───────────────┘
                            │
                 ┌──────────▼──────────┐
                 │                     │
                 │     Home Screen     │
                 │                     │
                 └─────────────────────┘
```

This diagram shows how the application manages user state based on household membership, with particular emphasis on the transitions when a user has no household (either after signup or after leaving their last household).

## 5. Identified Issues and Improvement Recommendations

### 5.1 Dependency Injection

**Current Implementation**: Custom singleton-based AppContainer
**Issue**: Hard to test, global state, manual initialization

**Recommendation**:
- Implement Hilt or Koin for dependency injection
- Create interfaces for services to improve testability
- Separate service creation from service usage

```kotlin
// Example Hilt module
@Module
@InstallIn(SingletonComponent::class)
object ServiceModule {
    @Provides
    @Singleton
    fun provideUserService(): UserService {
        return UserService()
    }
    
    // Other service providers
}
```

### 5.2 Error Handling

**Current Implementation**: Inconsistent error handling (some through StateFlow, some through callbacks)
**Issue**: Error propagation is not standardized

**Recommendation**:
- Create a standardized Result/Resource class for all network operations
- Implement consistent error handling patterns across all ViewModels
- Add error recovery strategies

```kotlin
sealed class Resource<out T> {
    data class Success<T>(val data: T) : Resource<T>()
    data class Error(val message: String, val exception: Exception? = null) : Resource<Nothing>()
    object Loading : Resource<Nothing>()
}
```

### 5.3 Code Organization

**Current Implementation**: Some components have multiple responsibilities
**Issue**: Reduced maintainability and testability

**Recommendation**:
- Break down large files into smaller, focused components
- Extract business logic from UI components into ViewModels
- Create a clear package structure (features, common, core)

### 5.4 Firebase Integration

**Current Implementation**: Direct Firebase references in service classes
**Issue**: Tight coupling, hard to test

**Recommendation**:
- Create interfaces for Firebase services
- Use dependency injection to provide Firebase implementations
- Add a data layer between Firebase and services

```kotlin
interface ChoreRepository {
    fun getHouseholdChores(householdId: String, completed: Boolean): Flow<List<Chore>>
    // Other methods
}

class FirestoreChoreRepository : ChoreRepository {
    // Implementation using Firestore
}
```

### 5.5 Testing Strategy

**Current Implementation**: Limited or no visible testing
**Issue**: Changes could introduce regressions

**Recommendation**:
- Add unit tests for ViewModels with mockable service interfaces
- Add UI tests for critical user flows
- Implement repository interfaces for easier mocking

### 5.6 UI State Management

**Current Implementation**: The app uses a combination of StateFlow in ViewModels for application state and local state in Composables for UI-specific state. The app implements a welcome screen for users without households, with navigation based on the household state.

**Strengths**:
- Clear separation of concerns with ViewModels managing domain state
- Reactive updates through StateFlow and collectAsState
- Well-defined state transitions with callbacks for complex flows
- Navigation based on user state (authenticated, has household, etc.)

**Areas for Improvement**:
- Some duplication of state tracking across ViewModels
- Mix of StateFlow and callback approaches for state transitions
- Complex UI state is managed with multiple independent StateFlows rather than cohesive state objects

**Recommendation**:
- Consolidate related states into cohesive state objects using sealed classes
- Implement consistent UDF (Unidirectional Data Flow) pattern across all features
- Create a central StateHolder for cross-cutting concerns

```kotlin
sealed class HouseholdUiState {
    object Loading : HouseholdUiState()
    object NoHousehold : HouseholdUiState()
    data class HouseholdLoaded(
        val household: Household,
        val members: List<User>,
        val isOwner: Boolean
    ) : HouseholdUiState()
    data class Error(val message: String) : HouseholdUiState()
}
```

**Example of a consolidated state update pattern**:

```kotlin
private val _uiState = MutableStateFlow<HouseholdUiState>(HouseholdUiState.Loading)
val uiState: StateFlow<HouseholdUiState> = _uiState

// Then in the UI:
val state by viewModel.uiState.collectAsState()

when(state) {
    is HouseholdUiState.Loading -> LoadingIndicator()
    is HouseholdUiState.NoHousehold -> WelcomeScreen(...)
    is HouseholdUiState.HouseholdLoaded -> HouseholdDetails(...)
    is HouseholdUiState.Error -> ErrorMessage(...)
}
```

### 5.7 Documentation

**Current Implementation**: Good code comments but limited architectural documentation
**Issue**: New developers may struggle to understand the system design

**Recommendation**:
- Create architecture decision records (ADRs)
- Add diagrams for complex flows
- Document service interfaces and expected behaviors

## 6. Future Architecture Enhancements

### 6.1 Modularization

Split the app into feature modules:
- `:feature:auth` - Authentication feature
- `:feature:chores` - Chore management
- `:feature:household` - Household management
- `:core:ui` - Common UI components
- `:core:data` - Data repositories and models

### 6.2 Offline Support

Improve offline support using:
- Room database for local caching
- WorkManager for background syncing
- Better conflict resolution strategies

### 6.3 Performance Optimization

- Implement pagination for large lists
- Optimize Firestore queries with proper indexes
- Add query result caching

### 6.4 Enhanced Security

- Add security rules validation on client
- Implement proper token refresh mechanisms
- Add request/response encryption for sensitive data

## 7. App Signing

### Keystore Details
- **Keystore Name**: `my-chore-release-key.keystore`
- **Alias**: `my-chore-key-alias`
- **Key Algorithm**: RSA
- **Key Size**: 2048 bits
- **Validity**: 10,000 days

The keystore is used to sign the APK for release builds, ensuring the authenticity and integrity of the app. It is critical to keep the keystore file and its credentials secure, as losing them can prevent future updates to the app.

## 8. Conclusion

The MyChores Android app has a solid foundation with a clean MVVM architecture and modern Android development practices. By implementing the suggested improvements, particularly around dependency injection, error handling, and testability, the app can become more maintainable and robust for future development.

The most critical improvements are:
1. Adopting a proper dependency injection framework
2. Standardizing error handling
3. Adding comprehensive test coverage
4. Improving Firebase integration through abstraction layers

These changes will significantly reduce technical debt and make the codebase more maintainable in the long term.
