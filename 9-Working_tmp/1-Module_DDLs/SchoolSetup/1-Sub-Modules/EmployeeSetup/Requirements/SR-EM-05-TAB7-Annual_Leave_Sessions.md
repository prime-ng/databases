# Screen Requirement: Annual Leave Sessions (Deep Requirements)
## Document ID: SR-EM-05-TAB7
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Configuration > Annual Leave Sessions (Tab 7)  
**Route:** `school-setup.leave-config?tab=annual-leave-sessions`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview & Business Purpose

### 1.1 Purpose
This screen defines **annual sessions** for leave tracking. A session is a **time period** (typically 12 months) within which leave balances are calculated, consumed, and carried forward. Sessions can follow either a **calendar year** (Jan–Dec) or an **academic year** (Apr–Mar or any custom period).

### 1.2 Business Context
Schools need flexibility in defining leave periods:
- **Calendar Year (Jan–Dec):** Used by corporate-style schools or for admin staff
- **Academic Year (Apr–Mar):** Used by most Indian schools aligning with the academic session
- **Custom Period:** Some schools use July–June, Oct–Sep, etc.

The active session determines:
- Which leave year applies to new applications
- Which holidays are relevant
- When year-end rollover occurs
- How balances are calculated

### 1.3 Key Concepts
- **Session = Balance Period:** Every leave balance record references a session
- **Active Session:** Determines the "current" leave period for new applications
- **Session Rollover:** When a session ends, balances roll over (carry-forward) to the next session
- **Holiday Association:** Holidays are linked to sessions (which year's holidays apply)

---

## 2. Complete Field Definitions (Deep Detail)

### 2.1 `name` (Session Name)
- **Type:** VARCHAR(100), Required, UNIQUE
- **Meaning:** A human-readable name for the session that uniquely identifies it.
- **Convention Examples:**
  - "2026 Calendar Year" — For Jan–Dec sessions
  - "2026-27 Academic Year" — For Apr–Mar sessions
  - "2026-27 Session" — For custom periods
- **Validation:**
  - Required, max 100 characters
  - Must be UNIQUE across all sessions (enforced at database level: `UNIQUE KEY uq_session_name`)
  - Should be descriptive enough to distinguish from other sessions
- **UI:** Primary display field in all dropdowns and lists

### 2.2 `start_date` (Session Start)
- **Type:** DATE, Required
- **Meaning:** The **first date** of the leave session. Leave balances for this session are effective from this date.
- **Business Logic:**
  - Leave applications with `from_date >= start_date AND from_date <= end_date` belong to this session
  - If today is between `start_date` and `end_date`, AND this session is active: this session is the "current" session
  - Carry-forward is calculated from the most recent completed session
- **Validation:**
  - Required, valid date
  - Must be before `end_date`
  - Should not overlap with other sessions (soft warning, not hard block)

### 2.3 `end_date` (Session End)
- **Type:** DATE, Required
- **Meaning:** The **last date** of the leave session. After this date, the session is considered "ended" and rollover can be triggered.
- **Business Logic:**
  - Applications with `from_date > end_date` belong to the NEXT session
  - After `end_date` passes AND rollover is done, this session becomes "historical"
  - Employees can still view old balances but cannot apply leave against an ended session
- **Validation:**
  - Required, valid date
  - Must be after `start_date`

### 2.4 `description` (Session Description)
- **Type:** VARCHAR(255), Optional
- **Meaning:** Free-text notes about this session — its purpose, special rules, or any administrative notes.
- **Usage:** Shown as tooltip or info on the leave application screen

### 2.5 `is_active` (Active Flag)
- **Type:** TINYINT(1), Boolean, Default = 1
- **Meaning:** Marks this session as the **current active session** for leave processing.
- **Critical Business Logic:**
  ```
  WHEN a leave application is submitted:
      active_session = session WHERE is_active = 1 AND deleted_at IS NULL
      
      IF no active session found:
          → Error: "No active leave session configured"
          → Block leave application submission
      
      IF one active session found:
          → Use this session for leave processing
      
      IF multiple active sessions:
          → Resolution Strategy 1: Use the session where today is between start and end
          → Resolution Strategy 2: Use the most recently created active session
          → Should warn admin: "Multiple active sessions detected"
  ```
- **UI Behavior:** Toggle button to activate/deactivate. Setting a new session active should prompt about the previous session.

### 2.6 Audit Fields
- `created_by`: INT UNSIGNED, FK → sys_users.id
- `created_at`: TIMESTAMP, Default = CURRENT_TIMESTAMP
- `updated_at`: TIMESTAMP, Auto-updates on change
- `deleted_at`: TIMESTAMP, Nullable — Soft delete

---

## 3. Session Lifecycle (Deep Detail)

### 3.1 Session Creation
```
1. Admin creates a new session
    - Name, Start Date, End Date, Description, is_active

2. On creation:
    - If is_active = true:
        → Check for existing active session
        → If another session is active:
            → Warn: "Another session ({name}) is already active. 
                      Activating this session will require deactivating the other."
    
    - Balance seeding does NOT happen on session creation
    - Balance seeding happens when employees are created or via bulk-sync
```

### 3.2 Session Activation
```
When setting a session as active (is_active = true):

Pre-condition:
    Check: Is there already an active session?
    
    If YES:
        → Warn: "Session '{existing_name}' is currently active. 
                  Deactivate it first or both sessions will be active."
        → Allow activation anyway (flexibility for overlapping sessions)
        → But show warning banner on leave screens: "Multiple active sessions"

Post-action:
    - This session becomes the "current" session for all new leave applications
    - Existing pending applications remain in their original session
```

### 3.3 Session End & Rollover Trigger
```
When a session's end_date has passed:

Option A: Manual Rollover (Recommended)
    Admin clicks "Rollover to Next Session"
    System: ProcessDailyLeaveRollover
    
Option B: Scheduled Rollover (Cron Job)
    leave:rollover command checks sessions where:
        - end_date < today
        - AND state != 'rolled_over'
    Processes them automatically

Rollover Process (handled by LeaveRolloverService):
    1. Identify source session (ended) and target session (next active)
    2. For each employee with balances in source session:
        a. Get available balance
        b. Calculate carry_forward per leave type (using config)
        c. Create balance rows in target session
        d. Mark source session as 'rolled_over'

Note: Ideally add a status field like 'rollover_status' to track this
(currently not in DDL, handled by application logic or additional sessions)
```

### 3.4 Session Deletion Prevention
```
BEFORE deleting a session:
    CHECK 1: Are there employee leave balances referencing this session?
        → BLOCK deletion: "Cannot delete session — {count} employee(s) have 
                           leave balance records for this session."
    
    CHECK 2: Are there holidays referencing this session via annual_leave_sessions_id?
        → CASCADE: Holidays associated with this session will be deleted too
        → WARN: "{count} holiday(s) associated with this session will be deleted."
    
    CHECK 3: Are there leave applications in this session?
        → BLOCK deletion: "Cannot delete session with active leave applications."

Resolution for deletion:
    - Instead of deleting, deactivate (set is_active = false)
    - This preserves historical data while preventing new usage
```

---

## 4. Validation Rules Matrix

### 4.1 Field Validations

| Field | Required | Constraints |
|-------|----------|-------------|
| name | Yes | Unique, max 100 chars, non-empty |
| start_date | Yes | Valid DATE format (YYYY-MM-DD) |
| end_date | Yes | Valid DATE, must be after start_date |
| description | No | Max 255 chars |
| is_active | Yes | Boolean, default true |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| end_date < start_date | Error | "End date must be after start date" |
| start_date = end_date | Error | "Session must span at least one day" |
| name = existing name | Error | "Session name already exists" |
| Date overlap with existing session | Warning | "Session dates overlap with '{existing_name}' ({start} to {end})" |
| Multiple sessions active | Warning | "Multiple sessions are active. Only one should be active at a time." |
| Session duration < 1 month | Warning | "Session is very short. Leave sessions are typically 12 months." |
| Session duration > 18 months | Warning | "Session is very long. Standard sessions are 12 months." |

### 4.3 Overlap Detection Logic

```
When creating/updating a session, check for date overlap:

OVerlap exists if:
    (new_start BETWEEN existing_start AND existing_end)
    OR (new_end BETWEEN existing_start AND existing_end)
    OR (existing_start BETWEEN new_start AND new_end)

This detects:
    - New session starts inside existing (partial overlap)
    - New session ends inside existing (partial overlap)
    - New session completely contains existing (full overlap)
    - New session is completely inside existing (contained)

Allowed but warns: Some schools run overlapping sessions intentionally
(e.g., calendar year + academic year)
```

---

## 5. Business Rules

### Rule 1: Session Uniqueness
```
Session name must be unique across ALL sessions (past, present, future).
This prevents confusion when referencing sessions in reports.
```

### Rule 2: Date Order
```
start_date MUST be before end_date. A zero-length session is not allowed.
```

### Rule 3: Session Overlap Tolerance
```
Overlapping sessions are ALLOWED but with a warning.
Use case: School runs Fiscal Year (Apr-Mar) and Calendar Year (Jan-Dec) simultaneously.
When resolving active session, use the one where today is between start and end.
```

### Rule 4: Active Session Resolution
```
When multiple sessions could apply (overlap), the resolution logic is:

PRIORITY 1: Session where TODAY is between start_date AND end_date
    → If exactly one: USE it
    
PRIORITY 2: If multiple sessions contain today:
    → Use the one with is_active = true
    → If still multiple: Use the most recently created (highest ID)
    → Log warning for admin
    
PRIORITY 3: If NO session contains today:
    → Use the session with is_active = true
    → If none active: Error
```

### Rule 5: Delete Protection
```
A session CANNOT be deleted if:
    - Employee leave balances reference it
    - Leave applications reference it
    
These records must be deleted first (or session deactivated instead).
```

### Rule 6: Holiday Cascade
```
When a session is deleted, ALL holidays (sch_holidays) linked to it
via annual_leave_sessions_id are cascade-deleted.
```

### Rule 7: Session Non-Editable After Rollover
```
Once a session has been rolled over (carry-forward processed):
    - Core fields (start_date, end_date) should be locked
    - is_active can still be toggled
    - description can be updated
```

---

## 6. Session Types & Examples

### 6.1 Calendar Year Session
```
Name: "2026 Calendar Year"
Start: 2026-01-01
End: 2026-12-31
Type: Standard calendar year
Use: Corporate-style leave tracking, admin staff
Active: January-December
```

### 6.2 Academic Year Session (April-March)
```
Name: "2026-27 Academic Year"
Start: 2026-04-01
End: 2027-03-31
Type: Indian academic year
Use: Most Indian K-12 schools
Active: April-March
```

### 6.3 Academic Year Session (July-June)
```
Name: "2026-27 Session"
Start: 2026-07-01
End: 2027-06-30
Type: International school academic year
Use: International schools following Western academic calendar
Active: July-June
```

### 6.4 Overlapping Sessions Example
```
Session A: "2026 Calendar Year" (2026-01-01 to 2026-12-31)
Session B: "2026-27 Academic Year" (2026-04-01 to 2027-03-31)

Overlap: 2026-04-01 to 2026-12-31 (9 months overlap)

When today = 2026-06-15:
    Session A contains today? YES
    Session B contains today? YES
    Both active? YES
    
Resolution:
    Use the session with is_active = true that most recently activated
    OR use a specific business rule (e.g., "academic year takes precedence during school months")
```

---

## 7. Session-Related Operations

### 7.1 Holiday Association
```
Holidays (sch_holidays) are linked to sessions:
    sch_holidays.annual_leave_sessions_id  →  sch_annual_leave_sessions.id
    
When calculating total_days for a leave application:
    holidays_in_range = count of holidays in the date range
                        WHERE annual_leave_sessions_id = active_session.id
    
    working_days = (total_calendar_days - weekends - holidays_in_range)
    For half-day: working_days = 0.5
```

### 7.2 Balance Seeding on Session Change
```
When a new session is created AND set to active:
    Should we auto-seed balances for all employees?
    
    Current design: Balance seeding happens:
    1. On employee creation (joined mid-session)
    2. On rollover from previous session
    3. Via manual bulk-sync
    
    NOT automatically on session creation alone.
    Because: The new session might not be the "next" session.
    Rollover from the ENDED session to the new session handles seeding.
```

### 7.3 Default Session Selection
```
When HR/admin enters the Leave Configuration screen:
    - Session dropdown auto-selects:
        1. Active session (is_active = true)
        2. If multiple active: session containing today
        3. If none: most recent session
```

---



## Related Documents
- [SR-EM-05-TAB6](./SR-EM-05-TAB6-Employee_Leave_Balance.md) — Balance tracking per session
- [SR-EM-04-TAB2](./SR-EM-04-TAB2-Holiday_Calendar.md) — Holiday calendar linked to sessions
- [SR-EM-05](./SR-EM-05-Leave_Configuration.md) — Leave Configuration module overview
