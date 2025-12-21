# Indkøb/Shopping Module - Implementation Guide

## Overview
Shopping module for household shopping list management with store organization, priority filtering, and shared household access.

---

## Data Model

### ShoppingItem
```dart
class ShoppingItem {
  final String id;                    // UUID
  final String name;                  // Required
  final bool active;                  // Default: true
  final String homeId;                // Reference to household
  final String createdBy;             // User ID who created
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields
  final StoreType? store;             // null = no store
  final double? price;
  final int? amount;                  // Default: 1 when set
  final bool important;               // Default: false - filtered at TOP
  final bool lookoutFor;              // Default: false - filtered at BOTTOM
  final DateRange? discountDateRange; // When item is on discount at store
}
```

### StoreType Enum
```dart
enum StoreType {
  bilka('Bilka'),
  rema1000('Rema 1000'),
  abcLavpris('ABC Lavpris'),
  other('Anden butik');
  
  final String displayName;
  const StoreType(this.displayName);
}
```

### DateRange Model
```dart
class DateRange {
  final DateTime start;
  final DateTime end;
}
```

---

## Business Rules

### Store & LookoutFor Logic
1. **If `lookoutFor = true`**: `store` MUST be `null`
2. **If `store` is set**: `lookoutFor` MUST be `false`
3. These are mutually exclusive states

### Default Values
- `active`: true
- `important`: false
- `lookoutFor`: false
- `amount`: null (shown as 1 in UI when null)
- `store`: null OR last used store in current session

### Session Memory
- Track last used store in session (not persisted)
- When creating new item, default store to last used

---

## Firestore Structure

### Collection Path
```
/homes/{homeId}/shopping/{itemId}
```

### Document Schema
```json
{
  "id": "uuid-string",
  "name": "Mælk",
  "active": true,
  "homeId": "home-uuid",
  "createdBy": "user-uuid",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "store": "bilka" | "rema1000" | "abcLavpris" | "other" | null,
  "price": 12.95 | null,
  "amount": 2 | null,
  "important": false,
  "lookoutFor": false,
  "discountStart": "Timestamp" | null,
  "discountEnd": "Timestamp" | null
}
```

### Firestore Indexes Required
```
Collection: homes/{homeId}/shopping
- active ASC, important DESC, store ASC, createdAt DESC
```

---

## List Display Logic

### Sorting Order (Top to Bottom)
1. **Important items** (`important = true`)
   - Grouped by store
   - Within store: by createdAt DESC

2. **Regular items by store** (`important = false`, `lookoutFor = false`, `store != null`)
   - Grouped by store (Bilka, Rema 1000, ABC Lavpris, Other)
   - Within store: by createdAt DESC

3. **No store items** (`store = null`, `lookoutFor = false`)
   - By createdAt DESC

4. **Lookout for items** (`lookoutFor = true`)
   - Always at bottom
   - By createdAt DESC

### Visual Grouping
```
┌─────────────────────────────────────┐
│ ⚡ VIGTIGT                          │
│ ├─ 🛒 Bilka                         │
│ │  └─ Item 1                        │
│ └─ 🛒 Rema 1000                     │
│    └─ Item 2                        │
├─────────────────────────────────────┤
│ 🛒 Bilka                            │
│ ├─ Item 3                           │
│ └─ Item 4                           │
├─────────────────────────────────────┤
│ 🛒 Rema 1000                        │
│ └─ Item 5                           │
├─────────────────────────────────────┤
│ 🛒 ABC Lavpris                      │
│ └─ Item 6                           │
├─────────────────────────────────────┤
│ 🛒 Anden butik                      │
│ └─ Item 7                           │
├─────────────────────────────────────┤
│ 📝 Uden butik                       │
│ └─ Item 8                           │
├─────────────────────────────────────┤
│ 👀 HOLD UDKIG                       │
│ └─ Item 9                           │
└─────────────────────────────────────┘
```

---

## UI Components

