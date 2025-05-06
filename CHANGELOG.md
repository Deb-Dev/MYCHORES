# Changelog

## [1.0.40] - 2025-05-09

### Fixed
- Fixed chore fetching and displaying in Android app:
  - Resolved the "Could not find enum value of RecurrenceType for value 'weekly'" error
  - Added custom FirestoreEnumConverter utility to handle lowercase enum values from Firestore
  - Enhanced Chore.RecurrenceType enum to properly handle lowercase string values
  - Updated ChoreService to use the custom converter for all Firestore operations
  - Enhanced MyChoresApplication to register custom enum handling on app startup
  - Added custom toString() method to RecurrenceType enum to ensure lowercase serialization
  - Ensured all Firestore operations properly handle cross-platform enum serialization
  - Matched enum serialization/deserialization to be compatible with iOS app

## [1.0.39] - 2025-05-09

### Fixed
- Fixed remaining "@Composable invocations" error in DrawPendingCircle:
  - Pre-captured MaterialTheme.colorScheme.secondary during composition phase
  - Moved theme color access outside of Canvas drawing scope
  - Added explanatory comments to prevent similar issues in future
  - Ensured proper separation between composition and drawing phases

## [1.0.38] - 2025-05-09

### Fixed
- Simplified status indicator in ChoresScreen.kt:
  - Updated DrawPendingCircle to use a simple circle without gradient effect
  - Added clear code comments to improve maintainability
  - Ensured consistent use of MaterialTheme color scheme 
  - Improved code documentation
  - Made StatusIcon composable more flexible with optional modifier parameter
  - Updated DrawPendingCircle to accept modifier parameter for consistency
  - Added detailed docstrings for all composables
  - Used consistent sizing for all status indicators

## [1.0.37] - 2025-05-08

### Fixed
- Fixed remaining Compose errors in ChoresScreen.kt:
  - Consolidated multiple status icon composables into a single StatusIcon composable
  - Added DrawPendingCircle helper composable to properly encapsulate Canvas drawing
  - Resolved all "@Composable invocations can only happen from the context of a @Composable function" errors
  - Improved component design with better separation of concerns

## [1.0.36] - 2025-05-08

### Fixed
- Fixed multiple Kotlin compilation errors in ChoresScreen.kt:
  - Fixed Card composable missing content parameter
  - Fixed incorrect clickable modifier usage (switched to lambda syntax)
  - Changed `when` statement to `if-else` for status icons to fix "@Composable invocations" errors
  - Fixed Composable function invocations in non-Composable contexts
  - Ensured all Compose API calls follow proper patterns

## [1.0.35] - 2025-05-08

### Fixed
- Fixed Compose error in ChoreScreen.kt:
  - Fixed incorrect usage of @Composable functions in when statements 
  - Extracted status icons into separate @Composable functions
  - Resolved "@Composable invocations can only happen from the context of a @Composable function" error
  - Properly encapsulated Canvas drawing in dedicated composable functions

## [1.0.34] - 2025-05-08

### Fixed
- Fixed structural code issues in ChoreScreen.kt:
  - Fixed incorrect function scope and brace placement causing "Unresolved reference" errors
  - Properly structured ChoreList and ChoreItem composables
  - Ensured proper scope for all composable functions
  - Made sure all colors are properly using MaterialTheme's color scheme

## [1.0.33] - 2025-05-08

### Fixed
- Fixed Canvas rendering error in ChoreItem composable:
  - Fixed Card composable syntax error that was causing layout issues
  - Added proper imports for Canvas and Stroke
  - Enhanced Canvas drawing with gradient effects to match iOS app
  - Added empty circle icon for pending chores
  - Added strikethrough text for completed chores
  - Improved Card elevation with proper shadow effects
  - Fixed overall visual fidelity to match iOS version

## [1.0.32] - 2025-05-07

### Improved
- Enhanced ChoreItem UI in Android app:
  - Redesigned the chore list item UI to match iOS styling
  - Added visual status indicators with colored circles
  - Created styled badges for points, assignees, and due dates
  - Improved visual hierarchy and spacing between elements
  - Added appropriate status icons for completed and overdue chores
  - Implemented consistent styling across card elements
  - Fixed visual appearance of chore items in list

## [1.0.31] - 2025-05-07

### Fixed
- Fixed Firestore query issues in Android app:
  - Modified ChoreService to avoid using compound queries that require special indexes
  - Replaced orderBy queries with client-side sorting for chores
  - Added better error logging in ChoreService to capture Firestore exceptions
  - Applied similar approach to both household chores and user chores fetching
  - Fixed "FAILED_PRECONDITION" errors from Firestore causing empty chore lists

