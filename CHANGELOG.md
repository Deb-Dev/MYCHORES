# Changelog

## [1.0.65] - 2025-05-08

### Fixed
- Fixed Firestore Timestamp constructor error when marking chores as complete:
  - Updated the code to use the correct Timestamp constructor with seconds and nanoseconds
  - Fixed proper Date to Timestamp conversion for Firestore operations

## [1.0.64] - 2025-05-08

### Fixed
- Fixed issue with marking chores as complete:
  - Changed Firestore operation from `set()` to `update()` to only modify specific fields
  - Ensured correct timestamp format for Firestore by using `Timestamp(date)` constructor
  - Added detailed logging to diagnose completion verification issues
  - Fixed field type issues in Firestore operations

## [1.0.63] - 2025-05-08

### Fixed
- Fixed string interpolation issue in error message when marking chores as complete
- Improved verification logic in ChoreService to better diagnose issues when marking chores as complete
- Enhanced error logging to show actual completion status during verification

## [1.0.62] - 2025-05-08

### Fixed
- Fixed Flow exception when creating new chores in Android app:
  - Modified Flow collection in ChoreViewModel to use `collect` instead of `first()` to prevent cancellation errors
  - Improved error handling and logging in FirestoreEnumConverter
  - Added proper exception handling in ChoreService data fetch methods
  - Enhanced UserService to correctly handle and log user data fetching issues
  - Added try-catch block around household data loading in ChoreDetailScreen
  - Fixed Flow transparency violation that was causing AbortFlow exceptions

## [1.0.61] - 2025-05-08

### Fixed
- Fixed critical issues in Android app causing chores to disappear:
  - Replaced incorrect Flow collection in `loadHouseholdChores` with `.first()` to ensure data is properly awaited
  - Added automatic refresh when switching to the "Completed" tab
  - Enhanced FirestoreEnumConverter with robust error handling and detailed logging
  - Improved chore completion handling with automatic refresh after completion
  - Added tap-to-complete functionality on status icons in the chore list
  - Fixed string interpolation issues throughout the codebase
  - Enhanced error handling for Firestore document parsing

## [1.0.60] - 2025-05-08

### Fixed
- Resolved remaining compilation errors in Android `ChoreDetailScreen.kt`:
  - Added missing `getValidHouseholdId` function to retrieve the correct household ID
  - Fixed the missing `recurrenceEndDatePickerState` initialization
  - Added `DaysOfWeekDialog` composable in a separate file with supporting functions
  - Implemented `getDayName` helper function for consistent day name display
  - Updated to use `preferencesManager` instead of non-existent `sessionManager`

## [1.0.58] - 2025-05-08

### Fixed
- Fixed compilation errors in the Android `ChoreDetailScreen.kt`:
  - Added missing imports for `Checkbox`, `Dialog`, `LocalContext`, and `FragmentActivity`.
  - Fixed smart cast issue with `recurrenceDaysOfWeek` by using null-safe operators and local variables.
  - Fixed unresolved reference issues for Calendar constants and Dialog composable.
  - Fixed syntax errors in the Text composable for days of week selection by properly structuring the code.
  - Improved type safety for day selection handling in recurrence settings with explicit lambda parameter names.
  - Cleaned up code and removed unnecessary comments.

## [1.0.57] - 2025-05-08

### Added
- Implemented "Days of Week" selection for weekly recurring chores in the Android `ChoreDetailScreen.kt`.
- Implemented "Day of Month" selection for monthly recurring chores in the Android `ChoreDetailScreen.kt`.
- Added a `DaysOfWeekDialog` composable for a user-friendly multi-selection of weekdays.
- Added `getDayName` helper function for displaying day names.

### Changed
- Updated `ChoreEditForm` in `ChoreDetailScreen.kt` to include UI elements for selecting days of the week (for weekly recurrence) and day of the month (for monthly recurrence), matching iOS functionality.

## [1.0.56] - 2025-05-08

