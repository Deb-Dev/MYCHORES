# Firestore Permissions for Badges and Achievements

## Issues Fixed

### Issue 1: Badge Permissions (Fixed in v1.0.14)
On May 3, 2025, we fixed an issue where users were seeing an error message "Failed to load badges: Missing or insufficient permissions" when accessing the Achievements tab. 

### Issue 2: Completed Tasks Count (Fixed in v1.0.15)
On May 3, 2025, we fixed a second issue where the task completion count and badges weren't reflecting correctly in the Achievements tab, though points were displaying properly.

## Root Causes
1. The first issue was caused by restrictive Firestore security rules in the `users` collection that only allowed a user to update their own document. However, the badges system needs to update user documents when other users complete chores and earn badges.

2. The second issue was caused by restrictive security rules for the `chores` collection that didn't allow users to read chores they had completed. Additionally, the chore counting logic was only looking for chores assigned to the user, not chores completed by the user.

## Changes Made

### 1. Updated Firestore Security Rules
We modified the security rules for the `users` collection to allow specific fields related to badges and points to be updated by any authenticated user:

```javascript
// Check if update is only affecting badges or points
function isPointsOrBadgesUpdate() {
  let allowedFields = ['earnedBadges', 'totalPoints', 'weeklyPoints', 'monthlyPoints', 'currentWeekStartDate', 'currentMonthStartDate'];
  let fieldPaths = request.resource.data.diff(resource.data).affectedKeys();
  return fieldPaths.hasOnly(allowedFields);
}

// Users can update their own data, or others can update just badges and points
allow update: if isUserAuthenticated(userId) || 
                (isSignedIn() && isPointsOrBadgesUpdate());
```

### 2. Enhanced Error Handling in AchievementsViewModel
We improved the error handling logic in the AchievementsViewModel to provide a better user experience when issues occur:
- Added graceful fallbacks when user data can't be retrieved
- Implemented the `showDefaultBadges()` method to display empty state instead of error messages
- Added better error handling for fetching completed chores

### 3. Added Documentation
This document serves as reference for the permissions model used for badges and achievements in the app.

### 3. Updated Chores Security Rules
We expanded the security rules for the `chores` collection to allow users to read any chores they've completed:

```javascript
// Members can read chores in their household or chores they completed
allow read: if isSignedIn() && (isHouseholdMember(false) || 
                               (resource.data.completedByUserId != null && 
                               resource.data.completedByUserId == request.auth.uid));
```

### 4. Enhanced ChoreService
We added a new method specifically for fetching completed chores by a user:

```swift
func fetchCompletedChores(byUserId userId: String) async throws -> [Chore]
```

### 5. Improved Achievement Logic
We improved the chore counting logic to use multiple methods:
- Fetch chores completed by the user
- Fetch chores assigned to the user as a fallback
- Infer completed chore count from badge requirements if needed

## Testing
To verify the fix:
1. Sign in to the app
2. Navigate to the Achievements tab
3. Verify that badges load properly without error messages
4. Check that the task completion count is accurate
5. Complete a chore to test badge awarding and task count updating
6. Verify that earned badges appear correctly and task count increases

## Deployment
The updated Firestore security rules need to be deployed using the Firebase CLI. We've included a helper script `deploy_firestore_rules.sh` to simplify this process.
