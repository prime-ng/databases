# Department SLA — Implementation Plan

## Purpose
Granular SLA rules that override category defaults for specific departments, roles, users, or vendors. The most specific match takes priority when computing resolution deadlines and escalation timelines.

## Documented But Not Implemented

### Item 1: SLA Override Never Used in Escalation/Resolution Calculation (P0)

**Source:** `Requirements/sla.md:36` — "The SLA rule with the most specific match takes priority when computing resolution dates"

**Current Behavior:** `ComplaintController` escalation computation (lines 753-785) uses only `$complaint->category` defaults. The `DepartmentSla` model is never queried at runtime. The SLA CRUD exists but produces dead data.

**Implement:**

- [ ] Create `App\Services\SlaResolutionService`:

```php
class SlaResolutionService
{
    public function resolveSla(Complaint $complaint): array
    {
        // 1. Query DepartmentSla matching complaint's category
        // 2. Apply specificity scoring:
        //    - Match by category + subcategory + department + role + user
        //    - Score = count of non-null matched target fields
        // 3. Return highest-scoring SLA's hours (or category defaults)
    }
}
```

- [ ] Specificity scoring logic:
```
For each DepartmentSla record:
  score = 0
  if category matches: score++
  if subcategory matches: score++
  if target_department matches complaint's target: score++
  if target_role matches complaint's assigned_to_role: score++
  if target_user matches complaint's assigned_to_user: score++
Take SLA with highest score
Fall back to category defaults if no match
```

- [ ] Replace inline escalation in `ComplaintController` lines 757-785 with `SlaResolutionService::resolveSla()`
- [ ] Use resolved SLA hours to compute `resolution_due_at = ticket_date + resolved_hours`

### Item 2: SLA Store/Update Should Use FormRequest

**Source:** `Requirements/sla.md:38-39` — CRUD pattern

**Current Behavior:** `DepartmentSlaController` uses inline validation.

**Implement:**
- [ ] Create `StoreDepartmentSlaRequest.php` with:
  - `complaint_category_id`: `required|exists:cmp_complaint_categories,id`
  - `complaint_subcategory_id`: `nullable|exists:cmp_complaint_categories,id`
  - Target fields: at least one should be non-null (custom rule)
  - Escalation chain: `gt:` validation for L1..L5
- [ ] Create `UpdateDepartmentSlaRequest.php` with same rules

### Item 3: Migration Exists — Verify Columns

**Source:** `database/migrations/tenant/2025_12_25_062953_create_department_slas_table.php`

**Current Behavior:** Migration exists. Verify it includes:
- All FK target columns (department, role, user, vehicle, vendor, entity_group)
- Escalation entity group references (escalation_l1..l5_entity_group_id)
- The `is_active` boolean and soft deletes

**Implement:**
- [ ] Review the migration to ensure all fields from `Requirements/sla.md` are present
- [ ] Add any missing columns via new migration if needed

### Item 4: Escalation Entity Group Notifications Not Wired

**Source:** `Requirements/sla.md:19-23` — Fields `escalation_l1..l5_entity_group_id` exist but are never used

**Current Behavior:** These FK fields store which entity group gets notified at each escalation level, but no notification logic references them.

**Implement (coordinated with complaints plan escalation command):**
- [ ] When escalation processing fires (see complaints plan), read `escalation_l{N}_entity_group_id` from the resolved SLA
- [ ] Dispatch notification to members of that entity group

### Item 5: Missing Feature Tests

**Current Behavior:** Zero tests.

**Implement:**
- [ ] `SlaResolutionServiceTest.php` — unit test specificity scoring:
  - Exact match (all fields) beats partial match
  - Partial match beats category default
  - No match falls back to category defaults
- [ ] `DepartmentSlaCrudTest.php` — CRUD operations
