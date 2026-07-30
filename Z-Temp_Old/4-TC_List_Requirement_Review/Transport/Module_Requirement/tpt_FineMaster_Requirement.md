# Fine Master — Business Requirements

## What This Screen Does

Fine Master defines the actual fine calculation rules. For each Fine Category + Academic Session combination, rules define a day range (e.g., 1-5 days late), a fine type (Fixed ₹ amount or Percentage), a fine rate, and whether the student should be restricted from bus services if this rule applies.

Without Fine Master, the system could categorise infractions (via Fine Category) but would have no mechanism to translate them into actual financial penalties. Late fee collection would be manual, inconsistent, and unaccountable — one clerk charging ₹200 while another charges ₹500 for the same number of days late. Fine Master removes human discretion from fine calculation and ensures every parent is charged the same penalty for the same transgression.

The screen appears in two contexts:
1. **Transport Master → Fine Master tab** — Paginated list, 20 per page.
2. **Standalone CRUD** — Via `FineMasterController` (178 lines).

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Fine Master tab, the system immediately loads the most recently created fine rules and displays them in a list — 20 rules per page. There is no search box or filter dropdown, which means if the school has set up 80 fine rules over multiple years, the manager has to click through four pages to find a specific rule. The list shows every rule for every category and every academic session all mixed together, with no way to narrow down by category name or day range.

Currently, the system does not check whether the person viewing this screen should actually have permission to see it. Any user who can access the Transport Master tab will see the fine rules listed — there is no access restriction at this initial screen level.

---

## When This Screen Is Used

- **Setting Up Late Fee Rules at the Start of the Academic Year** — Every April, when the new academic session begins, the Transport Manager must recreate all fine rules from scratch. The system does not allow copying rules from the previous year — each year's late fee slabs must be entered manually, one by one. Mrs. Desai, the Transport Manager at Green Valley School, sits down with the Finance team in the first week of April to decide the late fee structure for the new session: how many days of grace period, how much to charge per slab, and at what point a student should be restricted from boarding the bus.

- **Adjusting Fine Rates Mid-Year** — In October, the school's management decides that the existing late fee of ₹200 for the first 5 days is too low — parents are not taking payment deadlines seriously. Mrs. Desai opens Fine Master, finds the rule for 1-5 days, and increases the fine from ₹200 to ₹350. The change takes effect immediately for all future late fee calculations. Any student who is already overdue continues to be charged under the old rule that was in effect when their fee became late — the system does not retroactively apply the new rate.

- **Reviewing Current Fine Rules Before a Fee Recovery Drive** — Every quarter, the Finance department launches a fee recovery drive targeting parents whose transport fees are overdue. Before the drive begins, the Accounts Officer opens Fine Master to review which fine slabs are currently active, what the penalty amounts are, and which students are flagged for bus service restriction. This review ensures that the notices sent to parents reflect the correct fine amounts.

- **Investigating a Parent's Dispute About a Fine Amount** — A parent calls the school office claiming they were charged ₹1,000 for being 12 days late, when according to their calculation the fine should have been only ₹500. Mrs. Desai opens Fine Master to verify the slab that applies to the 6-15 day range. She confirms that the rule is set to ₹500 fixed, not ₹1,000 — the issue was a data entry error where the clerk selected the wrong fine category when recording the payment. The correct fine is applied after the category is corrected.

---

## Key Fields at a Glance

**Rule Definition and Scope**
Each fine rule belongs to one fine category (e.g., "Transport Late Fee") and one academic session. The academic session is not user-selectable — it is automatically assigned from the current active session when the rule is created or updated. This prevents a rule intended for the 2024-25 session from inadvertently applying to previous years' data. The day range (`fine_from_days` and `fine_to_days`) defines the window of late payment — for example, 1 to 5 days means the rule applies when a student's fee is 1 to 5 days overdue.

**Fine Calculation Method**
The rule defines how the fine amount is calculated: either a Fixed flat amount (e.g., ₹200 regardless of the fee total) or a Percentage of the outstanding fee amount (e.g., 5% of a ₹10,000 fee = ₹500). The `fine_rate` field stores either the rupee amount (if Fixed) or the percentage value (if Percentage). A note field allows the manager to record the rationale for the rule, such as "First time waiver — no penalty."

**Student Restriction Flag**
When `student_restricted` is enabled, the student is theoretically blocked from boarding the bus until the fine is paid. However, the codebase currently does not enforce this restriction anywhere in the trip generation, boarding, or attendance logic — the flag exists as a data field but has no consumption point. This means the restriction is advisory rather than enforceable until the downstream trip/boarding logic is updated to check it.