## [1.0.30] - 2025-05-07

### Fixed
- Fixed chore list not showing in Android app:
  - Added LaunchedEffect to ChoreListScreen to load chores when the screen is displayed
  - Implemented proper household ID persistence in PreferencesManager
  - Updated HouseholdViewModel to save current household ID when selecting, creating, or joining a household
  - Added selectHousehold method to properly update current household and load its chores
  - Improved data loading flow between screens to ensure chores are fetched for the current household

## [1.0.29] - 2025-05-06

### Fixed
- Fixed scrolling issues in Android app:
  - Resolved crash caused by nested scrollable components in HouseholdScreen
  - Removed verticalScroll from parent Column that contained LazyColumn in HouseholdDetails composable
  - Added verticalScroll to SettingsTab composable for proper scrolling behavior 
  - Set fixed height constraint for LazyColumn in MembersTab to prevent layout conflicts
  - Verified all other screens (ChoresScreen, LeaderboardScreen, AuthScreen) to ensure they don't have scrolling conflicts
  - Improved overall UI scrolling stability in tab-based screens
  - Fixed issues with Jetpack Compose best practices for scrollable components

## [1.0.28] - 2025-05-05

### Fixed
- Fixed compilation errors in Android project:
  - Removed duplicate User and UserPrivacySettings class declarations in User.kt
  - Fixed parameter inconsistency in UserPrivacySettings (showPoints vs shareActivity)
  - Removed problematic Calendar utility object with extension functions
  - Fixed duplicate companion object in ChoreAdapter.kt with DIFF_CALLBACK
  - Fixed syntax errors in DateTimeUtils.kt related to getRelativeDateString method
- Improved email validation in authentication screens:
  - Added better client-side email validation to match iOS implementation
  - Added real-time validation feedback as users type
  - Improved error messages for invalid email formats
  - Enhanced Firebase auth error handling with user-friendly messages
- Fixed household join functionality in Android app:
  - Resolved conflict between @DocumentId annotation and 'id' field in Household model
  - Added separate documentId field to match iOS implementation where id is both a field and DocumentID
  - Updated equality and hash code methods to handle both types of IDs
- Resolved Android build issues with resource conflicts:
  - Commented out duplicate color definitions in md3_colors.xml that conflicted with colors.xml
  - Commented out duplicate string resources in strings_backup.xml that conflicted with strings.xml
  - Maintained the original files but removed the conflicting resources
  - Updated ChoreAdapter to use standard Android system colors
  - Optimized layout files to use direct size and color attributes
- Enhanced Material Design integration:
  - Added proper Material 3 color theming
  - Added text appearance styles for consistent typography
  - Improved RecyclerView item layout with standard attributes
- Dependency management:
  - Added CardView, ConstraintLayout, and Material components
  - Added RecyclerView for list display
  - Added Secure Preferences for encrypted storage

## [1.0.27] - 2025-05-05

### Added
- Enhanced Android app implementation with improved data utilities:
  - Created FirestoreUtils to streamline Firestore operations for Android
  - Implemented PreferencesManager for secure storage of user data and settings
  - Added utility classes for RecyclerView integration (ChoreAdapter)
  - Created necessary drawable resources for notification and status icons
  - Created layout file for chore items in RecyclerView (item_chore.xml)
- Updated dependency injection in Android app:
  - Modified AppContainer to include PreferencesManager
  - Updated AuthService to use secure preferences for user credentials
  - Enhanced service reliability with proper resource management

## [1.0.26] - 2025-05-04

### Added
- Added initial Android project structure
- Created Android-specific README.md with project overview
- Updated .gitignore file with Android-specific rules
- Set up basic Android project folder structure for cross-platform development

## [1.0.25] - 2025-05-03

### Added
- Set up GitHub repository for the project
- Created comprehensive README.md with project overview and setup instructions
- Implemented detailed .gitignore file with Swift-specific rules
- Prepared project for public release and collaboration

## [1.0.24] - 2025-05-03

### Added
- Implemented fully functional settings section in the Profile view:
  - Added Notification settings with customizable reminder preferences
  - Created Privacy settings for controlling data visibility
  - Implemented Help & Support section with FAQ and feedback form
  - Added About section with app information and legal links
- Created UserPrivacySettings model for privacy preference management
- Added support for persisting user settings with UserDefaults
- Implemented NotificationService methods to handle notification preferences
- Added privacy settings management to UserService

### Fixed
- Fixed compilation error in ProfileView by implementing loadUserSettings() function
- Added synchronization of user privacy settings between Firestore and local storage

