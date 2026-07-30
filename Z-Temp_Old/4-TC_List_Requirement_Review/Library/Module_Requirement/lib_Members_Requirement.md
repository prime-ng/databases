# Lib Members — Business Requirements

## What This Screen Does
Manages library member records — the people (Students, Teachers, Staff) who borrow books and use library services. Each member is linked to a system user account (`sys_users`) and has a membership profile including membership type (e.g., Standard, Premium), barcode, registration/expiry dates, reading preferences, engagement metrics, and status. Admins can create, edit, view, search, filter, soft-delete, restore, and manage member statuses, including suspension with reason tracking.

---

## When This Screen Is Used
- Registering a new library member (linking an existing system user to a library membership).
- Viewing a member's complete profile including borrowing history, fines, and engagement metrics.
- Renewing or updating membership details (expiry date, membership type, barcode).
- Suspending a member for policy violations with a tracked reason.
- Changing a member's status (e.g., Active ↔ Suspended).
- Searching for members by name, membership type, status, segment, or outstanding fines.
- Managing terminated members: soft-delete, restore from trash, or permanent removal.

## Default Data Load
- Index: Paginated list (15 per page) of all members with search (by name, email, membership number), filters (membership_type_id, status, member_segment, has_outstanding, is_active). Eager loads: `user`, `membershipType`, `statusMaster`.
- Create: Loads all system users (filterable by type), membership types, status masters, notification channels (Email/SMS/Push/InApp), classes, and languages for dropdowns.
- Edit: Same as create, plus resolves class/section for student-type members.
- Show: Eager loads `user`, `membershipType`, `statusMaster`. Display includes an empty `borrowingHistory` placeholder (to be loaded on demand).
- Trash: Paginated list of soft-deleted members.
- AJAX endpoints: `getUsersByType` (filters users by type/class/section), `getSectionsByClass` (dependent dropdown).

---

## Key Fields at a Glance
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| user_id | INT UNSIGNED | UNIQUE, FK→sys_users | The system user this member is linked to |
| membership_type_id | INT UNSIGNED | FK→lib_membership_types | Membership tier |
| user_type | ENUM('Student','Teacher','Staff') | NOT NULL | Category of member |
| membership_number | VARCHAR(50) | UNIQUE | Auto-generated as `MBR-{uniqid}` on create |
| library_card_barcode | VARCHAR(100) | UNIQUE | Physical/library card barcode |
| registration_date | DATE | required | When membership started |
| expiry_date | DATE | required, after:registration_date | When membership expires |
| status | SMALLINT UNSIGNED | FK→lib_library_status_masters | Current member status |
| is_suspended | TINYINT(1) | DEFAULT 0 | Whether member is currently suspended |
| suspension_reason | TEXT | nullable | Reason for suspension |
| outstanding_fines | DECIMAL(10,2) | DEFAULT 0, CHECK >=0 | Total unpaid fines |
| reading_level | ENUM('Beginner','Intermediate','Advanced','Expert') | nullable | Reading proficiency level |
| preferred_notification_channel | ENUM('Email','SMS','Push','InApp') | DEFAULT 'InApp' | Contact preference |
| member_segment | VARCHAR(50) | nullable | Marketing/engagement segment (e.g., 'High Value', 'At Risk') |
| engagement_score | DECIMAL(5,2) | DEFAULT 0 | Activity engagement metric |
| churn_risk_score | DECIMAL(5,2) | DEFAULT 0 | Predicted churn likelihood |
| lifetime_value | DECIMAL(10,2) | DEFAULT 0 | Total value metric |
| preferred_language | INT UNSIGNED | FK→sys_dropdown_table | Language preference |
| reading_goal_annual | INT | DEFAULT 0 | Annual book reading target |
| reading_progress_ytd | INT | DEFAULT 0 | Books read year-to-date |
| is_active | TINYINT(1) | DEFAULT 1 | Global active flag |

---

## Business Rules and Conditions

### 11 Business Rules (from Lib_Conditions.md Section 4.8)

