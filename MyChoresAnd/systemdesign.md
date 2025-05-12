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

1. User creates/joins a household → HouseholdViewModel → HouseholdService → Firestore
2. Household data is observed through StateFlow → UI components update automatically

## 4. State Management

The app uses Kotlin's `StateFlow` for reactive state management:

```kotlin
private val _pendingChores = MutableStateFlow<List<Chore>>(emptyList())
val pendingChores: StateFlow<List<Chore>> = _pendingChores
```

UI components observe these StateFlows using `collectAsState()`:

```kotlin
val pendingChores by viewModel.pendingChores.collectAsState()
```

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

**Current Implementation**: Mix of ViewModel state and local component state
**Issue**: State management is inconsistent

**Recommendation**:
- Move more state to ViewModels for better testability
- Use sealed classes for UI states
- Implement UDF (Unidirectional Data Flow) pattern

```kotlin
sealed class ChoreListUiState {
    object Loading : ChoreListUiState()
    data class Success(val chores: List<Chore>) : ChoreListUiState()
    data class Error(val message: String) : ChoreListUiState()
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