## [1.0.23] - 2025-05-03

### Fixed
- Fixed jerky animation in ChoreRowView status indicators
  - Implemented smoother gradient transitions
  - Improved animation timing for a more polished experience
  - Applied consistent animation patterns across all interactive elements

## [1.0.22] - 2025-05-03

### Added
- Created advanced AnimatedView component with multiple animation modifiers:
  - Pulse, shimmer, floating, badge bounce, slide in, and gradient animations
  - Consistent API for applying animations throughout the app
- Enhanced EmptyStateView with beautiful layouts and factory methods
  - Added specialized empty states for different scenarios (chores, leaderboard, achievements)
  - Implemented animated elements and better visual hierarchy

### Improved
- Enhanced ChoreRowView with modern design elements:
  - Added animated gradient backgrounds to status indicators
  - Created visual badges for metadata (due date, points, recurrence)
  - Improved typography with better font weights and spacing
  - Added subtle animations to make the interface more engaging
- Updated CardView component with new features:
  - Added support for leading accent borders
  - Improved shadow effects for better depth perception
  - Added animation capabilities for interactive card elements

## [1.0.21] - 2025-05-03

### Improved
- Major UI enhancement for the Profile view with beautiful, modern design
- Added user statistics cards showing points, badges, and membership details
- Implemented settings section with navigational items
- Created profile editing functionality with proper form validation
- Added user avatar display with initials fallback when no profile photo exists
- Enhanced sign out experience with confirmation dialog

## [1.0.20] - 2025-05-03

### Added
- Created comprehensive system design document (SYSTEM_DESIGN.md) to serve as a reference for future development
- Document includes architecture overview, database design, key workflows, and extensibility points

## [1.0.19] - 2025-05-03

### Fixed
- Fixed compiler error: "Referencing instance method 'animation(_:value:)' on 'Array' requires that 'Chore' conform to 'Equatable'"
- Added Equatable conformance to the Chore model to support animations in ChoreListView
- Implemented custom equality comparison for Chore objects based on ID and critical properties

## [1.0.18] - 2025-05-03

### Fixed
- Fixed critical compiler error in ChoresView.swift: "Closure containing a declaration cannot be used with result builder ViewBuilder"
- Restructured view components to follow proper SwiftUI patterns
- Replaced `.onChange` modifiers with `.onReceive` for better compatibility 
- Ensured computed properties and methods are correctly placed outside the body property
- Fixed toast message handling to use the proper ToastManager API

## [1.0.17] - 2025-05-03

### Fixed
- Fixed structural issues in ChoresView.swift that were causing compiler errors
- Corrected ToastManager implementation with proper view hierarchy
- Removed redundant closing braces that broke the view structure

## [1.0.16] - 2025-05-03

### Improved
- Refactored ChoresView.swift to improve maintainability and reduce complexity
- Created ToastManager component for centralized toast message handling
- Added ChoreListView as a dedicated component for better separation of concerns
- Consolidated Theme system extensions into Theme.swift for better organization 
- Created DateExtensions.swift to centralize date-related utilities
- Implemented async/await pattern in ChoresView and ChoreViewModel for better concurrency
- Reduced potential for compiler bottlenecks with simpler, more modular code structure

## [1.0.15] - 2025-05-03

### Fixed
- Fixed issue where users would get stuck on the loading screen after signup
- Added explicit user refresh call after sign-up to ensure data is properly loaded
- Enhanced refreshCurrentUser method to explicitly update auth state when user data is loaded
- Improved LoadingView to proactively refresh user data when the loading screen appears
- Added more aggressive refresh strategies with multiple attempts when loading stalls
- Implemented state force transition as last resort to overcome persistent loading states
- Reduced timeout timer from 15 to 10 seconds for better user experience
- Fixed syntax error in MainView.swift with extra closing braces

## [1.0.14] - 2025-05-03

### Fixed
- Fixed "Failed to load badges: Missing or insufficient permissions" error on the Achievements tab
- Updated Firestore security rules to properly allow badge and points updates
- Enhanced error handling in AchievementsViewModel to avoid showing error dialogs
- Added graceful fallback to show empty badges list instead of error messages
- Improved user experience by handling permission errors elegantly

## [1.0.13] - 2025-05-03

### Fixed
- Fixed issue where household members were showing with the same name multiple times in the household tab
- Updated HouseholdView to use stableId for member identification in ForEach loops
- Enhanced household member loading logic to use the more reliable getAllHouseholdMembers method
- Improved consistency between household tab and chore assignment views

## [1.0.12] - 2025-05-03

