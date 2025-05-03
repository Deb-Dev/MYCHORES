# Changelog

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
