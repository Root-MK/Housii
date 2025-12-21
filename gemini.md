# Housii Project Context

## 1. Project Overview
**App Name:** Housii
**Purpose:** A household management app for families and shared living spaces to organize shopping, chores, meal planning, and garden care.
**Platforms:** Web (primary), iOS (future).
**Language:** Dart (Flutter).
**Locale:** Danish (da_DK) only.

## 2. Tech Stack
-   **Framework:** Flutter (Web primarily).
-   **State Management:** `flutter_riverpod` with `riverpod_annotation`.
-   **Navigation:** `go_router`.
-   **Backend:** Firebase (Auth, Firestore, Hosting).
-   **UI:** Material Design with Google Fonts ('Inter'), `flutter_animate`, and glassmorphism elements.
-   **Key Dependencies:**
    -   `firebase_core`, `firebase_auth`, `cloud_firestore`
    -   `google_sign_in`
    -   `flutter_riverpod`
    -   `go_router`
    -   `flutter_animate`, `flutter_svg`
    -   `uuid`, `shared_preferences`

## 3. Architecture
The project follows a **Feature-First Clean Architecture**:
-   **`lib/core`**: Shared utilities, theme, router, and common widgets (buttons, inputs).
-   **`lib/shared`**: Shared domain logic (models, services, providers) accessible across features (e.g., Auth, Home context).
-   **`lib/features`**: Isolated feature modules. Each module contains its own `data`, `domain` (providers), and `presentation` (screens, widgets) layers.
    -   **Rule:** Features should not import from other features directly. Shared logic goes to `lib/shared`.

## 4. Key Modules & Features

### Auth (`lib/features/auth`)
-   **Status:** Implemented.
-   **Features:** Google Sign-In, Pending Approval screen for new users waiting for admin acceptance.

### Home Management (`lib/features/home_management`)
-   **Status:** Implemented.
-   **Features:** Create new home, Join existing home (via code), Home settings.

### Main Shell (`lib/features/main_shell`)
-   **Status:** Implemented.
-   **Features:** Bottom navigation bar, floating action button (FAB) for quick adds.

### Shopping (`lib/features/shopping`)
-   **Status:** Implemented (Core functionality).
-   **Features:**
    -   Items with stores (Bilka, Rema 1000, etc.) or generic.
    -   "Lookout for" items.
    -   Priority/Important flagging.
    -   Grouping by store.
    -   Swipe to complete.
    -   Suggestions service.

### Lists (`lib/features/lists`)
-   **Status:** Implemented.
-   **Features:** General purpose lists, list item management.

### Food (`lib/features/food`)
-   **Status:** Implemented (Core functionality).
-   **Features:**
    -   Food ideas/recipes.
    -   Freezer items tracking.
    -   Meal planning.

### Garden (`lib/features/garden`)
-   **Status:** Basic implementation (Screen exists).
-   **Features:** Placeholder for future garden tracking.

### Household (`lib/features/household`)
-   **Status:** Basic implementation (Screen exists).
-   **Features:** Placeholder for chores/tasks.

## 5. Data Model & Backend
-   **Firestore Structure:**
    -   `users/{userId}`: User profile and admin approval status.
    -   `homes/{homeId}`: Home metadata (members, owner, join code).
    -   `homes/{homeId}/{module}/{docId}`: Sub-collections for feature data (shopping, food, etc.).
-   **Security Rules:**
    -   Users must be `admin_accepted` to create homes or join via code.
    -   Read/Write access restricted to home members.

## 6. Design System
-   **Theme:** `lib/core/theme/app_theme.dart`
-   **Colors:** Purple branding (`AppColors.primaryPurple`).
-   **Typography:** 'Inter' font family.
-   **Components:** Custom buttons (`PrimaryButton`), cards (`OptionCard`), and loading indicators.

## 7. Development Guidelines
-   **New Features:** Create a new folder in `lib/features/`.
-   **State:** Use Riverpod `AutoDispose*` providers by default.
-   **Navigation:** Register routes in `lib/core/router/app_router.dart`.
-   **Localization:** Hardcoded Danish strings in `lib/core/constants/strings_da.dart` (for now).
-   **Code Style:** Follow Flutter lints. Use `const` constructors where possible.