### Fixed
- Fixed issue where multiple household members were showing with the same name in the dropdown
- Added stableId property to User model to ensure unique identification in UI lists
- Fixed nil DocumentID issue that was causing all users to appear the same in the picker
- Added explicit ID assignment mechanism for users with missing IDs
- Enhanced UI list rendering to properly display different household members

## [1.0.11] - 2025-05-03

### Fixed
- Fixed critical issue with household members not appearing in assignment dropdown due to Firestore permissions
- Completely revised user fetching strategy to use individual document fetches for more reliability
- Added multi-level fallback mechanism for user data retrieval to ensure UI always shows something useful
- Enhanced logging throughout user fetching process for better debugging
- Improved error handling when accessing user documents with permission issues

## [1.0.10] - 2025-05-03

### Fixed
- Fixed issue with chore assignment dropdown showing hard-coded "John Doe" instead of actual household members
- Updated AddChoreView to load real household members from the database
- Fixed implementation of user name display in ChoreDetailView
- Improved loading states for user information in the UI
- Added fallback mechanism to ensure household members always display, even when network issues occur
- Added Array chunking extension needed for fetching multiple users
- Enhanced error handling with graceful degradation to ensure UI remains functional
- Added detailed logging for easier debugging of household member loading issues

## [1.0.9] - 2025-05-03

### Fixed
- Fixed issue with Firestore security rules preventing users from joining households
- Added special security rule to allow users to update households when joining them
- Enhanced error handling in HouseholdService and UserService for better resilience
- Fixed issue where users couldn't be created or added to households
- Made the User model more robust with custom decoders for handling missing fields
- Improved error logging for easier debugging

### Added
- Extensive defensive programming in critical services to handle edge cases
- User creation fallback in addUserToHousehold method
- Enhanced logging throughout the household join process

## [1.0.8] - 2025-05-03

### Fixed
- Fixed Firestore security rules to properly allow users to join households with invite codes
- Added improved error handling with detailed error messages for Firestore operations
- Added custom error alert UI component for better user experience
- Fixed issue with "Missing or insufficient permissions" errors when trying to join a household

### Added
- New ErrorAlertView component for consistent error handling across the app
- Better error messages with context about what went wrong
- Additional logging for debugging issues

## [1.0.7] - 2025-05-03

### Fixed
- Fixed "Join Household Failed" error that occurred when users attempted to join a household after signup
- Improved error handling in HouseholdService and UserService for more descriptive error messages
- Enhanced the Household model to handle potential missing data during decoding
- Added retry mechanism for refreshing user data after joining a household
- Fixed compiler error "unable to type-check this expression in reasonable time" in JoinHouseholdView by breaking complex code into smaller functions

### Improved
- Enhanced JoinHouseholdView UI with better user guidance and error handling
- Added input validation for invite codes (automatic uppercasing, filtering invalid characters)
- Improved visual feedback during the joining process
- Added informational alert about invite codes

## [1.0.6] - 2025-05-03

### Fixed
- Fixed issue where users could not create a new chore when the chore list was displayed
- Added proper NavigationStack to tab views to ensure toolbar buttons are accessible
- Improved behavior of "Add a Chore" button to appear in more empty states
- Added automatic refresh of chores list after adding a new chore
- Made navigation structure consistent across all tabs

## [1.0.5] - 2025-05-03

### Fixed
- Fixed persistent permissions errors when completing chores and awarding points
- Simplified Firestore security rules to allow household members to update any chore in their household
- Relaxed user document update validation to ensure points and badges can be awarded
- Removed overly complex validation logic that was causing permission errors

## [1.0.4] - 2025-05-03

### Fixed
- Fixed issue preventing users from marking chores as complete due to Firestore security rules
- Added specific rules for handling chore completion that validate the user is authorized
- Updated validation in both top-level and subcollection chore rules for consistency
- Added permissions that allow a user to complete a chore if it's assigned to them or unassigned

## [1.0.3] - 2025-05-03

### Fixed
- Fixed crash in NotificationService when creating advance notifications
- Replaced incorrect UNNotificationContent casting with proper UNMutableNotificationContent initialization
- Improved notification content handling to ensure proper configuration of all notification properties

## [1.0.2] - 2025-05-03

### Fixed
- Fixed chore creation permission issue in Firestore security rules
- Removed overly strict validation in Firestore rules that was blocking chore creation
- Simplified security rules for better consistency and reliability
- Made validations more flexible to handle optional fields and different data types

## [1.0.1] - 2025-05-03