1. **Ek User = Ek Member:** Har user sirf ek library membership rakh sakta hai. Duplicate nahi ho sakta (`user_id` is UNIQUE). The system checks, "This user is already a library member."

2. **Membership Type:** Har member ki ek type hoti hai (Student/Teacher/Staff etc.) — jo library rules define karti hai (max books, loan period, etc.).

3. **Status:** Member Active, Suspended, Expired, ya Closed ho sakta hai. Sirf Active members ko book issue kar sakte hain.

4. **Expiry Date:** Membership ki expiry date hoti hai. Expired member ko book issue nahi kar sakte. The model provides `isExpired()` helper and `scopeExpired()` for querying members past their expiry date.

5. **Total Books Borrowed (Auto-increment):**
   - ✅ **GAP FIXED (Jun 17):** Pehle ye sirf manual edit ya weekly command se update hota tha.
   - **Ab:** Har book issue pe auto-increment hota hai. Jab bhi koi book borrow karega, count automatically badhega.
   - Dashboard stats aur engagement score calculation mein use hota hai.

6. **Outstanding Fines (Auto-managed):**
   - Member par kitna fine baki hai (`outstanding_fines` DECIMAL(10,2) DEFAULT 0).
   - **Badhta hai jab:**
     - Koi fine create hota hai (overdue, damaged, lost)
     - Book return pe late fee aati hai
     - Book khone par replacement cost lagti hai
   - **Ghatta hai jab:**
     - Fine payment karta hai member
     - Admin fine waive/edit karta hai
     - Fine payment delete hota hai
   - **Issue Blocked:** Agar outstanding fines >= ₹500 hai, to book issue nahi ho sakti.
   - Model helper: `hasOutstandingFines()` checks if `outstanding_fines > 0`.

7. **Total Fines Paid (Auto-increment):**
   - ✅ **GAP FIXED (Jun 17):** Pehle kabhi auto-update nahi hota tha — sirf admin manual edit karta tha.
   - **Ab:** Jab bhi fine payment create hota hai, `total_fines_paid` auto-increment hota hai.

8. **Last Activity Date (Auto-update):**
   - ✅ **GAP FIXED (Jun 17):** Pehle sirf manual edit se set hota tha.
   - **19+ member activities pe ab auto-update hota hai:**
     - Student Portal: book view, search, reserve, renew, digital request, download, view, review, cancel request — sab update
     - Admin: book issue, return, renew, mark lost — sab update
     - Fines: creation aur payment dono update

9. **Language Preference:**
   - Member ki preferred language (e.g., Hindi, English, Gujarati).
   - **Current Issue:** DB mein varchar hai `en/hi/gu` but DDL ke hisaab se FK se linked hona chahiye dropdown se. **TODO:** Migrate karna hai.

10. **Analytics Fields (reading_level, member_segment, engagement_score, etc.):**
    - Ye fields auto-calculated nahi hote — weekly scheduled commands se update hote hain.
    - Ya admin manual edit kar sakta hai.
    - `engagement_score`, `churn_risk_score`, and `lifetime_value` are calculated externally and updated periodically.

11. **Auto Renew Card:** Agar `is_icard_auto_renew = 1` hai to library card expiry par auto-renew ho jayega.

---

### Additional Business Rules (Existing)

1. **Unique User:** Each system user can have only one library membership (`user_id` is UNIQUE). The system checks, "This user is already a library member."
2. **Auto-Generated Membership Number:** If not provided, the model's `boot()` generates `MBR-{strtoupper(uniqid())}` (e.g., `MBR-67F3A2C1B0`).
3. **Unique Barcode:** `library_card_barcode` must be unique across all members.
4. **Transaction Protection — Delete:** Before soft-deleting a member, the system blocks if the member has issued or overdue transactions. Pending reservations are cancelled.
5. **Restore Resets Active Flag:** Restoring a member sets `is_active = true`.
6. **Suspension Rules:**
   - A member cannot be deactivated if they have issued books.
   - A duplicate suspension request is rejected (cannot suspend an already-suspended member).
   - Suspension requires a reason (`suspension_reason`).
