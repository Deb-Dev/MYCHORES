## General
Before making any changes, check the existing code for similar implementations to avoid duplication.
Always try to find the root cause of any issues you encounter and fix them rather than applying quick fixes.
Ask preplexity for any firebase, firestore or related usages to check the latest documentation.
Follow the same architectural and stylistic patterns consistently throughout the project.
For any changes you make. Summarize the changes in the chnagelog.md file.
Emphasize modularity, separation of concerns, and loose coupling.
Make the UI look beautiful and user-friendly use best in class elite design practices.
Use `@MainActor` for UI-related code to ensure it runs on the main thread.
Define a list of cool looking colors and fonts in a central place (e.g., `Assets.xcassets` or a dedicated `Theme` file) to ensure consistency across the app.

## Architectural Guidelines

Use the MVVM (Model-View-ViewModel) pattern for clean architecture and separation of concerns:
Handle navigation in the app using a centralized `NavigationCoordinator` or similar pattern.
  - **Views:** SwiftUI views should be simple beautiful elegant and declarative.
  - **ViewModels:** Handle all business logic and state management.
  - **Models:** Represent data structures, using structs wherever possible.

- **Dependency Injection:** Inject dependencies via initializers or protocols. Avoid singletons.
- **State Management:** Utilize SwiftUI property wrappers (`@State`, `@ObservedObject`, `@StateObject`, `@EnvironmentObject`) appropriately.

## Coding Conventions

- **Naming:** Follow Swift naming conventions:
  - PascalCase for Types (classes, structs, enums).
  - camelCase for methods, properties, and variables.
- **Avoid Force Unwrapping:** Always handle optionals safely with `guard let` or `if let`.
- **Error Handling:** Use Swift's `Result` type or `throws`. Handle and propagate errors meaningfully.
- **File Length:** Avoid putting multiple classes or large implementations in a single file. Keep each file concise and dedicated to a single type or responsibility.

## SwiftUI Best Practices

- **Composable Components:** Break down complex views into small, reusable components.
- **Modern APIs:** Use `NavigationStack`, `async/await`, and modern SwiftUI techniques (Swift 5.9+).
- **Previews:** Provide SwiftUI previews with example data to facilitate UI iteration and maintenance.

## Modularity & Organization

- **Clear Folder Structure:** Organize files into clear groups (`Views`, `ViewModels`, `Models`, `Services` etc).
- **Extensions & MARK:** Use extensions for protocol conformances and related logic. Add `// MARK:` sections for readability.
- **Single Responsibility:** Ensure each file, class, or function has a single, well-defined responsibility.

## Localization & Theme

- **Localization:** Localize all strings
- **Theming & Colors:** Consistently use the project's defined color palette and theme resources. Avoid hardcoded colors or fonts.

## Testing & Documentation

- **Testability:** Write code that is easy to test. Use dependency injection and protocols to facilitate mocking.
- **Unit Tests:** Write unit tests for ViewModels and business logic using XCTest.
- **Inline Documentation:** Use Swift documentation (`///`) to clearly describe public methods and types. Update documentation with any code changes.

## Performance & Memory

- **Efficiency:** Be mindful of performance implications. Avoid unnecessary complexity and use efficient algorithms.
- **Memory Management:** Avoid retain cycles with `[weak self]`. Prefer structs and value types when possible.
- **Lazy Loading:** Use `@State` and `@ObservedObject` judiciously to avoid unnecessary re-renders. Use `LazyVStack` and `LazyHStack` for large lists.
- **Asynchronous Code:** Use `async/await` for network calls and long-running tasks. Ensure UI updates are performed on the main thread.
- **Combine Framework:** Use Combine for reactive programming where appropriate, but avoid overcomplicating simple tasks.
- **Swift Concurrency:** Use Swift's concurrency features (e.g., `async/await`, `Task`) for asynchronous code. Avoid callback hell and deeply nested closures.
- **Avoid Global State:** Minimize the use of global state. Use `@EnvironmentObject` or dependency injection to pass state down the view hierarchy.
- **Avoid Memory Leaks:** Use weak references in closures to prevent retain cycles. Use `weak` or `unowned` where appropriate
