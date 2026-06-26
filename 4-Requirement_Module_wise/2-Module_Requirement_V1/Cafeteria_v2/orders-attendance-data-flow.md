# Orders & Attendance Tab — Data Flow

## Data Entry Points (Where does tab data come from?)

| Tab | Create Button? | Data Entry Method | Entry Point |
|-----|:-------------:|-------------------|-------------|
| **Orders** | ❌ No | **API only** — Student mobile app / POS terminal place orders via API. Web tab is view-only. | `POST /api/cafeteria/orders` (auth:sanctum) → `OrderController::apiStore()` |
| **Meal Attendance** | ❌ No | **QR scan only** — QR scanner device at meal counter scans student QR code. Web tab is view-only. | `POST /api/cafeteria/meal-attendance/scan` (auth:sanctum) → `MealAttendanceController::apiScan()` |
| **Dietary Profiles** | ✅ Yes (Modal) | **Web form** — "Create Dietary Profile" button opens inline modal in the tab itself. | `POST /cafeteria/dietary-profiles` (web) → `DietaryProfileController::store()` |
| **POS Sessions** | ✅ Yes (Modal) | **Web form** — "Open Session" button opens inline modal in the tab itself. | `POST /cafeteria/pos/open` (web) → `PosController::openSession()` |

### Why Orders & Attendance have no Create button?

- **Orders** are placed by **students themselves** via mobile app or at POS counter — not manually created by admin from web tab. Admin only views/manages order status.
- **Meal Attendance** is recorded automatically when a **student scans their QR code** at the meal counter — not manually entered. The web tab shows attendance history only.

### Tab 3 & 4 have Create buttons because:
- **Dietary Profiles** need to be set up by admin/staff based on student medical requirements.
- **POS Sessions** need to be opened/closed by cafeteria staff at the start/end of their shift.

## Hub Structure

```
CafeteriaController::ordersAttendance()
  └── view: pages/orders-attendance.blade.php
       └── <x-backend.tab.nav-tab>
            ├── Tab 1: orders           → partials/orders-attendance/_orders.blade.php
            ├── Tab 2: attendance        → partials/orders-attendance/_attendance.blade.php
            ├── Tab 3: dietary-profiles  → partials/orders-attendance/_dietary-profiles.blade.php
            └── Tab 4: pos               → partials/orders-attendance/_pos.blade.php
```

## Dependency Graph

```
                        ┌──────────────────────┐
                        │  Menu Categories      │  ← Layer 1 (no deps)
                        │  (caf_menu_categories) │
                        └──────────┬───────────┘
                                   │
            ┌──────────────────────┼──────────────────────┐
            │                      │                      │
            ▼                      ▼                      ▼
   ┌────────────────┐   ┌──────────────────┐   ┌──────────────────┐
   │  Menu Items     │   │  Orders           │   │  Meal Attendance  │
   │ (caf_menu_items)│   │ (caf_orders)      │   │(caf_meal_attendance)│
   │ cat→MenuCategory│   │ cat→MenuCategory  │   │ cat→MenuCategory  │
   └────────┬───────┘   │ std→Students       │   │ std→Students      │
            │           │ items→OrderItems   │   └──────────────────┘
            ▼           └──────────┬─────────┘
   ┌────────────────┐             │
   │  Order Items    │             │
   │(caf_order_items)│             │
   │ item→MenuItem   │             │
   └────────────────┘             │
                                   │
   ┌──────────────────┐           │
   │  Students         │◄──────────┘
   │ (std_students)    │◄──────────┐
   │ [StudentProfile]  │           │
   └──────────────────┘           │
                                   │
   ┌──────────────────────┐        │
   │  Dietary Profiles     │        │
   │ (caf_dietary_profiles)│────────┘
   │ std→Students (UNIQUE) │
   └──────────────────────┘

   ┌──────────────────────┐    ┌──────────────────────────┐
   │  POS Sessions         │    │  POS Transactions         │
   │ (caf_pos_sessions)    │───►│ (caf_pos_transactions)     │
   │ opened_by→Users       │    │ session→PosSession        │
   │                       │    │ card→MealCards            │
   └──────────────────────┘    │ items_json (snapshot)     │
                               └──────────────────────────┘

   ┌──────────────────────┐
   │  Meal Cards           │◄──── Used by both Orders and POS
   │ (caf_meal_cards)      │       via meal_card_id FK
   │ std→Students          │
   └──────────────────────┘
```