7. **Expiry:** The model provides `isExpired()` helper and `scopeExpired()` for querying members past their expiry date.
8. **Outstanding Fines:** `hasOutstandingFines()` helper checks if `outstanding_fines > 0`.
9. **Accounting Integration:** On member creation, `RemoteEntryService::processEvent()` is fired for accounting journal entry generation.
10. **Financial Metrics:** `engagement_score`, `churn_risk_score`, and `lifetime_value` are calculated externally and updated periodically.

---

## Workflow Steps
1. **Register Member:** Admin opens Create → selects system user → sets membership type, user type, membership number (auto-generated), barcode, registration/expiry dates, preferred notification channel, language, reading goal → saves. Accounting event fires automatically.
2. **View Profile:** Admin clicks Show → sees member details, borrowing history (placeholder), fines, and engagement metrics.
3. **Edit Member:** Admin updates membership type, barcode, expiry date, notification preferences, reading level, etc.
4. **Search/Filter:** Admin searches by name/email/membership number or filters by type, status, segment, or outstanding fines.
5. **Change Status:** Admin clicks the status update button → selects new status → optionally provides suspension reason → system validates business rules → updates.
6. **Toggle Active:** AJAX toggle flips `is_active`. Blocked if user has issued books.
7. **Delete:** Admin deletes → system checks for issued/overdue transactions → cancels pending reservations → soft-deletes with `is_active = false`.
8. **Trash View:** Admin views soft-deleted members.
9. **Restore:** Admin restores → `deleted_at` cleared, `is_active` set to true.
10. **Force Delete:** Admin permanently removes → FK constraint caught if referenced.

---

## Example Scenario
**Registering a new Student member:**
1. Admin clicks "Add Member."
2. System loads: users list (filtered by Student type), membership types (e.g., "Student Standard"), statuses (e.g., "Active"), classes, sections, languages.
3. Admin selects user "Rahul Sharma" (Student, Class 10, Section A).
4. Admin chooses membership type "Student Standard," sets registration date to today, expiry to 1 year later.
5. Member number auto-generates as `MBR-67F3A2C1B0`. Admin scans library card to populate barcode.
6. Admin sets notification channel to "SMS," language to "Hindi," reading goal to 20 books/year.
7. System saves, fires accounting event for membership fee, and redirects to member list.

---

