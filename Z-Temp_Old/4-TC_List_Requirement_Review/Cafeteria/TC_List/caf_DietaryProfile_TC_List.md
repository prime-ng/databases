# caf_DietaryProfile — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Dietary Profiles (Per-Student Dietary Preferences + Allergy Flags + Conflict Check)
**DB scope:** TENANT-side (`caf_dietary_profiles`) · **Test style:** Browser Dusk + API
**Primary table:** `caf_dietary_profiles` · **Module URL prefix:** `/cafeteria/orders-attendance?tab=dietary-profiles`
**Test file:** `caf_DietaryProfile_TestCas.php`
**Tab:** Dietary Profiles (third tab of Orders & Attendance)

Controllers:
- `DietaryProfileController` — index, store, update, toggleStatus, destroy
- `CafeteriaController::ordersAttendance()` — loads dietary profiles for tabbed page

Routes (`cafeteria.` prefix):
- `GET /cafeteria/orders-attendance` — tabbed page (dietary-profiles tab)
- `POST /cafeteria/dietary-profiles` — store/update (upsert)
- `POST /cafeteria/dietary-profiles/{dietaryProfile}/toggle-status` — toggle active
- `DELETE /cafeteria/dietary-profiles/{dietaryProfile}` — soft delete

**DDL reference:** `caf_dietary_profiles` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_dietary_profiles`: id (INT UNSIGNED PK AI), student_id (INT UNSIGNED NOT NULL UNIQUE FK → std_students.id ON DELETE CASCADE), food_preference (ENUM('Veg','Non_Veg','Egg','Jain') NOT NULL), is_nut_allergy (TINYINT 1 DEFAULT 0), is_dairy_allergy (TINYINT 1 DEFAULT 0), is_gluten_allergy (TINYINT 1 DEFAULT 0), is_soy_allergy (TINYINT 1 DEFAULT 0), is_no_onion_garlic (TINYINT 1 DEFAULT 0), is_gluten_free (TINYINT 1 DEFAULT 0), is_dairy_free (TINYINT 1 DEFAULT 0), custom_restrictions (TEXT NULL), medical_dietary_note (TEXT NULL), is_active (TINYINT 1 DEFAULT 1), created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (student_id), Indexes: idx_caf_dp_student | DDL |
| BC-DB-02 | Model `DietaryProfile`: table caf_dietary_profiles, SoftDeletes, fillable 11 fields, casts: is_nut_allergy→boolean, is_dairy_allergy→boolean, is_gluten_allergy→boolean, is_soy_allergy→boolean, is_active→boolean. Relations: student() belongsTo, creator() belongsTo User | Model |

### BC-VAL — Validation (StoreDietaryProfileRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required integer unique:updateOrCreate|caf_dietary_profiles,student_id (upsert handles uniqueness) | FR |
| BC-VAL-02 | `food_preference` required in:Veg,Non_Veg,Egg,Jain | FR |
| BC-VAL-03 | `is_nut_allergy` nullable boolean | FR |
| BC-VAL-04 | `is_dairy_allergy` nullable boolean | FR |
| BC-VAL-05 | `is_gluten_allergy` nullable boolean | FR |
| BC-VAL-06 | `is_soy_allergy` nullable boolean | FR |
| BC-VAL-07 | `is_no_onion_garlic` nullable boolean | FR |
| BC-VAL-08 | `is_gluten_free` nullable boolean | FR |
| BC-VAL-09 | `is_dairy_free` nullable boolean | FR |
| BC-VAL-07 | `custom_restrictions` nullable string max:1000 | FR |

### BC-AUTH — Authorization (DietaryProfilePolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.dietary.profile` (viewAny) | View |
| BC-AUTH-02 | create/store gate `cafeteria.dietary.profile.create` | Policy |
| BC-AUTH-03 | update gate `cafeteria.dietary.profile.update` | Policy |
| BC-AUTH-04 | toggle-status gate `cafeteria.dietary.profile.update` | Policy |
| BC-AUTH-05 | delete gate `cafeteria.dietary.profile.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Dietary Profiles tab: card grid layout (not table), each card shows Student Name + food preference icon | View |
| BC-BIZ-02 | Card shows allergy flag icons for each true flag (nut, dairy, gluten, soy) | View |
| BC-BIZ-03 | Card shows active/inactive toggle-switch (ToggleStatus component) | View |
| BC-BIZ-04 | Card shows Staff Name (creator) and Last Updated | View |
| BC-BIZ-05 | "Add Profile" button opens modal: student select, food_preference radio, allergy checkboxes, custom_restrictions textarea, medical_dietary_note textarea | View |
| BC-BIZ-06 | Edit modal pre-fills with existing profile data | View |
| BC-BIZ-07 | Store/Update uses `updateOrCreate(['student_id' => $data['student_id']], $data)` → one student, one profile | Ctrl |
| BC-BIZ-08 | Toggle status: toggleStatus() flips is_active true↔false | Ctrl |
| BC-BIZ-09 | Soft delete: destroy() sets deleted_at | Ctrl |
| BC-BIZ-10 | Activity logged for create/update, toggle, delete | Ctrl |
| BC-BIZ-11 | Dietary conflict check: Veg profile blocks Non_Veg+Egg dishes; Jain blocks Non_Veg+Egg; Egg blocks Non_Veg; allergen keywords matched | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Create profile for student who already has one → updateOrCreate updates existing | Ctrl |
| BC-EDG-02 | Toggle inactive profile → set is_active=0, order dietary check skips inactive profiles (implied) | Ctrl |
| BC-EDG-03 | Delete already-deleted profile → 404 | Ctrl |
| BC-EDG-04 | Veg student orders Non_Veg dish in new order → DomainException from OrderService | Service |
| BC-EDG-05 | No dietary profile exists for student → no conflict check performed (nothing to check) | Service |

---

## 2. Test Case List

### Screen 1: Dietary Profiles Tab (GET /cafeteria/orders-attendance?tab=dietary-profiles)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDP-P10 | Positive | View | Profiles tab: card grid with Student Name, food preference icon, allergy icons | Rendered | test_caf_dp_10 | Automated |
| TC-CAFDP-P11 | Positive | View | Card shows active/inactive toggle-switch | Toggle | test_caf_dp_11 | Automated |
| TC-CAFDP-P12 | Positive | View | Card shows Staff Name and Last Updated | Meta | test_caf_dp_12 | Automated |
| TC-CAFDP-P13 | Positive | View | Empty state "No dietary profiles found" | Empty | test_caf_dp_13 | Automated |
| TC-CAFDP-P14 | Positive | View | "Add Profile" button visible | Button | test_caf_dp_14 | Automated |

### Screen 2: Create/Update Profile (POST /cafeteria/dietary-profiles)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDP-P30 | Positive | Ctrl | Create profile for new student → profile created | Created | test_caf_dp_30 | Automated |
| TC-CAFDP-P31 | Positive | Ctrl | Create profile for student with existing profile → updates (upsert) | Updated | test_caf_dp_31 | Automated |
| TC-CAFDP-P32 | Positive | Ctrl | Profile with all 4 allergy flags true → flags saved | Saved | test_caf_dp_32 | Automated |
| TC-CAFDP-N33 | Negative | Val | Missing student_id → validation error | Error | test_caf_dp_33 | Automated |
| TC-CAFDP-N34 | Negative | Val | Invalid food_preference → validation error | Error | test_caf_dp_34 | Automated |

### Screen 3: Toggle Status (POST /cafeteria/dietary-profiles/{id}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDP-P50 | Positive | Ctrl | Toggle active→inactive → is_active=0, activity logged | Inactive | test_caf_dp_50 | Automated |
| TC-CAFDP-P51 | Positive | Ctrl | Toggle inactive→active → is_active=1, activity logged | Active | test_caf_dp_51 | Automated |

### Screen 4: Delete (DELETE /cafeteria/dietary-profiles/{dietaryProfile})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDP-P70 | Positive | Ctrl | Soft delete profile → deleted_at set | Deleted | test_caf_dp_70 | Automated |
| TC-CAFDP-N71 | Negative | Ctrl | Delete already-deleted profile → 404 | NotFound | test_caf_dp_71 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDP-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_dp_200 | Automated |
| TC-CAFDP-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_dp_201 | Automated |
| TC-CAFDP-N202 | Negative | Auth | Without create → 403 on store | 403 | test_caf_dp_202 | Automated |
| TC-CAFDP-N203 | Negative | Auth | Without update → 403 on toggle/update | 403 | test_caf_dp_203 | Automated |
| TC-CAFDP-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_dp_204 | Automated |
