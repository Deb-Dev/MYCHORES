# Changelog

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