## Related Screens
- **Membership Types** — Defines the tiers available for selection.
- **Library Status Masters** — Defines the status values used by `status` field.
- **Fine Management** — Members' outstanding fines are tracked here.
- **Borrowing/Transactions** — Members' borrowing history loaded on Show page.
- **System Users (sys_users)** — Each member is linked to a system user account.
- **Accounting Module** — New member registrations generate accounting entries via `RemoteEntryService`.

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibMemberController` (422 lines, 15 methods):
  - `index`: Filters (search, membership_type_id, status, segment, has_outstanding, is_active). Paginate 15. Eager load `user`, `membershipType`, `statusMaster`.
  - `create`: Loads users, membershipTypes, statuses, notificationChannels, classes, languages.
  - `store`: DB transaction, validates user is active, fires `RemoteEntryService::processEvent()`.
  - `show`: Eager loads user, membershipType, statusMaster. Empty borrowingHistory.
  - `edit`: Same as create + resolves class/section for students.
  - `update`: DB transaction.
  - `destroy`: Blocks if issued/overdue transactions, cancels pending reservations, sets `is_active=false`, soft deletes.
  - `trashed`: Paginated trashed members.
  - `restore`: Sets `is_active=true`.
  - `forceDelete`: Catches FK 23000 (integrity constraint violation).
  - `toggleStatus`: AJAX JSON, uses `'tenant.lib-members.status'` permission (NOT in $crud — possible bug).
  - `updateStatus`: **NO Gate::authorize!** Validates status + suspension_reason. Prevents deactivation if issued books. Prevents duplicate suspension. Returns JSON.
  - `getUsersByType`: AJAX, filters users by type/class/section. No gate.
  - `getSectionsByClass`: AJAX, dependent dropdown. No gate.
- **Model:** `LibMember` — table `lib_members`, uses `SoftDeletes`. Boot: auto-generates `membership_number` as `'MBR-'.strtoupper(uniqid())` if empty. 30 fillable fields. Relationships: `user` (belongsTo User), `membershipType` (belongsTo), `statusMaster` (belongsTo LibLibraryStatusMaster), `transactions`, `digitalAccessTransactions`, `reviews`, `wishlistItems`. Scopes: `active()`, `expired()`. Helpers: `isExpired()`, `hasOutstandingFines()`.
- **Validation (LibMemberRequest, 105 lines):**
  - `prepareForValidation`: Converts `preferred_language` string → dropdown id, normalizes booleans.
  - Create rules: `user_id` => required|exists:sys_users,id|unique:lib_members,user_id; `membership_type_id` => required|exists:lib_membership_types,id; `user_type` => required|in:Student,Teacher,Staff; `membership_number` => required|string|max:50|unique:lib_members,membership_number; `library_card_barcode` => required|string|max:100|unique:lib_members,library_card_barcode; `registration_date` => required|date; `expiry_date` => required|date|after:registration_date; `status` => required|exists:lib_library_status_masters,id; `preferred_language` => required|exists:sys_dropdown_table,id; plus 15 optional fields.
  - Update rules: Same but `user_id`/`membership_number`/`barcode` unique-with-ignore.
  - Custom messages: `user_id.unique` = "already a library member".
  - After validation hook: checks `user.is_active`.
- **ActivityLog:** ⚠️ **NOT called anywhere** in the controller — this is a known gap. Must be added to `store`, `update`, `destroy`, `restore`, `forceDelete`.
- **Policy:** `tenant.lib-members.*` (bypassed by string-based `Gate::authorize` calls).

### Known Issues Found in Code Review
1. **`activityLog` not called** — Missing from all mutation methods (store, update, destroy, restore, forceDelete). Must add.
2. **`updateStatus` has NO `Gate::authorize`** — Anyone who can reach this endpoint can change member status without permission check.
3. **`toggleStatus` uses wrong permission** — Uses `'tenant.lib-members.status'` which is NOT defined in `$crud` within `permissionslist.php`. Should use `'tenant.lib-members.update'`.
4. **Show view references `$member->last_segment_calculation`** — This field does not exist on the model or DDL. Probable typo/removed field.
5. **Show view references `$member->is_auto_renew`** — Wrong field name. The correct field is `is_icard_auto_renew`.

---

## Who Can Access This Screen
- Users with `tenant.lib-members.viewAny` — list/index tab visibility.
- Users with `tenant.lib-members.create` — add button and store.
- Users with `tenant.lib-members.view` — show/details page.
- Users with `tenant.lib-members.update` — edit, update, toggleStatus, updateStatus (should be gated).
- Users with `tenant.lib-members.delete` — soft delete.
- Users with `tenant.lib-members.restore` — trash view and restore.
- Users with `tenant.lib-members.forceDelete` — permanent delete.
- ⚠️ `getUsersByType` and `getSectionsByClass` are AJAX endpoints with no gate — used for dependent dropdowns (low risk, but should at minimum have auth check).

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User opens the Members screen. The system loads all members and shows them in a table (15 per page). Each row shows the member's name (linked to system user), membership type, status badge, outstanding fines, and action buttons.
2. The user can search by name/email/membership number or filter by membership type, status, segment, members with outstanding fines, or active/inactive status.
3. Clicking "Add Member" opens a registration form. The user selects an existing system user, sets the member type (Student/Teacher/Staff), chooses a membership tier, sets dates, and configures preferences.
4. When saving, the system auto-generates a membership number if not provided, validates that the user isn't already a member, and creates the record. An accounting event is sent to the finance system.
5. Clicking a member's name opens their profile page, showing personal details, membership info, engagement metrics, and a placeholder for borrowing history.
6. The user can edit member details, update their status (including suspending with a reason), toggle active status, or delete.
7. Deleting is blocked if the member has books still issued or overdue. Pending reservations are automatically cancelled before deletion.
8. Deleted members go to the trash where they can be restored or permanently removed.

---

## Validate Before Save
1. `user_id` is required, must exist in `sys_users`, must be unique in `lib_members` (not already a member). The system user must be active.
2. `membership_type_id` is required, must exist in `lib_membership_types`.
3. `user_type` is required, must be one of: Student, Teacher, Staff.
4. `membership_number` is required, must be unique, ≤50 characters.
5. `library_card_barcode` is required, must be unique, ≤100 characters.
6. `registration_date` is required, must be a valid date.
7. `expiry_date` is required, must be a valid date after `registration_date`.
8. `status` is required, must exist in `lib_library_status_masters`.
9. `preferred_language` is required, must exist in `sys_dropdown_table`.
10. `is_icard_auto_renew`, `is_suspended`, `is_active` are boolean flags.
11. `outstanding_fines` must be ≥ 0 if provided.
12. `reading_level` must be one of: Beginner, Intermediate, Advanced, Expert (if provided).
13. `preferred_notification_channel` must be one of: Email, SMS, Push, InApp (if provided).
14. On update: `user_id`/`membership_number`/`barcode` unique checks exclude the current record.

---

## Error Handling and Validation Messages
| Condition | Message |
|-----------|---------|
| User already a member | "{user name} is already a library member." (custom: `user_id.unique`) |
| User not found | "The selected user id is invalid." |
| User inactive | "The selected user is not active." (after-validation hook) |
| Membership number duplicate | "The membership number has already been taken." |
| Barcode duplicate | "The library card barcode has already been taken." |
| Expiry before registration | "The expiry date must be a date after registration date." |
| Delete with issued books | "Cannot delete member with issued or overdue transactions." |
| Deactivate with issued books | "Cannot deactivate member with issued books." |
| Duplicate suspension | "Member is already suspended." |
| Suspension missing reason | "Suspension reason is required." (when `is_suspended` = true) |

---

## Success Scenarios
1. **Create:** New member registered. Accounting event fired. Redirect to list with success.
2. **Update:** Modified details saved. Redirect to list with success.
3. **Show:** Member profile displayed with all details and empty borrowing history placeholder.
4. **Status Update:** Status changed via `updateStatus`. Returns JSON `{success: true}`.
5. **Toggle Active:** AJAX toggles `is_active`. Returns `{success: true, is_active: bool}`.
6. **Soft Delete:** Validated no issued books → pending reservations cancelled → soft-deleted. Redirect with success.
7. **Restore:** Record restored with `is_active=true`. Success message.
8. **Force Delete:** Record permanently removed (or FK caught if referenced). Success message.

---

## Failure Scenarios
1. **Create with duplicate user:** Validation fails, "already a library member."
2. **Create with inactive user:** After-validation hook fails, "The selected user is not active."
3. **Delete a member with active borrowings:** Blocked. "Cannot delete member with issued or overdue transactions."
4. **Suspend an already-suspended member:** "Member is already suspended."
5. **Deactivate a member with issued books:** "Cannot deactivate member with issued books."
6. **Force delete a member with transactions:** FK 23000 constraint violation caught. Flash error.
7. **AJAX getUsersByType with invalid type:** Returns empty list, no error.
8. **updateStatus without permission:** ⚠️ Currently no gate — unauthorized access can change member status.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_members` | Table | Primary table for this feature |
| `sys_users` | Table | FK `user_id` references system users |
| `lib_membership_types` | Table | FK `membership_type_id` references membership tiers |
| `lib_library_status_masters` | Table | FK `status` references status definitions |
| `sys_dropdown_table` | Table | FK `preferred_language` references language dropdown |
| `lib_transactions` | Table | Checked during delete for issued/overdue items |
| `lib_reservations` | Table | Pending reservations cancelled on member delete |
| Accounting Module | Module | `RemoteEntryService::processEvent()` fired on member create |
| `lib-members` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibMemberPolicy` | Policy | Authorization policy mapped to `tenant.lib-members.*` |