### Fixed
- Resolved "Missing or insufficient permissions" error when accessing chores from the Firestore database
- Updated Firestore security rules to properly validate access to top-level chores collection
- Added createdByUserId field to Chore model to track who created each chore
- Enhanced security rules to allow chore deletion by the household owner, the chore creator, or the assigned user

## [1.0.0] - 2025-05-02

### Added
- Initial setup of the MyChores app based on PRD requirements
- Project structure using MVVM architecture
- Custom theme and color assets with support for light/dark mode

### Improved
- Enhanced authentication system with better error handling, email validation, and proper @MainActor usage
- Fixed household creation flow to properly refresh user data after creating or joining a household
- Added refreshCurrentUser method to AuthService and AuthViewModel to ensure user data is always up-to-date
- Refactored AuthViewModel and AuthService to follow best practices for Firebase Authentication with async/await
- Added user-friendly error messages for various authentication scenarios
- Fixed signUp and resetPassword methods to properly handle completion and provide consistent error handling
- Improved signOut implementation with proper async Task handling in views and consistent error management
- Added robust error handling for network issues and missing user profiles
- Enhanced LoadingView with retry mechanism and improved user feedback
- Added automatic profile creation for users that exist in Auth but not in Firestore
- Base navigation and app framework

### Fixed
- Fixed crash during app launch caused by empty household IDs by adding validation across all services and ViewModels
- Added comprehensive null and empty string checking to Firestore operations
- Improved household creation to ensure proper ID handling and assignment
- Enhanced safety checks in HomeView to prevent using empty household IDs
- Authentication system implementation
  - AuthViewModel with state management and secure authentication flows
  - Email/password sign-in, sign-up, and password reset
  - Support for error handling and loading states
- Comprehensive Chores management features
  - ChoresView for viewing, filtering, and managing household tasks
  - AddChoreView for creating new chores with recurrence options
  - ChoreDetailView for viewing and completing chores
- Leaderboard implementation
  - Weekly and monthly point tracking
  - Visual podium for top performers
  - Real-time updates for points earned
- Achievements system
  - Badge tracking for completed tasks milestones
  - Visual display of earned and upcoming badges
  - Progress tracking for incomplete achievements
- Core UI components with consistent styling using Theme system
  - User avatar display
  - Badge cards with progress indicators
  - Tab-based navigation with intuitive icons

### Fixed
- Fixed integration between HomeView and HouseholdView by restructuring HomeView
- Added HouseholdViewWrapper for proper view hierarchy
- Improved onboarding flow for users without households
- Fixed AchievementsView and AchievementsViewModel property names consistency
- Fixed compiler type-checking issues in ChoresView by:
  - Breaking down complex view hierarchy into smaller components
  - Extracting components to dedicated files (FilterControlsView, EmptyStateView, ChoreRowView)
  - Creating helper extensions for accessing Theme properties
  - Simplifying overlay structure for toast messages
  - Modularizing code to improve readability and maintainability
- Fixed HouseholdViewModel to use completion handlers for async operations
  - Updated createHousehold, joinHousehold, leaveHousehold and other methods with completion callbacks
  - Renamed loadHousehold to fetchHousehold for consistency
  - Added currentUser property to HouseholdViewModel
  - Updated HomeView and HouseholdView to use the new callback pattern
- Fixed method name mismatch between UserService and HouseholdViewModel
  - Changed getUser(withId:) to fetchUser(withId:) to match the actual method name in UserService
- Fixed property name mismatch in HouseholdView's isCreator method
  - Changed household.createdByUserId to household.ownerUserId to match the Household model
- Added Equatable conformance to Household model to support onChange handler in views
- Fixed improper optional handling of householdMembers array in HouseholdView
  - Changed from optional binding with if let to direct non-optional array check
  - Fixed improper use of optional nil-coalescing on householdMembers.count
- Fixed getDayName function in ChoresView to properly get weekday names without using non-existent Date extension
- Optimized complex expressions in ChoresView to improve compiler type-checking
  - Refactored complex binding expressions into separate helper methods
  - Broke down complex conditional expressions in addChore method
  - Created dedicated binding helper methods for improved readability and performance
- Fixed "unable to type-check this expression in reasonable time" error in ChoresView
  - Decomposed complex view body into smaller, modular components
  - Extracted overlay components into reusable PointsEarnedToastView and BadgeEarnedToastView
  - Created separated @ViewBuilder functions for conditional UI components
  - Reorganized complex forms into logical section-based components
  - Improved code organization with proper MARK comments for better readability
  - Extracted swipe actions into a dedicated function for better maintainability
  - Modularized recurrence section of AddChoreView for better type inference
