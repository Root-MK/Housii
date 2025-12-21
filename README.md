# Housii

> Din husholdnings bedste ven 🏠

En moderne husholdnings-app bygget med Flutter til web og iOS.

## 🚀 Features

- **Indkøb** - Administrer indkøbslister
- **Opgaver** - Hold styr på huslige opgaver
- **Mad** - Planlæg måltider og opskrifter
- **Have** - Track dine planter og have

## 🛠 Tech Stack

- **Frontend:** Flutter 3.24+
- **Backend:** Firebase (Auth, Firestore)
- **State Management:** Riverpod
- **Navigation:** go_router

## 📋 Forudsætninger

- Flutter SDK 3.24+
- Firebase CLI
- Node.js (til Firebase emulators)

## 🔧 Opsætning

### 1. Klon repository

```bash
git clone https://github.com/Root-Aralore/housii.git
cd housii
```

### 2. Installer dependencies

```bash
flutter pub get
```

### 3. Firebase opsætning

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Log ind
firebase login

# Konfigurer Firebase
flutterfire configure
```

### 4. Kør appen

```bash
# Web
flutter run -d chrome

# iOS (macOS required)
flutter run -d ios
```

## 📁 Projekt Struktur

```
lib/
├── core/           # Shared theme, widgets, utils
├── shared/         # Services, models, providers
└── features/       # Feature modules (isolated)
    ├── shopping/
    ├── household/
    ├── food/
    └── garden/
```

## 📖 Dokumentation

Se [doc/01-IMPLEMENTATION-GUIDE.md](doc/01-IMPLEMENTATION-GUIDE.md) for fuld implementeringsguide.

## 🔐 Auth Flow

1. Login med Google
2. Venter på admin godkendelse (`admin_accepted: true`)
3. Opret eller tilslut et hjem
4. Fuld adgang til app

## 🎨 Design

- **Farver:** Hvid og mørk lilla
- **Stil:** 2025 moderne, clean, crisp
- **Font:** Inter

## 📱 Platforme

- ✅ Web
- 🔜 iOS

## 🇩🇰 Sprog

Appen er kun på dansk.

---

Built with ❤️ by Housii Team
