# Firebase Security Rules for MyChores App

## ✅ Problem Solved: "Missing or insufficient permissions"

**Status: Fixed on May 3, 2025**

The error "Missing or insufficient permissions" occurred because of a mismatch between the database structure and security rules. The issue has been resolved by implementing Option 1 below.

## Previous Structure

1. The Firestore database has a top-level `chores` collection where each document contains a `householdId` field
2. The security rules were configured for chores as subcollections under households: `/households/{householdId}/chores/{choreId}`

## Implemented Solution

### Option 1: Updated Firestore Security Rules ✅

Updated security rules to validate access to the top-level `chores` collection based on household membership:

```javascript
// Top-level chores collection - access based on household membership
match /chores/{choreId} {
  // Check if user is a member of the household this chore belongs to
  function isHouseholdMember() {
    let householdId = resource.data.householdId;
    let household = get(/databases/$(database)/documents/households/$(householdId));
    return isSignedIn() && request.auth.uid in household.data.memberUserIds;
  }
  
  // Check if user is the owner of the household this chore belongs to
  function isHouseholdOwner() {
    let householdId = resource.data.householdId;
    let household = get(/databases/$(database)/documents/households/$(householdId));
    return isSignedIn() && request.auth.uid == household.data.ownerUserId;
  }
  
  // Check if user is the creator of this chore
  function isCreator() {
    return isSignedIn() && request.auth.uid == resource.data.createdByUserId;
  }
  
  // Check if chore is assigned to the user
  function isAssignedToUser() {
    return isSignedIn() && request.auth.uid == resource.data.assignedToUserId;
  }
  
  // Members can read chores in their household
  allow read: if isSignedIn() && isHouseholdMember();
  
  // Members can create chores in their household
  allow create: if isSignedIn() && (
    let householdId = request.resource.data.householdId;
    let household = get(/databases/$(database)/documents/households/$(householdId));
    request.auth.uid in household.data.memberUserIds
  );
  
  // Members can update chores in their household
  allow update: if isSignedIn() && isHouseholdMember();
  
  // Delete allowed if: user is household owner, user created the chore, or chore is assigned to user
  allow delete: if isSignedIn() && (isHouseholdOwner() || isCreator() || isAssignedToUser());
}
```

Additionally, we added a `createdByUserId` field to the `Chore` model to track who created each chore, enabling more granular permission control.

## Best Practices for Firestore Security Rules

1. **Use get() for Cross-Collection Validation**: The `get()` function allows you to look up documents in other collections to validate access.

2. **Implement User-Friendly Error Handling**: Set meaningful error codes and messages to help users understand access issues.

3. **Consider Rule Testing**: Test your security rules using the Firebase Emulator Suite before deploying.

4. **Apply Principle of Least Privilege**: Only grant the minimum permissions needed for each operation.

5. **Cache Household Data When Possible**: Store current user's household membership locally to reduce redundant checks.

## Implementation Considerations

Before making any changes:

1. **Evaluate Costs**: Using `get()` in security rules counts as a read operation, which may impact your Firestore usage costs.

2. **Test Thoroughly**: Any security rule changes should be tested extensively to ensure they don't block legitimate access.

3. **Consider Data Migration**: If restructuring your database, you'll need a migration plan.

## Next Steps

1. Review your application's security requirements
2. Decide which approach best fits your needs
3. Implement and test changes in a development environment before rolling out to production
