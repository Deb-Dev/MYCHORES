# Badges and Achievements System Guide

## Overview
The MyChores app includes an achievements system that awards badges to users based on their chore completion activities. This guide explains how the system works and how to extend it.

## Badge Structure

Badges are defined in `Badge.swift` with the following structure:
```swift
struct Badge: Identifiable, Codable {
    @DocumentID var id: String?
    var badgeKey: String      // Unique identifier (e.g., "first_chore")
    var name: String          // Display name
    var description: String   // Describes how to earn it
    var iconName: String      // SF Symbol name
    var colorName: String     // Color from asset catalog
    var requiredTaskCount: Int? // Tasks needed (if applicable)
}
```

## How Badges Are Awarded

1. When a chore is marked complete in `ChoreService.swift`, `checkAndAwardBadges(forUserId:)` is called
2. This method uses the user's `totalPoints` to determine badge eligibility
3. The `UserService.awardBadge(to:badgeKey:)` method handles adding the badge to the user's document
4. The system awards milestone badges at 1, 10, 50, and 100 completed chores
5. The "first_chore" badge has a special check to ensure it's always awarded on the first completed chore

## Badge Storage and Permissions

1. Badges are not stored as separate documents - they're predefined in `Badge.predefinedBadges`
2. A user's earned badges are stored as an array of badge keys in their user document
3. Special Firestore permissions allow any authenticated user to update another user's badges
4. This enables the system to award badges regardless of who is completing the chore

## Displaying Badges

1. The `AchievementsView` shows both earned and unearned badges
2. `AchievementsViewModel` handles loading and categorizing badges
3. Error handling provides graceful fallbacks if permissions issues occur
4. Progress toward unearned badges is calculated and displayed

## Adding New Badges

To add a new badge:
1. Add the badge definition to `Badge.predefinedBadges` in `Badge.swift`
2. Update `checkAndAwardBadges(forUserId:)` in `ChoreService.swift` with logic for awarding
3. Test that the badge appears in the Achievements tab
4. Verify that it's awarded correctly when conditions are met

## Troubleshooting

If badges aren't loading or being awarded:
1. Check Firestore security rules - make sure `isPointsOrBadgesUpdate()` is working correctly
2. Verify that `User.earnedBadges` is properly initialized and accessible
3. Check for permissions errors in console logs
4. Deploy updated security rules if needed using `deploy_firestore_rules.sh`

## Security Rule Considerations

The badge system is designed to work with Firestore security rules that:

1. Allow any authenticated user to update another user's `earnedBadges` array (via the `isPointsOrBadgesUpdate()` rule)
2. Restrict direct queries across all chores to only those in the user's household

To accommodate these security restrictions, the badge system:
1. Uses the `totalPoints` field in the User document as a proxy for completed chore count
2. Has a special check for the "first_chore" badge to ensure backward compatibility
3. Uses milestone counts (10, 50, 100) based on `totalPoints`
4. Disables streak and early-completion badges which would require cross-household queries

If you need to implement more complex badges that require querying across households:
1. Update the Firestore security rules to allow these queries
2. Re-enable the commented out methods in `ChoreService.swift`