### Changed
- Aligned Android chore management (add, edit, complete) with iOS implementation:
  - **ChoreService.kt**:
    - Ensured `nextOccurrenceDate` is correctly handled for recurring chores in `createChore`.
    - `createChore` now returns the verified `Chore` object.
    - `updateChore` preserves `createdByUserId` and `createdAt`.
    - `completeChore` uses `FirestoreEnumConverter` for robust parsing and calls `userService.checkAndAwardBadges`.
    - Ensured new instances of recurring chores get new Firestore IDs.
  - **ChoreViewModel.kt**:
    - Added `badgeEarnedMessage` StateFlow for badge notifications.
    - `createChore` & `updateChore` now more closely match iOS logic, update local lists immediately, and refresh household chores.
    - `completeChore` correctly updates lists, shows points earned, and reloads household chores to reflect new recurring instances.
    - Improved error/success message handling and data refresh logic.
    - `loadHouseholdChores` now also fetches household members.

## [1.0.55] - 2025-05-07

### Fixed
- Fixed compiler errors in ChoreDetailScreen:
  - Corrected imports and styling in the description field implementation
  - Simplified Box implementation with proper Material3 shape references
  - Removed problematic background styling that was causing compiler errors
  - Improved text field styling for consistent appearance

## [1.0.54] - 2025-05-07

### Fixed
- Fixed critical issue with chore creation in Android app:
  - Completely rewrote the chore creation flow to match iOS implementation
  - Enhanced Firestore document creation with explicit ID field updates
  - Added immediate chore list updates for better user feedback
  - Fixed description field with proper border, scrolling, and input handling
  - Added detailed logging throughout the chore creation process
  - Added verification step to confirm data is properly saved
  - Ensured all chore fields including recurrance fields are properly passed to the service

## [1.0.53] - 2025-05-06

### Fixed
- Fixed success message display issue in Android app:
  - Added separate state flow for success messages
  - Created proper success dialog with appropriate styling
  - Ensured success messages don't appear in error dialogs
  - Added verification steps to confirm chores are actually saved
  - Improved error handling and feedback during chore creation

## [1.0.52] - 2025-05-06

### Fixed
- Fixed critical issues with chore creation in Android app:
  - Fixed issue where chores weren't being created despite success message
  - Completely redesigned the description field to ensure text input works properly
  - Added proper async handling to ensure chores are fully created before navigation
  - Added detailed logging for better troubleshooting
  - Implemented verification of chore creation through explicit retrieval
  - Added callback mechanism to ensure UI state remains consistent with data changes

## [1.0.51] - 2025-05-06

### Fixed
- Fixed and improved "New Chore" screen in Android app:
  - Fixed issue with description field not allowing text input
  - Enhanced form validation with meaningful error messages
  - Improved text field UI with placeholder text and supporting text for validation
  - Added ability to clear due date and assignee with a single click
  - Improved dropdown menus with descriptive text and visual indicators
  - Enhanced recurring chore UI with better toggles and visual structure
  - Added keyboard type constraints for numeric fields
  - Improved overall UX with card-based layout and better visual hierarchy
  - Fixed compilation errors related to duplicate isError property
  - Resolved method ambiguity with clearError by removing duplicate method definition
  - Used fully qualified references to prevent ambiguity with ViewModel methods

## [1.0.50] - 2025-05-16

### Fixed
- Fixed "Add Chore" functionality in Android app:
  - Initialized householdId properly when creating new chores
  - Added additional validation to ensure chores are created with valid household IDs
  - Added a fallback mechanism to find a valid household ID when creating chores
  - Implemented better error handling with user-friendly alerts
  - Added comprehensive logging for easier debugging
  - Ensured household members are loaded for the assignee dropdown when creating a new chore

## [1.0.49] - 2025-05-14

### Fixed
- Fixed HouseholdViewModel implementation in Android app:
  - Added missing getUser method to UserService to retrieve user by ID
  - Ensured consistent API usage between HouseholdViewModel and UserService

## [1.0.48] - 2025-05-13

### Fixed
- Fixed AchievementsViewModelEnhanced implementation on Android:
  - Added missing UserService methods: getCurrentUserId, getUserById, and awardBadge
  - Fixed unresolved references to user model fields and methods
  - Enhanced error handling for badge-related operations
  - Ensured proper synchronization with iOS app badge management

