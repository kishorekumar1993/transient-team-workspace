# Team Workspace Mobile Application

A lightweight, production-ready Flutter mobile application demonstrating Clean Architecture, state management using BLoC, local database persistence, and robust offline-first synchronization.

This app allows team members to authenticate, view a paginated dashboard of project tasks, perform searches and compound filtering, edit tasks, toggle completed/reopened status immediately in the UI, and queue write actions offline that auto-synchronize to a simulated backend when internet connectivity returns.

---

## Architecture Overview

The codebase is organized following **feature-first Clean Architecture** principles. Each module (Auth, Tasks) is strictly decoupled and divided into three distinct layers:

```
lib/
├── core/
│   ├── di/               # Manual dependency injection (GetIt service locator)
│   ├── error/            # Failures (domain representation) & Exceptions (data layer representation)
│   ├── network/          # Dio setup, Mock API Interceptor, Network connectivity status
│   ├── persistence/      # Local Storage (SharedPreferences wrapper)
│   └── theme/            # Material 3 light/dark style specifications
├── features/
│   ├── auth/             # Sign Up, Login, Session Management
│   │   ├── data/         # Models, Local & Remote DataSources, Repository implementation
│   │   ├── domain/       # User Entities, Repository interfaces, Use cases
│   │   └── presentation/ # BLoC state, Login & SignUp Pages
│   └── tasks/            # Paginated Task Dashboard, Search/Filter, Create & Edit Tasks
│       ├── data/         # Models, Local Cache/Queue DataSources, Repository implementation
│       ├── domain/       # Task Entities, Repository interfaces, Use cases
│       └── presentation/ # Blocs (TaskListBloc, TaskFormBloc), Dashboard, Details & Form UI Pages
└── main.dart
```

### Clean Architecture Layers

1. **Domain Layer (Pure Dart)**:
   - Contains pure business logic and rule-sets. It is 100% independent of any external packages, plugins, framework UI elements, or databases.
   - Defines **Entities** (e.g. `UserEntity`, `TaskEntity`) representing core structures.
   - Defines **Use Cases** implementing single business actions (e.g. `GetTasksUseCase`, `SignUpUseCase`).
   - Defines **Repository Interfaces** specifying operations that must be implemented by the data layer.

2. **Data Layer (Infrastructure & External bindings)**:
   - Interfaces with databases, APIs, device features, and local storage.
   - Implements the repository definitions (e.g. `TaskRepositoryImpl`).
   - Declares **DataSources** to fetch data. Remote sources hit the network; local sources access local storage cache.
   - Defines **Models** extending the domain entities and adding JSON serialization methods (`fromJson`, `toJson`).

3. **Presentation Layer (UI & State)**:
   - Built around the **BLoC (Business Logic Component)** pattern to guarantee a clean separation between UI render widgets and state mutations.
   - Pages dispatch **Events** to Blocs. Blocs process business logic (via Use Cases) and yield new **States**.
   - UI widgets react dynamically to states using `BlocBuilder` and `BlocListener`.

---

## Key Technical Implementations

### 1. Fail-Safe Firebase Authentication
To satisfy the Firebase requirement while ensuring the evaluator can build and test the application instantly *without* configuring a custom Firebase project or downloading configuration plist/json files:
- The `AuthRepository` abstract definition is backed by both a real Firebase authentication implementation (`FirebaseAuthRemoteDataSourceImpl`) and a local mock datasource (`MockAuthRemoteDataSourceImpl`).
- In `service_locator.dart`, the DI engine attempts to resolve `FirebaseAuth.instance`. If the initialization fails (or missing configurations are detected), it catches the error gracefully and initializes the mock auth datasource, persisting credentials in `SharedPreferences` instead.
- Real Firebase Auth and simulated Mock Auth behave identically from the UI perspective, ensuring signup, login, session recovery, and logout operate seamlessly out-of-the-box.

