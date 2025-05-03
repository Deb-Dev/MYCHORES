#!/bin/zsh

# Helper script to deploy Firestore security rules
# Created on: May 3, 2025
# This script assumes you have Firebase CLI installed

echo "Deploying Firestore security rules..."
echo "Make sure you're logged in to Firebase CLI"

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI is not installed. Please install it first with:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
firebase projects:list &> /dev/null
if [ $? -ne 0 ]; then
    echo "Please login to Firebase first:"
    echo "firebase login"
    exit 1
fi

# Deploy the rules
echo "Deploying rules from firestore.rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Successfully deployed Firestore security rules!"
    echo "The fixes for badges permissions should now be active."
else
    echo "❌ Failed to deploy Firestore security rules."
    echo "Please check the error message above and try again."
fi