## [1.0.47] - 2025-05-12

### Fixed
- Fixed compilation issues in Android's HouseholdScreenEnhanced screen:
  - Added missing clickable import
  - Fixed references to userHouseholds (now using households)
  - Added missing clearErrorMessage extension function
  - Fixed incorrect usage of LoadingIndicator by properly using modifier
  - Added ZXing library dependency for QR code generation

## [1.0.46] - 2025-05-12

### Fixed
- Fixed Firebase Functions integration in Android app:
  - Added missing Firebase Functions dependency to the Android app build.gradle.kts
  - Fixed import for Firebase.functions in NotificationServiceEnhanced
  - Corrected implementation of Firebase Functions calls with proper result handling
  - Enhanced error handling for Firebase Function responses
  - Made function call chain consistent with iOS implementation
  - Added proper result type parameters for Firebase Function calls

## [1.0.45] - 2025-05-11

### Enhanced
- Improved Android notifications handling to match iOS implementation:
  - Added proper notification permissions handling
  - Enhanced notification appearance with category-based icons
  - Added support for deep linking from notifications to specific chores
  - Implemented badge count for app icon on supported devices
- Refined Household management screen:
  - Added member role indication (owner vs member)
  - Improved invite flow with QR code support
  - Enhanced visual design to match iOS implementation
- Updated Badge achievement logic to match iOS implementation:
  - Fixed inconsistencies in badge awarding criteria
  - Added proper animations when earning new badges

## [1.0.44] - 2025-05-10

### Fixed
- Fixed compilation errors in filter tabs implementation:
  - Resolved `@Composable invocations can only happen from the context of a @Composable function` errors
  - Fixed `No parameter with name 'backgroundColor' found` in ScrollableTabRow
  - Fixed duplicate import for Icons.Default.Add
  - Moved date formatting logic to separate DateUtils class to avoid Calendar-related errors
  - Added proper imports for horizontalScroll and rememberScrollState
  - Removed unnecessary ScrollableTabRow and replaced with a simple Row + horizontalScroll implementation

## [1.0.43] - 2025-05-10

### Enhanced
- Improved Android filter tabs UI to match iOS implementation:
  - Updated filter tabs to match iOS: "Assigned to Me", "Pending", "Overdue", and "Completed"
  - Enhanced filter chip design with pill-shaped containers for a more iOS-like appearance
  - Added proper padding and spacing to match iOS design
  - Added subtle shadow effect to selected chip for better visual hierarchy
  - Set "Assigned to Me" as default selected tab to match iOS behavior
  - Fixed filter logic to properly filter chores based on selected tab
  - Improved layout with horizontal scrolling for filter chips
  - Adjusted typography to match iOS styling with proper font weights
  - Enhanced card design with subtle elevation and rounded corners
  - Improved spacing between list items for better readability
  - Refined visual hierarchy to emphasize important elements

## [1.0.42] - 2025-05-10

### Fixed
- Fixed compilation errors in ChoresScreen.kt:
  - Added missing imports for Color, Calendar, and other required classes
  - Fixed CurrentUserId not found error by implementing getCurrentUserId() method in PreferencesManager
  - Improved date formatting logic with proper Calendar instance handling
  - Fixed Color.White references by using fully qualified name
  - Added null safety for AppContainer.choreViewModel usage
  - Enhanced type safety throughout the implementation

## [1.0.41] - 2025-05-10

### Enhanced
- Improved Android chore list UI to match iOS implementation:
  - Added filter tabs for "All", "Assigned to Me", "Pending", and "Overdue" categories
  - Enhanced chore item design with better visual hierarchy and styling
  - Improved status indicators with gradient backgrounds and animated effects for overdue tasks
  - Added enhanced date formatting to show relative dates like "Today" and "Tomorrow"
  - Improved recurrence indication with proper text formatting (Daily, Weekly, etc.)
  - Added user initials display for assigned users
  - Added complete and delete functionality directly in the list view
  - Matched color schemes and visual design with iOS app for consistent cross-platform experience

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