### 2. Dio Paginated REST API Interceptor
- Requests targeting `https://api.workspace.com/v1/tasks` are handled by a custom `MockTaskApiInterceptor` attached to the `Dio` client.
- The interceptor maintains an in-memory database of tasks (pre-populated with 25+ diverse project items) and replicates server behavior (e.g. 600ms network delay, pagination metadata, status and priority query filters).
- To make testing the **"Retry option on API failure"** requirement easy and predictable, we added a **"Sim Error"** toggle in the Dashboard AppBar. Activating it causes the interceptor to return HTTP 500 error responses, allowing you to trigger error boundaries and click the "Retry" button.

### 3. Robust Offline Cache & Operation Syncing
- **Offline Cache**: The dashboard's first page is cached locally using `SharedPreferences`. If the device is offline or the API request fails, the repository returns these cached tasks so the app remains functional.
- **Offline Search & Filter**: Search queries and priority/status filter operations are performed *locally* on the cached data set when offline, maintaining interactive usability.
- **Offline Operations Queue**: When the app is offline (or server requests fail), task creations and edits are cached immediately in the local database to update the UI instantly. The write actions are appended to a persistent offline synchronization queue.
- **Automatic Sync Manager**: The Dashboard listens to connection status changes using `connectivity_plus`. On transition from offline to online, it fires a `SyncQueueTriggered` event to replay all queued operations to the REST API, updating the local cache, clearing the queue, and updating the UI state.

---

## Packages Used

- **`flutter_bloc`**: Manages presentation state cleanly and decouples logic from layout.
- **`get_it`**: Lightweight service locator for dependency injection.
- **`dio`**: High-performance HTTP client for handling REST API calls and integrating custom Mock interceptors.
- **`shared_preferences`**: Local key-value database used for user sessions, cached tasks lists, and the offline sync queue.
- **`firebase_core` & `firebase_auth`**: Official plugins for Firebase Authentication.
- **`connectivity_plus`**: Listens to device Wi-Fi/cellular connection changes to drive background sync.
- **`intl`**: Formats due dates inside task detail layouts.
- **`uuid`**: Generates unique, non-colliding IDs for tasks created while offline.
- **`bloc_test`** *(dev)*: Provides tools to verify BLoC state transition cascades.

---

## Assumptions Made

- **Authentication Fallback**: It is assumed that the app might be tested in environments without pre-configured Firebase projects. Hence, the graceful fallback to Mock Authentication is enabled to prevent startup crashes.
- **Mock Assigned Users**: Task assignees are populated from a pre-defined set of users ("Alice Smith", "Bob Jones", "Charlie Brown", "Diana Prince", "Evan Wright") as actual user collaboration lists were not required.
- **Pagination Size**: The default page size is set to 10 tasks to make infinite scrolling and loading indicator states easily visible across the 25+ pre-loaded tasks.

---

## Setup & Running Instructions

### Prerequisites
- [Flutter SDK (Stable channel)](https://docs.flutter.dev/get-started/install) installed and configured on your machine.
- An iOS/Android Emulator or physical debugging device connected.

### Steps to Run
1. Clone the repository and navigate to the project directory:
   ```bash
   cd transient
   ```
2. Pull application dependencies:
   ```bash
   flutter pub get
   ```
3. Run the test suite:
   ```bash
   flutter test
   ```
4. Run the application:
   ```bash
   flutter run
   ```

### Verification Scenarios to Try
1. **Login & SignUp**: Register a new email/password account. Logout, restart the app, and observe that your authenticated session is restored.
2. **Infinite Scroll Pagination**: On the Dashboard, scroll to the bottom of the list. Notice the spinner indicator as Page 2 loads.
3. **Compound Search & Filter**: Type "configure" in the search bar and select the "Pending" status chip. Observe the instant filter updates.
4. **Offline Synchronization**:
   - Turn off your internet connection (or toggle your emulator's network status).
   - Create a new task (e.g. "Draft Documentation") and mark another task as "Completed".
   - Notice that changes are reflected in the UI immediately, and an "Offline Mode" banner appears.
   - Re-enable your internet connection. Notice the loading spinner as the app automatically synchronizes your queued edits, clears the queue, and updates the cache.
5. **API Failure & Retry**: Toggle the **"Sim Error"** switch in the Dashboard AppBar. Pull to refresh, or search for a task. Observe the Error Screen with the **"Retry Option"** button. Disable the toggle and click "Retry" to verify successful reloading.