---

## Business Rules and Conditions

**Current Session Is Auto-Assigned — Not User-Selectable**
Both `store()` and `update()` override any session the user submits and automatically assign `std_academic_sessions_id` from `AcademicSession::where('is_current', 1)->first()`. This is intentional — fine rules should only apply to the current academic year, and allowing manual session selection could lead to rules being accidentally applied to past or future sessions. However, it also means that when a new academic session becomes current, all fine rules must be recreated; they cannot be bulk-copied from the previous year.

**Day Range Overlap — No Validation (GAP)**
Within a single fine category and academic session, the day ranges are expected to be mutually exclusive: 1-5 days, 6-15 days, 16-30 days. However, there is no validation preventing overlaps. A user could create a rule for 1-10 days and another for 5-20 days for the same category, and the system would save both without complaint. When the fee engine calculates penalties, it would find two matching rules and have no way to choose between them — the result depends on which record the query returns first.

**Student Restriction Flag Is Declared But Not Enforced (GAP)**
The `student_restricted` flag is designed to block a student from boarding the bus when a fine is unpaid. However, the actual enforcement would need to happen during trip generation (the system should exclude restricted students from the vehicle manifest) or at boarding time (the driver's app should show an alert). Neither of these enforcement points currently exists in the codebase. The flag is stored but has zero downstream consequences.

**Missing `updated_at` Column in DDL — Will Cause SQL Error (GAP)**
The `tpt_fine_master` DDL defines `created_at` and `deleted_at` columns but omits `updated_at`. Laravel's Eloquent ORM automatically sets `updated_at` on every record update via the model's `timestamps` feature (inherited from `BaseModel`). When `store()` or `update()` runs, SQL will attempt to write to the missing column and throw a database error. This means the edit feature is functionally broken for FineMaster — every update will fail with an SQL exception.

---

## Workflow Steps

**Creating Slab-wise Late Fee Rules for the New Academic Year**
It is April 5th and the new academic session 2025-26 has just begun. Mrs. Desai opens Fine Master and clicks the Add button. The system presents her with a blank form. She selects "Transport Late Fee" as the fine category — this is the category the Finance team uses for all transport-related penalties. She enters the first day range: from day 1 to day 5, meaning this rule applies to any student whose fee is 1 to 5 days overdue. She selects "Fixed" as the fine type and enters ₹200 as the rate. She leaves the student restriction toggle set to "No" — the school management has decided that students in the first 5 days of delay should not be denied bus service. She clicks Save. The system logs the activity and the rule appears in the list.

Mrs. Desai repeats the process for the second slab: 6 to 15 days, ₹500 fixed rate, but this time she switches the student restriction toggle to "Yes" — any student whose fee remains unpaid beyond 5 days will be flagged for bus service restriction. She adds a third slab: 16 to 30 days, ₹1,000 fixed rate, student restricted to "Yes." She adds a fourth slab for extreme cases: 31 to 60 days, 10% of the outstanding fee amount (Percentage type), student restricted to "Yes." All four rules are now live and the system will use them to calculate fines for any overdue transport fees during the 2025-26 session.

**Adjusting a Mid-Year Fine Rate After Management Review**
In September, the school's management reviews the late fee collection data and notices that 40% of parents are paying fees exactly on day 6 — the first day of the higher ₹500 slab. They believe the jump from ₹200 to ₹500 is too steep and is causing disputes. Mrs. Desai opens Fine Master and clicks Edit on the 6-15 day rule. She changes the rate from ₹500 to ₹350 and notes in the Remark field: "Rate reduced per management decision dated 15-Sep-2025." The system logs the change: "Fine rate changed from 500.00 to 350.00 for rule ID 12." Parents who are currently in the 6-15 day overdue window will still be charged the old rate that was in effect when their fee first became late — the change applies only to new overdue cases going forward.

**Removing an Obsolete Fine Rule**
At the end of the academic year in March, Mrs. Desai reviews the fine rules list and notices that the 31-60 day slab (10% of outstanding amount) has never been used — no student has ever gone past 30 days without paying. She clicks Delete on this rule. The system asks for confirmation, and upon confirmation, it archives the rule — it hides it from the active list but keeps it in the Trash in case the school needs to refer to it later. If Mrs. Desai is certain the rule will never be needed again, she can permanently delete it from the Trash, which removes it from the database entirely.

---

## Example Scenario

Green Valley School has set up the following late fee rules for the 2025-26 academic session through the Fine Master screen:

| Days Late | Fine Amount | Student Restricted? |
|-----------|-------------|-------------------|
| 1 to 5 days | ₹200 (Fixed) | No — student can board the bus |
| 6 to 15 days | ₹500 (Fixed) | Yes — student is flagged for restriction |
| 16 to 30 days | ₹1,000 (Fixed) | Yes — student is flagged for restriction |
| 31 to 60 days | 10% of outstanding fee (Percentage) | Yes — student is flagged for restriction |

On September 15th, Aarav Sharma's transport fee of ₹8,000 for the term falls due. Aarav's parents are travelling and forget to make the payment. By September 25th, Aarav's fee is 10 days overdue.

On the morning of September 26th, the system processes the late fee calculation. It checks the days overdue (10 days) and looks up the Fine Master rules for the Transport Late Fee category. It finds that 10 days falls within the 6-15 day slab, so it applies Rule #2: a fixed fine of ₹500. Since the student restriction flag is set to "Yes" for this rule, Aarav's name is flagged in the system. However, because the downstream enforcement logic (trip assignment, driver's boarding app) does not yet check this flag, Aarav continues to board the bus as usual — the restriction is recorded but not enforced.

When Aarav's father finally makes the payment on September 28th (online via the parent portal), the system shows: Outstanding Fee ₹8,000 + Late Fine ₹500 = Total ₹8,500. The payment receipt clearly breaks down the base fee and the fine separately so the parent can see what they are being charged for.

---

## Related Screens

- **Fine Category** — The categories that these fine rules reference.

---

## Requirements

- Controller: `FineMasterController` — index, create, store, show, edit, update, destroy, trashed, restore, forceDelete (no toggleStatus)
- Model: `TptFineMaster` (53 lines) — `tpt_fine_master` table, SoftDeletes, belongsTo `academicSession`, `fineCategory`
- Form request: `FineMasterRequest`
- Activity logging: ✅ Created, Updated, Deleted, Restored, Force Deleted

---

## Who Can Access

- **Transport Manager** — Has full control over fine rules. Mrs. Desai can create new fine slabs at the start of the academic year, edit existing rules (change day ranges, adjust fine rates, toggle student restriction), delete obsolete rules, and permanently remove test entries. This is the primary user who works with this screen on a regular basis — at least once per term for rule setup and mid-year adjustments.

- **Finance Manager / Accounts Officer** — Can view all fine rules and see the complete list of active slabs. They can also create and edit rules, since fine rates directly impact fee collection. However, they cannot delete or permanently remove any rule — that authority is reserved for the Transport Manager. This prevents accidental removal of rules that could break the fee calculation engine.

- **School Administrator** — Has view-only access to the fine rules list. They can see what slabs are active, check fine rates, and review which student restriction flags are set, but they cannot create, edit, or delete any rules.

- **Clerk / Data Entry Operator** — Does not have access to this screen. Clerks process fee payments through the Fee Collection screen and do not need to see or modify fine rule definitions.

Behind the scenes, each action is checked against a permission. However, the main list screen (called the index) and the trash view (called trashed) currently do not check permissions — meaning a clerk who somehow navigates to the Fine Master tab could see the complete list of fine rules even though they should not have access.

---

## Logic Flow

When the Transport Manager opens the Fine Master tab, the system reaches into the database and pulls out every fine rule that has ever been created — for all categories and all academic sessions — and arranges them with the most recently created rule appearing first. It shows 20 rules per page. If the school has been using the system for three years with 20 rules per year, the manager would see 60 rules spread across three pages with no way to filter by category or session. The system also does not check whether the person viewing this screen is authorised to see fine rules — anyone who can access the Transport Master tab can see the complete list.

When the manager clicks the Add button to create a new rule, the system presents a blank form. The manager selects a fine category (for example, "Transport Late Fee"), enters the starting day and ending day of the range (for example, from day 1 to day 5), chooses whether the fine is a fixed rupee amount or a percentage of the outstanding fee, enters the rate, and decides whether students falling under this rule should be restricted from bus services. When the manager clicks Save, the system first checks that all required fields are filled in and that the "to day" is greater than or equal to the "from day." Critically, the system does NOT check whether the day range overlaps with any existing rule for the same category — if the manager accidentally creates a rule for 1-10 days when a 1-5 day rule already exists, both rules are saved without any warning. The system also automatically assigns the current academic session to the rule, ignoring whatever session the manager may have selected in the form — this is intentional to prevent rules meant for the current year from accidentally applying to past years.

When the manager edits an existing rule, the form loads with the current values pre-filled. The manager can change any field except the academic session, which remains locked to the current year. When saving, the system tries to update the rule in the database. However, there is a critical flaw: the database table is missing a column called "updated_at" that the system expects to exist. Every time the system tries to save an update, it attempts to write the current timestamp into this missing column, and the database rejects the operation with an error. This means the edit feature is effectively broken — any attempt to modify an existing fine rule will fail until the missing column is added to the database table.

When the manager deletes a rule, the system does not erase it. Instead, it archives the rule by hiding it from the active list while keeping it in the Trash. The rule still exists in the database with a timestamp marking when it was archived. To see archived rules, the manager switches to the Trash view, where they can either restore a rule (which brings it back to the active list with all its original values intact) or permanently delete it (which removes it from the database entirely — typically done only for test entries that were created during training).

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Fine Category | Must be selected from the available categories | "Please select a fine category." |
| From Day (range start) | Must be provided, must be a whole number, minimum 0 | "The from-day must be at least 0." |
| To Day (range end) | Must be provided, must be a whole number, must be equal to or greater than the from-day | "The to-day must be greater than or equal to the from-day." |
| Fine Type | Must be either "Fixed" (a flat rupee amount) or "Percentage" (a percentage of the outstanding fee) | "Please select either Fixed or Percentage as the fine type." |
| Fine Rate | Must be provided, must be a number (rupees if Fixed, percentage value if Percentage) | "Please enter a valid fine rate." |
| Student Restricted | Must be either Yes or No | "The student restricted field must be yes or no." |
| Day Range Overlap | ❌ NOT CHECKED — the system does not verify whether the new rule's day range overlaps with any existing rule for the same category | No error — rules with overlapping day ranges are saved without warning |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| User tries to create a rule without selecting a fine category | "Please select a fine category." — the form does not submit until a category is chosen | Data entry error — prevented before saving |
| User enters a "to day" that is smaller than the "from day" (e.g., from day 10 to day 5) | "The to-day must be greater than or equal to the from-day." — the form blocks submission | Data entry error — prevented before saving |
| User enters a non-numeric value in the fine rate field (e.g., "five hundred") | "Please enter a valid fine rate." — the form does not submit | Data entry error — prevented before saving |
| User creates a rule with a day range that overlaps an existing rule for the same category | ✅ The rule saves successfully without any warning — no error is shown | 🔴 Gap — no overlap validation. Two rules can claim the same day range, and the fee calculation engine will pick whichever one it finds first |
| User tries to edit an existing fine rule | ❌ The update fails with a database error. The system attempts to write the current timestamp into a column called "updated_at", but this column does not exist in the database table. The user sees a generic error page — there is no user-friendly message explaining the issue | 🔴 Gap — missing "updated_at" column in the database table makes the edit feature broken |
| User tries to view the Fine Master list without proper permissions | ✅ The page loads normally — the system does not check permissions at the list level | ⚠️ Gap — anyone who can reach the Transport Master tab can see all fine rules |
| User tries to view the Trash without proper permissions | ✅ The trash page loads normally — the system does not check permissions at the trash level | ⚠️ Gap — same as above, the trash view is unprotected |
| User tries to access the screen when no academic session is marked as "current" | ❌ The create and update features will fail because the system cannot find a current academic session to auto-assign. The user sees an error message depending on how the code handles the null session | 🔴 Gap — no fallback if no session is current |

---

## Success Scenarios — When Everything Works

**SC-001 — Transport Manager Sets Up All Late Fee Rules for the New Academic Year**
Mrs. Desai opens Fine Master on April 5th and creates four fine rules for the 2025-26 session: 1-5 days (₹200, no restriction), 6-15 days (₹500, restricted), 16-30 days (₹1,000, restricted), and 31-60 days (10%, restricted). All four rules are saved successfully and appear in the list. The activity log records each creation with the manager's name and timestamp. When the fee engine later processes overdue payments, it correctly applies the ₹500 fine for a student who is 10 days overdue and the ₹1,000 fine for a student who is 22 days overdue.

**SC-002 — Finance Manager Adjusts a Fine Rate Mid-Year and the Change Is Logged**
In September, the Finance Manager determines that the ₹500 slab for 6-15 days is causing too many parent complaints. She opens Fine Master, edits the 6-15 day rule, changes the rate from ₹500 to ₹350, and adds a note explaining the reason. The system saves the update successfully, records the exact change in the activity log ("Fine rate changed from 500.00 to 350.00 for rule ID 12"), and the updated rule is now used for all new overdue cases going forward. Parents whose fees became late before the change date continue to be charged the old rate — the system does not retroactively apply the new rate.

**SC-003 — Obsolete Rule Is Deleted and Archived for Future Reference**
At the end of the academic year, Mrs. Desai reviews the fine rules and finds that the 31-60 day slab was never used — no student ever went past 30 days without paying. She deletes the rule, and the system archives it. The rule disappears from the active list but remains in the Trash with a timestamp. Six months later, when the school considers whether to reintroduce an extreme slab, the Finance team asks Mrs. Desai to check the old rule. She opens the Trash, finds the archived rule, and notes the original parameters (31-60 days, 10% of outstanding fee). She restores the rule — it reappears in the active list with all its original values. She then edits the fine rate to 12% before the new session begins.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Edit Feature Is Completely Broken Due to Missing Database Column**
Mrs. Desai opens the 6-15 day rule to change the fine rate from ₹500 to ₹350. She edits the rate and clicks Save. The system attempts to update the record but immediately crashes with a database error. The error message is technical and shows on-screen — it does not say "Please contact your system administrator." Mrs. Desai is unable to complete the rate change. She tries again, and the same error occurs. She tries editing a different rule — same error. She calls the IT department, who investigates and discovers that the "tpt_fine_master" table is missing the "updated_at" column that the system needs to write to on every update. Every edit attempt for every fine rule is broken until a database administrator adds the missing column. In the meantime, the school is stuck with the old fine rates, and any mid-year changes that management has approved cannot be implemented.

**FC-002 — Overlapping Day Ranges Cause Inconsistent Fine Calculations**
The clerk creates a fine rule for 1-10 days (₹300 fixed) not realising that a 1-5 day rule (₹200 fixed) already exists for the same Transport Late Fee category. The system saves the new rule without warning. Two weeks later, two students are both 4 days overdue. For the first student, the system charges ₹200 (it found the 1-5 day rule first). For the second student, the system charges ₹300 (it found the 1-10 day rule first). The parents of the second student complain that they were charged more than another parent for the same number of days late. The school has no way to explain the inconsistency because both rules are valid in the system. The Finance team has to manually refund the difference and delete the duplicate rule.

**FC-003 — Permission Check Missing — Clerk Accidentally Deletes Fine Rules**
The Fine Master list screen does not check whether the viewer has permission to see or modify fine rules. A data entry clerk who is training on the system clicks through the Transport Master tabs and ends up on Fine Master. Thinking it is a test environment, the clerk deletes three fine rules from the active list. The rules are now in the Trash, but the Transport Manager does not notice for two weeks. During those two weeks, the fee calculation engine processes overdue payments without those three rules — students who should have been charged ₹500 for being 10 days late are charged nothing because the applicable rule is gone. When Mrs. Desai eventually discovers the missing rules, she restores them from the Trash, but the two weeks of fee calculations that happened in between cannot be retroactively corrected — the school has lost ₹12,000 in fine revenue.

**FC-004 — Academic Session Rollover Leaves System Without Active Rules**
When the new academic session begins in April, the system automatically marks the old session as inactive and the new session as current. However, since fine rules are tied to a specific academic session and cannot be bulk-copied, the new session starts with zero fine rules. The first time a student's fee becomes overdue, the fee calculation engine looks for rules matching the current session and finds nothing — no fine is calculated, no penalty is applied. The school does not realise that fine rules need to be recreated every year until a parent calls asking why no late fee was charged even though their payment was three weeks late. Mrs. Desai then scrambles to set up all the slabs from memory, comparing against printed reports from the previous year to match the old rates.

---

## Table: `tpt_fine_master`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| fine_category_id | TINYINT UNSIGNED NOT NULL FK | → `tpt_fine_category.id` RESTRICT |
| std_academic_sessions_id | INT UNSIGNED NOT NULL FK | → academic session |
| fine_from_days | TINYINT DEFAULT 0 | Day range start |
| fine_to_days | TINYINT DEFAULT 0 | Day range end |
| fine_type | ENUM('Fixed','Percentage') | Calculation type |
| fine_rate | DECIMAL(5,2) DEFAULT 0.00 | Rate |
| student_restricted | TINYINT(1) DEFAULT 0 | Block student? |
| Remark | VARCHAR(512) NULL | Notes |
| created_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
| **`updated_at`** | ❌ **MISSING IN DDL** | **Model expects this column** |
