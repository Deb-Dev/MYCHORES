# Firebase Security Rules Implementation Guide

These instructions will help you implement the updated Firestore security rules to fix the "Missing or insufficient permissions" error in your MyChores app.

## 1. Copy the Firebase Security Rules

I've created a file called `firestore.rules` in your project directory with properly structured security rules that match your Household model and access patterns.

## 2. Deploy the Rules to Firebase

Follow these steps to deploy the updated security rules to your Firebase project:

### Option 1: Using the Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left navigation, click on "Firestore Database"
4. Click on the "Rules" tab
5. Delete the existing rules and copy-paste the contents of the `firestore.rules` file
6. Click "Publish" to deploy your rules

### Option 2: Using the Firebase CLI

If you have the Firebase CLI installed, you can deploy the rules directly from the terminal:

```bash
# Navigate to your project directory
cd /Users/debchow/Documents/coco/MyChores

# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase (if not already logged in)
firebase login

# Initialize Firebase in your project (if not already initialized)
firebase init firestore

# Deploy the rules
firebase deploy --only firestore:rules
```

## 3. Verify Your Rules

After deploying the rules:

1. Make sure they're properly formatted and have no syntax errors
2. Test if the "Missing or insufficient permissions" error is resolved
3. Confirm that household creation, joining, and access all work correctly

## 4. Key Rule Implementation Details

The security rules implement the following access pattern:

- **Users collection**:
  - Users can only read and write their own data

- **Households collection**:
  - Read: Users can only read households where they're either the owner or a member
  - Create: Users can create households if they set themselves as owner and member
  - Update: Only members can update a household, and they can't change the owner
  - Delete: Only the owner can delete a household

- **Chores subcollection**:
  - Read/Create/Update: Any household member can read, create and update chores
  - Delete: Only the household owner can delete chores

## 5. Troubleshooting

If you still encounter permission issues:

1. Check Firebase console logs for more specific error details
2. Verify that all users are properly authenticated
3. Ensure that the Household model's `ownerUserId` and `memberUserIds` fields match the field names in the security rules
4. Confirm that when creating a household, the current user's ID is added to both the `ownerUserId` and the `memberUserIds` array

I've updated the CHANGELOG.md to document these changes.