## Tab-by-Tab Detail

### Tab 1: Orders
| Column | Source | FK / Constraint |
|--------|--------|-----------------|
| `order_number` | Auto-generated (CAF-YYYY-XXXXXXXX) | UNIQUE |
| `student_id` | `std_students.id` | FK → StudentProfile |
| `meal_card_id` | `caf_meal_cards.id` | FK → MealCards (nullable) |
| `meal_category_id` | `caf_menu_categories.id` | FK → MenuCategory |
| `total_amount` | Calculated from OrderItems | |
| `payment_mode` | MealCard / Cash / Counter / Subscription | ENUM |
| `status` | Pending→Confirmed→Preparing→Ready→Served→Delivered→Cancelled | ENUM |

**Order Items (child table):**
| Column | Source |
|--------|--------|
| `menu_item_id` | `caf_menu_items.id` |
| `price` | Snapshotted at order time |
| `quantity` | Per-item qty |
| `line_total` | qty × price |

**Feeds into views:**
- `_orders.blade.php` — list with status badges + action buttons
- `orders/show.blade.php` — dedicated detail page
- `orders/kitchen.blade.php` — kitchen display (for Preparing/Ready status)

### Tab 2: Meal Attendance
| Column | Source | Constraint |
|--------|--------|------------|
| `student_id` | `std_students.id` | FK → StudentProfile |
| `meal_date` | DATE of scan | UNIQUE (student_id, meal_date, meal_category_id) |
| `meal_category_id` | `caf_menu_categories.id` | FK → MenuCategory |
| `scan_method` | QR / Biometric / Manual | ENUM |
| `scanned_at` | Auto timestamp | |

**Read-only.** No edit/delete. QR-scan driven. Idempotent (duplicate scan returns existing record).

### Tab 3: Dietary Profiles
| Column | Source | Constraint |
|--------|--------|------------|
| `student_id` | `std_students.id` | UNIQUE (one profile per student) |
| `food_preference` | Veg / Non_Veg / Egg / Jain | ENUM |
| `is_no_onion_garlic` | boolean | |
| `is_gluten_free` | boolean | |
| `is_nut_allergy` | boolean | |
| `is_dairy_free` | boolean | |

**Full CRUD** (create via modal, show/edit/delete via dedicated pages, soft delete, toggle status).

### Tab 4: POS Sessions
| Column | Source | Constraint |
|--------|--------|------------|
| `session_date` | DATE | |
| `opened_by` | `sys_users.id` | FK → Users |
| `opened_at` | Auto timestamp | |
| `closed_at` | Nullable timestamp | NULL = open session |
| `total_cash_collected` | DECIMAL | Auto-calculated |
| `total_transactions` | INT | Auto-incremented |

**POS Transactions (child table):**
| Column | Source |
|--------|--------|
| `pos_session_id` | `caf_pos_sessions.id` |
| `student_id` | `std_students.id` (nullable for anonymous) |
| `meal_card_id` | `caf_meal_cards.id` (nullable) |
| `items_json` | JSON snapshot of purchased items |
| `payment_mode` | MealCard / Cash |
| `balance_after` | Meal card balance after deduction |

**Actions:** Open session, close session, show session detail, record transactions.

## Where Data Comes From (Module Dependencies)

| Data | Source Module | Table |
|------|-------------|-------|
| Students | StudentProfile | `std_students` |
| Users (staff) | SystemConfig / Prime | `sys_users` |
| Menu Categories | Cafeteria (self) | `caf_menu_categories` |
| Menu Items | Cafeteria (self) | `caf_menu_items` |
| Meal Cards | Cafeteria (self) | `caf_meal_cards` |

## Key Business Rules

1. **Order → Attendance:** Both reference `meal_category_id` — orders are placed for specific meal times (Breakfast/Lunch/Snacks/Dinner) which match attendance categories.
2. **Dietary Profile → Order:** A student's dietary profile (food_preference, allergies) restricts which menu items they can order — enforced at POS/ordering UI level.
3. **POS → Meal Card:** POS transactions can deduct from meal card balance (`balance_after` column tracks post-deduction balance).
4. **Attendance is immutable:** Once scanned, a meal attendance record cannot be modified or deleted. Duplicate scans return the existing record (UNIQUE constraint on `student_id, meal_date, meal_category_id`).
5. **POS session model:** Only one open session allowed per day (enforced by `PosService`). A closed session cannot be reopened.