### 1. Shopping List Screen
**File:** `lib/features/shopping/presentation/screens/shopping_screen.dart`

```
┌─────────────────────────────────────┐
│ [Filter chips: Alle | Vigtigt | ...]│
├─────────────────────────────────────┤
│                                     │
│  Grouped list of items              │
│  (see sorting logic above)          │
│                                     │
│  Each item:                         │
│  ┌─────────────────────────────┐    │
│  │ 🥛 Mælk              x2     │    │
│  │ 12,95 kr  📅 Tilbud til 15/12│   │
│  └─────────────────────────────┘    │
│                                     │
│  ← Swipe left to complete           │
│  Long press for context menu        │
│                                     │
└─────────────────────────────────────┘
         [+ FAB from shell]
```

### 2. Shopping Item Card
**File:** `lib/features/shopping/presentation/widgets/shopping_item_card.dart`

**Features:**
- Swipe left to mark complete (with animation)
- Long press for context menu
- Show discount badge if within discount date range
- Visual distinction for important/lookoutFor

**Context Menu Options:**
- ✏️ Rediger (Edit)
- ✅ Marker som købt (Mark complete)
- 🗑️ Slet (Delete)

### 3. Add/Edit Shopping Item Bottom Sheet
**File:** `lib/features/shopping/presentation/widgets/add_shopping_item_sheet.dart`

```
┌─────────────────────────────────────┐
│ ═══  (drag handle)                  │
│                                     │
│ Tilføj vare                         │
│                                     │
│ Navn *                              │
│ [________________________]          │
│                                     │
│ Antal          Pris (kr)            │
│ [____]         [________]           │
│                                     │
│ Butik                               │
│ [Ingen ▼] [Bilka] [Rema] [ABC] [+]  │
│                                     │
│ Tilbudsdato                         │
│ [Fra] ────────── [Til]              │
│                                     │
│ [○ Vigtigt]     [○ Hold udkig]      │
│                                     │
│      [ Tilføj ]                     │
└─────────────────────────────────────┘
```

### 4. Store Section Header
**File:** `lib/features/shopping/presentation/widgets/store_section_header.dart`

Collapsible section headers for each store group.

---

## State Management

### Providers

```dart
// Shopping items stream for current home
final shoppingItemsProvider = StreamProvider.family<List<ShoppingItem>, String>((ref, homeId) {
  return ref.watch(shoppingServiceProvider).watchActiveItems(homeId);
});

// Session state (last used store)
final lastUsedStoreProvider = StateProvider<StoreType?>((ref) => null);

// Filter state
final shoppingFilterProvider = StateProvider<ShoppingFilter>((ref) => ShoppingFilter.all);

enum ShoppingFilter { all, important, lookoutFor, byStore }
```

---

## Service Layer

### ShoppingService
**File:** `lib/features/shopping/data/shopping_service.dart`

```dart
class ShoppingService {
  // CRUD Operations
  Future<void> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> deleteItem(String homeId, String itemId);
  Future<void> markComplete(String homeId, String itemId);
  
  // Queries
  Stream<List<ShoppingItem>> watchActiveItems(String homeId);
  Stream<List<ShoppingItem>> watchCompletedItems(String homeId); // For history
  
  // Batch operations
  Future<void> markMultipleComplete(String homeId, List<String> itemIds);
}
```

---

## File Structure

```
lib/features/shopping/
├── data/
│   ├── models/
│   │   ├── shopping_item.dart
│   │   ├── store_type.dart
│   │   └── date_range.dart
│   └── shopping_service.dart
├── presentation/
│   ├── providers/
│   │   └── shopping_providers.dart
│   ├── screens/
│   │   └── shopping_screen.dart
│   └── widgets/
│       ├── shopping_item_card.dart
│       ├── add_shopping_item_sheet.dart
│       ├── edit_shopping_item_sheet.dart
│       ├── store_section_header.dart
│       ├── shopping_context_menu.dart
│       └── swipe_to_complete.dart
└── domain/
    └── shopping_list_sorter.dart
```

