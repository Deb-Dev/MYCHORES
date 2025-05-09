# MyChores

A cross-platform mobile application for managing household chores with gamification features.

## Overview

MyChores helps households manage chores through a points-based system, leaderboards, and achievements to encourage task completion through positive reinforcement and friendly competition.

## Features

- User accounts and household management
- Chore creation, assignment, and tracking
- Points system and leaderboards
- Achievement badges
- Notifications and reminders

## Project Structure

This project consists of two main applications:

1. **iOS App**: Built with SwiftUI and follows MVVM architecture
2. **Android App**: Built with Jetpack Compose and follows MVVM architecture

Both apps connect to the same Firebase backend for data synchronization and authentication.

## iOS Implementation

The iOS app is built using:
- SwiftUI for the UI
- Firebase for backend services
- MVVM architecture pattern

Key files:
- `MyChores/Views/` - UI components
- `MyChores/ViewModels/` - Business logic
- `MyChores/Models/` - Data structures
- `MyChores/Services/` - Firebase and API integration

## Android Implementation

The Android app is built using:
- Jetpack Compose for the UI
- Firebase for backend services
- MVVM architecture pattern

Key directories:
- `MyChoresAnd/app/src/main/java/com/example/mychoresand/ui/screens/` - UI components
- `MyChoresAnd/app/src/main/java/com/example/mychoresand/viewmodels/` - Business logic
- `MyChoresAnd/app/src/main/java/com/example/mychoresand/models/` - Data structures
- `MyChoresAnd/app/src/main/java/com/example/mychoresand/services/` - Firebase and API integration

The Android implementation includes both standard and enhanced versions of key components:
- Standard components: Basic implementation
- Enhanced components: Match iOS functionality with improvements

See `MyChoresAnd/IMPLEMENTATION_PLAN.md` for details on the Android implementation strategy.

## Getting Started

### Prerequisites

- Xcode 15+ (for iOS)
- Android Studio (for Android)
- Firebase project with Firestore, Authentication enabled
- CocoaPods (for iOS dependencies)
- Gradle (for Android dependencies)

### Configuration

1. Clone the repository
2. Set up Firebase projects:
   - Place `GoogleService-Info.plist` in the iOS app
   - Place `google-services.json` in the Android app
3. Install dependencies:
   - For iOS: `pod install`
   - For Android: Gradle will handle dependencies automatically

### Run the App

#### iOS:
- Open `MyChores.xcworkspace` in Xcode
- Select a simulator or device
- Press Run

#### Android:
- Open the `MyChoresAnd` directory in Android Studio
- Select a simulator or device
- Press Run

## Documentation

For more detailed information, refer to:
- [PRD.md](./PRD.md) - Product Requirements Document
- [SYSTEM_DESIGN.md](./SYSTEM_DESIGN.md) - System Design Documentation
- [CHANGELOG.md](./CHANGELOG.md) - Version history and changes

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

Please ensure that any changes maintain cross-platform consistency in functionality.

## License

This project is proprietary and confidential.