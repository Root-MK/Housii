# Housii - Implementeringsguide

> Version 1.0 | December 2025  
> Flutter Web App med iOS Native Support

---

## 📋 Indholdsfortegnelse

1. [Projektoversigt](#1-projektoversigt)
2. [Teknisk Stack](#2-teknisk-stack)
3. [Design System](#3-design-system)
4. [Projektstruktur](#4-projektstruktur)
5. [Firebase Opsætning](#5-firebase-opsætning)
6. [Autentificering](#6-autentificering)
7. [Hjem Management](#7-hjem-management)
8. [Navigation & Layout](#8-navigation--layout)
9. [Moduler](#9-moduler)
10. [Splash Screen](#10-splash-screen)
11. [Lokalisering](#11-lokalisering)
12. [Deployment](#12-deployment)

---

## 1. Projektoversigt

### 1.1 Formål
Housii er en husholdnings-app der hjælper familier og bofællesskaber med at organisere:
- Indkøb
- Huslige opgaver
- Madplanlægning
- Havepleje

### 1.2 Platforme
- **Primær:** Web (Flutter Web)
- **Fremtidig:** iOS Native (Flutter iOS)

### 1.3 Sprog
- Dansk (da_DK) - kun dansk understøttet

---

## 2. Teknisk Stack

### 2.1 Frontend
| Teknologi | Version | Formål |
|-----------|---------|--------|
| Flutter | 3.24+ | UI Framework |
| Dart | 3.5+ | Programmeringssprog |
| go_router | latest | Navigation |
| flutter_riverpod | latest | State Management |
| google_fonts | latest | Typography |

### 2.2 Backend (Firebase)
| Service | Formål |
|---------|--------|
| Firebase Auth | Autentificering (Google Sign-In) |
| Cloud Firestore | Database |
| Firebase Hosting | Web Hosting |

### 2.3 Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  google_sign_in: ^6.2.1
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Navigation
  go_router: ^13.0.0
  
  # UI
  google_fonts: ^6.1.0
  flutter_animate: ^4.3.0
  flutter_svg: ^2.0.9
  
  # Utils
  uuid: ^4.2.2
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
```

---

## 3. Design System

### 3.1 Farvepalette

```dart
// Primary Colors
static const Color primaryPurple = Color(0xFF5B21B6);      // Dark Purple
static const Color primaryPurpleLight = Color(0xFF7C3AED); // Light Purple
static const Color primaryPurpleDark = Color(0xFF3B0764);  // Darker Purple

// Neutral Colors
static const Color white = Color(0xFFFFFFFF);
static const Color offWhite = Color(0xFFFAFAFA);
static const Color lightGray = Color(0xFFF3F4F6);
static const Color gray = Color(0xFF9CA3AF);
static const Color darkGray = Color(0xFF374151);
static const Color black = Color(0xFF111827);

// Accent Colors
static const Color success = Color(0xFF10B981);
static const Color warning = Color(0xFFF59E0B);
static const Color error = Color(0xFFEF4444);
```

### 3.2 Typography (2025 Style)

```dart
// Font Family: Inter (clean, modern)
static const String fontFamily = 'Inter';

// Headings
headline1: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)
headline2: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3)
headline3: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)

// Body
bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)
bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)
bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)

// Labels
labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
```

### 3.3 Spacing System

```dart
// Base unit: 4px
static const double xs = 4;
static const double sm = 8;
static const double md = 16;
static const double lg = 24;
static const double xl = 32;
static const double xxl = 48;
```

### 3.4 Border Radius

```dart
static const double radiusSmall = 8;
static const double radiusMedium = 12;
static const double radiusLarge = 16;
static const double radiusXLarge = 24;
static const double radiusFull = 9999;
```

### 3.5 Shadows (2025 Soft Shadows)

```dart
// Subtle elevation
shadow1: BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
)

// Medium elevation
shadow2: BoxShadow(
  color: Color(0x14000000),
  blurRadius: 16,
  offset: Offset(0, 4),
)

// High elevation
shadow3: BoxShadow(
  color: Color(0x1F000000),
  blurRadius: 24,
  offset: Offset(0, 8),
)
```

### 3.6 Design Principper (2025)

1. **Glassmorphism Light** - Subtile blur-effekter og transparens
2. **Micro-interactions** - Smooth animationer på alle interaktioner
3. **White Space** - Generøs spacing for rent look
4. **Soft Gradients** - Purple til light purple gradients
5. **Rounded Everything** - Afrundede hjørner overalt
6. **Floating Elements** - Cards og buttons med soft shadows

---

## 4. Projektstruktur

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
│
├── core/                        # Shared across all modules
│   ├── config/
│   │   ├── firebase_config.dart
│   │   └── app_config.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── inputs/
│   │   └── loading/
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   ├── constants/
│   │   └── strings_da.dart
│   └── router/
│       └── app_router.dart
│
├── shared/                      # Shared services & models
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── home_service.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── home_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── home_provider.dart
│   └── repositories/
│       ├── user_repository.dart
│       └── home_repository.dart
│
├── features/                    # Feature modules (isolated)
│   ├── splash/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── splash_screen.dart
│   │   │   └── widgets/
│   │   │       └── animated_logo.dart
│   │   └── splash_module.dart
│   │
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── pending_approval_screen.dart
│   │   │   └── widgets/
│   │   │       └── google_sign_in_button.dart
│   │   └── auth_module.dart
│   │
│   ├── home_management/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── home_selection_screen.dart
│   │   │   │   ├── create_home_screen.dart
│   │   │   │   ├── join_home_screen.dart
│   │   │   │   └── home_settings_screen.dart
│   │   │   └── widgets/
│   │   └── home_management_module.dart
│   │
│   ├── main_shell/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── main_shell_screen.dart
│   │   │   └── widgets/
│   │   │       ├── bottom_nav_bar.dart
│   │   │       └── add_fab.dart
│   │   └── main_shell_module.dart
│   │
│   ├── shopping/                # MODULE 1: Indkøb
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── providers/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── shopping_screen.dart
│   │   │   └── widgets/
│   │   └── shopping_module.dart
│   │
│   ├── household/               # MODULE 2: Huslige opgaver
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── providers/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── household_screen.dart
│   │   │   └── widgets/
│   │   └── household_module.dart
│   │
│   ├── food/                    # MODULE 3: Mad idéer og plan
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── providers/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── food_screen.dart
│   │   │   └── widgets/
│   │   └── food_module.dart
│   │
│   └── garden/                  # MODULE 4: Have tracker
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   └── providers/
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── garden_screen.dart
│       │   └── widgets/
│       └── garden_module.dart
```

### 4.1 Modul Isolation Regler

**KRITISK:** Hvert modul skal være fuldstændig isoleret!

```
┌─────────────────────────────────────────────────────────┐
│                        core/                            │
│              (theme, widgets, utils, router)            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                       shared/                           │
│           (auth, home, services, providers)             │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │shopping │       │household│       │  food   │  ...
   └─────────┘       └─────────┘       └─────────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                     INGEN IMPORTS
                    MELLEM MODULER!
```

**Regler:**
1. Et modul må KUN importere fra `core/` og `shared/`
2. Et modul må ALDRIG importere fra et andet modul
3. Fælles logik skal altid ligge i `shared/`
4. Fælles UI komponenter skal altid ligge i `core/widgets/`

---

## 5. Firebase Opsætning

### 5.1 Firestore Database Struktur

```
firestore/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── displayName: string
│       ├── photoUrl: string?
│       ├── admin_accepted: boolean (default: false)
│       ├── currentHomeId: string?
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
│
├── homes/
│   └── {homeId}/                    # UUID
│       ├── name: string
│       ├── joinCode: string         # 16-character code
│       ├── ownerId: string
│       ├── memberIds: string[]
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
│
├── homes/{homeId}/shopping/         # Module 1 data
│   └── {itemId}/
│       └── ... (module-specific)
│
├── homes/{homeId}/household/        # Module 2 data
│   └── {taskId}/
│       └── ... (module-specific)
│
├── homes/{homeId}/food/             # Module 3 data
│   └── {mealId}/
│       └── ... (module-specific)
│
└── homes/{homeId}/garden/           # Module 4 data
    └── {plantId}/
        └── ... (module-specific)
```

### 5.2 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function: Check if user is admin approved
    function isAdminApproved() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.admin_accepted == true;
    }
    
    // Helper function: Check if user is home member
    function isHomeMember(homeId) {
      return isAdminApproved() && 
        request.auth.uid in get(/databases/$(database)/documents/homes/$(homeId)).data.memberIds;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId
        && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['admin_accepted']);
    }
    
    // Homes collection
    match /homes/{homeId} {
      allow read: if isHomeMember(homeId);
      allow create: if isAdminApproved();
      allow update: if isHomeMember(homeId);
      allow delete: if isAdminApproved() && 
        resource.data.ownerId == request.auth.uid;
      
      // Module subcollections
      match /{module}/{docId} {
        allow read, write: if isHomeMember(homeId);
      }
    }
  }
}
```

### 5.3 Firebase Auth Configuration

1. Aktivér Google Sign-In i Firebase Console
2. Tilføj authorized domains for web
3. Konfigurer OAuth consent screen

---

## 6. Autentificering

### 6.1 Auth Flow

```
┌─────────────┐
│ Splash      │
│ Screen      │
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ Check Auth State     │
└──────────┬───────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌──────────────┐
│ Not     │ │ Logged In    │
│ Logged  │ └──────┬───────┘
│ In      │        │
└────┬────┘        ▼
     │      ┌──────────────────┐
     ▼      │ Check            │
┌─────────┐ │ admin_accepted   │
│ Login   │ └──────┬───────────┘
│ Screen  │        │
└─────────┘  ┌─────┴─────┐
             │           │
             ▼           ▼
      ┌───────────┐ ┌───────────┐
      │ false     │ │ true      │
      │ Pending   │ │ Home      │
      │ Approval  │ │ Selection │
      └───────────┘ └───────────┘
                          │
                    ┌─────┴─────┐
                    │           │
                    ▼           ▼
             ┌───────────┐ ┌───────────┐
             │ No Home   │ │ Has Home  │
             │ Create/   │ │ Main App  │
             │ Join      │ │           │
             └───────────┘ └───────────┘
```

### 6.2 Login Screen Krav

- Minimalistisk white baggrund
- Housii logo centreret
- "Log ind med Google" knap med purple gradient
- Smooth fade-in animationer
- Dansk tekst: "Velkommen til Housii"

### 6.3 Pending Approval Screen

- Ikon: Sandur eller check-waiting
- Tekst: "Venter på godkendelse"
- Undertekst: "Din konto afventer godkendelse fra administrator"
- Log ud knap

---

## 7. Hjem Management

### 7.1 Home Selection Screen

Vises når bruger er godkendt men ikke har et hjem.

**UI Elements:**
- "Opret nyt hjem" kort med + ikon
- "Tilslut et hjem" kort med link ikon
- Purple gradient header

### 7.2 Create Home

**Flow:**
1. Indtast hjem navn
2. System genererer:
   - UUID som homeId
   - 16-character join code (human-readable)
3. Bruger bliver owner og tilføjet til memberIds

**Join Code Format:**
```dart
// 16 karakterer, læsbare (ingen 0/O, 1/l/I forvirring)
// Format: XXXX-XXXX-XXXX-XXXX
static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
```

### 7.3 Join Home

**Flow:**
1. Indtast 16-character join code
2. Valider kode findes
3. Tilføj bruger til home's memberIds
4. Opdater brugers currentHomeId

### 7.4 Home Settings

Tilgængelig fra main app's profil/settings.

**Features:**
- Vis home navn
- Vis join code (kun for owner)
- Kopier join code knap
- Liste over medlemmer
- Forlad hjem (ikke owner)
- Slet hjem (kun owner, kun hvis ingen andre medlemmer)

---

## 8. Navigation & Layout

### 8.1 Bottom Navigation Bar

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    [Main Content]                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  🛒        📋        (+)        🍽️        🌱           │
│ Indkøb   Opgaver     Add      Mad      Have            │
└─────────────────────────────────────────────────────────┘
```

### 8.2 Navigation Items

| Index | Ikon | Label | Route |
|-------|------|-------|-------|
| 0 | 🛒 | Indkøb | /shopping |
| 1 | 📋 | Opgaver | /household |
| - | ➕ | - | (FAB action) |
| 2 | 🍽️ | Mad | /food |
| 3 | 🌱 | Have | /garden |

### 8.3 Add Button (Center FAB)

- Floating action button i midten
- Purple gradient baggrund
- White + ikon
- Scale animation on tap
- Opens context-specific add dialog baseret på aktiv tab

### 8.4 Design Specs

```dart
// Bottom Nav Bar
height: 80
backgroundColor: Colors.white
elevation: soft shadow
borderRadius: top corners 24px

// Nav Items
iconSize: 24
labelSize: 12
activeColor: primaryPurple
inactiveColor: gray

// Center FAB
size: 56
backgroundColor: purple gradient
iconColor: white
elevation: shadow2
```

---

## 9. Moduler

### 9.1 Module Interface

Hvert modul skal eksportere en module file der definerer:

```dart
// Eksempel: shopping_module.dart
class ShoppingModule {
  static const String routeName = 'shopping';
  static const String routePath = '/shopping';
  
  static Widget screen() => const ShoppingScreen();
  
  static void showAddDialog(BuildContext context) {
    // Module-specific add dialog
  }
}
```

### 9.2 Module 1: Shopping (Indkøb)

**Placeholder tekst:** "Indkøb kommer snart"

**Fremtidig funktionalitet:**
- Indkøbslister
- Kategorisering
- Deling med husstand
- Check-off items

### 9.3 Module 2: Household (Huslige opgaver)

**Placeholder tekst:** "Opgaver kommer snart"

**Fremtidig funktionalitet:**
- Opgavelister
- Tildeling til medlemmer
- Gentagende opgaver
- Status tracking

### 9.4 Module 3: Food (Mad idéer og plan)

**Placeholder tekst:** "Madplan kommer snart"

**Fremtidig funktionalitet:**
- Opskrifter
- Ugeplanlægning
- Ingrediens-lister
- Favoritter

### 9.5 Module 4: Garden (Have tracker)

**Placeholder tekst:** "Have kommer snart"

**Fremtidig funktionalitet:**
- Plante-registrering
- Vanding påmindelser
- Sæson tracking
- Billede dokumentation

---

## 10. Splash Screen

### 10.1 Design

- Full screen white baggrund
- Centreret "Housii" tekst
- Purple gradient på tekst (eller solid primaryPurple)
- Loading animation under tekst

### 10.2 Animationer

```dart
// 1. Fade in Housii tekst (0-500ms)
FadeIn + SlightSlideUp

// 2. Pulse glow effect on text (500-1500ms)
Subtle purple glow pulse

// 3. Loading dots/spinner (after 500ms)
Three dots bouncing OR
Circular progress with gradient

// 4. Fade out entire screen (when ready)
FadeOut (300ms)
```

### 10.3 Loading Logic

```dart
// Parallel initialization
await Future.wait([
  Firebase.initializeApp(),
  Future.delayed(Duration(milliseconds: 2000)), // Minimum splash time
]);

// Then check auth state and navigate
```

---

## 11. Lokalisering

### 11.1 Dansk Strings

```dart
// lib/core/constants/strings_da.dart

class AppStrings {
  // App
  static const appName = 'Housii';
  
  // Auth
  static const welcomeTitle = 'Velkommen til Housii';
  static const loginWithGoogle = 'Log ind med Google';
  static const pendingApproval = 'Venter på godkendelse';
  static const pendingApprovalDesc = 'Din konto afventer godkendelse fra administrator';
  static const logout = 'Log ud';
  
  // Home Management
  static const createHome = 'Opret nyt hjem';
  static const joinHome = 'Tilslut et hjem';
  static const homeName = 'Hjemmets navn';
  static const joinCode = 'Tilslutningskode';
  static const enterJoinCode = 'Indtast tilslutningskode';
  static const create = 'Opret';
  static const join = 'Tilslut';
  static const homeSettings = 'Hjem indstillinger';
  static const members = 'Medlemmer';
  static const copyCode = 'Kopiér kode';
  static const codeCopied = 'Kode kopieret';
  static const leaveHome = 'Forlad hjem';
  static const deleteHome = 'Slet hjem';
  
  // Navigation
  static const shopping = 'Indkøb';
  static const household = 'Opgaver';
  static const food = 'Mad';
  static const garden = 'Have';
  
  // Placeholders
  static const comingSoon = 'Kommer snart';
  static const shoppingComingSoon = 'Indkøb kommer snart';
  static const householdComingSoon = 'Opgaver kommer snart';
  static const foodComingSoon = 'Madplan kommer snart';
  static const gardenComingSoon = 'Have kommer snart';
  
  // Common
  static const cancel = 'Annuller';
  static const save = 'Gem';
  static const delete = 'Slet';
  static const edit = 'Rediger';
  static const add = 'Tilføj';
  static const loading = 'Indlæser...';
  static const error = 'Fejl';
  static const tryAgain = 'Prøv igen';
}
```

---

## 12. Deployment

### 12.1 Web Deployment (Firebase Hosting)

```bash
# Build
flutter build web --release

# Deploy
firebase deploy --only hosting
```

### 12.2 iOS Preparation (Fremtidig)

1. Xcode project setup
2. Apple Developer account
3. Provisioning profiles
4. App Store Connect setup
5. Google Sign-In iOS configuration

### 12.3 Environment Configuration

```dart
// lib/core/config/app_config.dart

enum Environment { development, staging, production }

class AppConfig {
  static Environment environment = Environment.development;
  
  static String get firebaseProjectId {
    switch (environment) {
      case Environment.development:
        return 'housii-dev';
      case Environment.staging:
        return 'housii-staging';
      case Environment.production:
        return 'housii-prod';
    }
  }
}
```

---

## Appendix A: Checkliste

### Setup
- [ ] Flutter projekt oprettet
- [ ] Firebase projekt oprettet
- [ ] Firebase konfigureret i app
- [ ] Google Sign-In aktiveret

### Core
- [ ] Theme implementeret
- [ ] Routing sat op
- [ ] Shared widgets oprettet

### Features
- [ ] Splash screen med animationer
- [ ] Login screen med Google Sign-In
- [ ] Pending approval screen
- [ ] Home selection screen
- [ ] Create home flow
- [ ] Join home flow
- [ ] Main shell med navigation
- [ ] Shopping placeholder
- [ ] Household placeholder
- [ ] Food placeholder
- [ ] Garden placeholder
- [ ] Home settings

### Quality
- [ ] Alle danske tekster
- [ ] Animations smooth
- [ ] Design consistent
- [ ] Module isolation verified

---

*Dokumentet sidst opdateret: December 2025*