---

## Animations & Interactions

### Swipe to Complete
- Swipe left reveals green checkmark background
- Item slides out and fades
- Haptic feedback on complete
- Undo snackbar for 5 seconds

### Context Menu (Long Press)
- Scale down item slightly on press
- Show popup menu with blur backdrop
- Options: Edit, Mark Complete, Delete

### Add Item Sheet
- Slide up from bottom
- Keyboard auto-focus on name field
- Chip selection for stores with ripple effect
- Toggle animations for important/lookoutFor

### List Animations
- Items animate in with staggered fade
- Section headers animate on expand/collapse
- Smooth reordering when items change priority

---

## Danish Strings

Add to `lib/core/constants/strings_da.dart`:

```dart
// Shopping module
static const String shoppingTitle = 'Indkøb';
static const String addItem = 'Tilføj vare';
static const String editItem = 'Rediger vare';
static const String itemName = 'Navn';
static const String itemAmount = 'Antal';
static const String itemPrice = 'Pris';
static const String selectStore = 'Butik';
static const String noStore = 'Ingen butik';
static const String otherStore = 'Anden butik';
static const String discountPeriod = 'Tilbudsperiode';
static const String discountFrom = 'Fra';
static const String discountTo = 'Til';
static const String markImportant = 'Vigtigt';
static const String lookoutFor = 'Hold udkig';
static const String markComplete = 'Marker som købt';
static const String itemCompleted = 'Vare markeret som købt';
static const String undo = 'Fortryd';
static const String deleteItem = 'Slet vare';
static const String deleteItemConfirm = 'Er du sikker på at du vil slette denne vare?';
static const String importantSection = 'Vigtigt';
static const String lookoutSection = 'Hold udkig';
static const String noStoreSection = 'Uden butik';
static const String emptyShoppingList = 'Din indkøbsliste er tom';
static const String addFirstItem = 'Tilføj din første vare';

// Store names
static const String storeBilka = 'Bilka';
static const String storeRema = 'Rema 1000';
static const String storeAbc = 'ABC Lavpris';
static const String storeOther = 'Anden';
```

---

## Implementation Order

### Phase 1: Data Layer
1. [ ] Create `ShoppingItem` model
2. [ ] Create `StoreType` enum
3. [ ] Create `DateRange` model
4. [ ] Create `ShoppingService` with Firestore integration
5. [ ] Add Firestore security rules for shopping collection

### Phase 2: State Management
6. [ ] Create shopping providers
7. [ ] Implement list sorting logic
8. [ ] Add session state for last used store

### Phase 3: UI Components
9. [ ] Create `ShoppingItemCard` with swipe-to-complete
10. [ ] Create `AddShoppingItemSheet`
11. [ ] Create `StoreSectionHeader`
12. [ ] Create context menu component

### Phase 4: Main Screen
13. [ ] Implement `ShoppingScreen` with grouped list
14. [ ] Add filter chips
15. [ ] Connect FAB to add sheet
16. [ ] Implement animations

### Phase 5: Polish
17. [ ] Add haptic feedback
18. [ ] Implement undo functionality
19. [ ] Add empty state
20. [ ] Test household sharing

---

## Security Rules Addition

Add to `firestore.rules`:

```javascript
// Shopping items - household members only
match /homes/{homeId}/shopping/{itemId} {
  allow read, write: if isAuthenticated() 
    && isHomeMember(homeId);
}
```

---

## Testing Checklist

- [ ] Create item with all fields
- [ ] Create item with only name
- [ ] Verify lookoutFor/store mutual exclusivity
- [ ] Swipe to complete works
- [ ] Context menu all options work
- [ ] Items sorted correctly
- [ ] Discount badge shows in date range
- [ ] Multiple household members see same list
- [ ] Session remembers last store
- [ ] Undo after complete works
