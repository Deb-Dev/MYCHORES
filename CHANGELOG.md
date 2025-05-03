# Changelog

## [1.0.0] - 2025-05-02

### Added
- Initial setup of the MyChores app based on PRD requirements
- Project structure using MVVM architecture
- Custom theme and color assets with support for light/dark mode
- Base navigation and app framework
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
