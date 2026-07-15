# Review Queue — Manual Testing Specification (`bha_ReviewQueueMANUALTESTING_Require`)

**Module:** BehaviouralAssessment (code BHA) · **Feature / Screen:** ReviewQueue
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/11-Review-Queue.md`
**Companion automation:** `bha_ReviewQueue_TestCas.php` (single comprehensive Dusk suite, **47 methods**, `php -l` clean)
**Traceability:** every manual case below maps 1:1 to a `TC-*` in `bha_ReviewQueueTcList_Require.md` and to a `test_review_queue_NN_*` method.

> **This is a WORKFLOW / STATE-MACHINE screen.** The centre of gravity is the assessment lifecycle
> `draft → submitted → reviewed`, the Send-Back loop, and audit finding **BUG-BA-001** (ratings/assessment
> remain editable after submit/approve because the read-only guard only checks `isLocked()` — a state the
> workflow never reaches). Manual verification of BUG-BA-001 is mandatory (MTC-20…MTC-23).

---

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| **Module** | BehaviouralAssessment (`BHA`) |
| **Feature / Screen** | Review Queue (screen `11-Review-Queue`) |
| **Primary URL** | `/behavioural-assessment/reviews` (queue index) |
| **Secondary URLs** | `/behavioural-assessment/reviews/{id}` (review sheet); `/behavioural-assessment/reviews/{id}/approve`; `/behavioural-assessment/reviews/{id}/send-back`; `/behavioural-assessment/assessments-page?tab=review-queue` (tabbed entry); `/behavioural-assessment/assessments/{id}/submit`; `/behavioural-assessment/assessments/{id}/bulk-rate` |
| **Controller** | `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController` (`reviewIndex` / `reviewShow` / `approve` / `sendBack`; plus `submit` / `bulkRate` / `autoSave`) |
| **Policy** | `Modules\BehaviouralAssessment\Policies\BaReviewPolicy` |
| **Service** | `Modules\BehaviouralAssessment\Services\BehaviouralScoreService::computeForPeriod` (invoked on approve) |
| **Primary table** | `ba_assessments` (**live `ba_` prefix**; the DDL doc says `bha_` — DOC-BA-001; filename keeps `bha_`) |
| **Related tables** | `ba_assessment_ratings`, `ba_student_remarks`, `ba_audit_log`, `ba_assessment_periods`, `sch_employees`, `sch_class_section_jnt` |
| **Validation** | `BaAssessmentRequest` (submit/bulk-rate). `sendBack()` has **no** `reviewer_remarks` server rule (VAL-BA-REV-001). |
| **Migration** | `database/migrations/tenant/2026_06_16_130617_create_ba_assessments_table.php` (resolved from the app repo via reflection) |
| **CRUD Type** | Workflow / state-machine review screen (approve, send-back — no create/edit/delete UI on this screen) |
| **Soft Delete** | Yes on `ba_assessments` (`deleted_at`, `SoftDeletes` trait). `ba_audit_log` is **immutable** — no soft delete, no `updated_at`. |
| **Pagination** | Queue index list of submitted assessments |
| **Audit Log** | **Module-local `ba_audit_log`** via `BaAuditLog::log` (immutable trail) — **NOT** the generic `activity_logs` helper. Assert audit rows in `ba_audit_log` (`entity_type='assessment'`, `field_name='status'`, `new_value='reviewed'`). |
| **DB scope** | TENANT-side (`tenant_db`, database-per-tenant, no `tenant_id` columns). Tenancy context required. |
| **Module prerequisite** | BehaviouralAssessment must be ENABLED in `prime_testing/modules_statuses.json` (else 404 on every route). |

---

## 2. Business Conditions (detailed, with messages & flow)

### State machine (as implemented)
```
                 submit (assessments/{id}/submit)         approve (reviews/{id}/approve)
   ┌──────┐  ──────────────────────────────────▶  ┌───────────┐  ─────────────────────▶  ┌──────────┐
   │ draft│                                        │ submitted │                          │ reviewed │
   └──────┘  ◀──────────────────────────────────  └───────────┘  ◀─────────────────────  └──────────┘
       ▲        sendBack (reviews/{id}/send-back)        │             sendBack (BUG-BA-REV-002:
       │        clears submitted_at / reviewed_by        │             freeze NOT permanent — reviewed
       └─────────────────────────────────────────────────┘             can still be sent back to draft)

   ENUM('draft','submitted','reviewed','locked')
   'locked' is UNREACHABLE for assessments — no controller path ever assigns it (dead state, BUG-BA-001).
```

- **BR — Pending Queue:** `reviewIndex()` lists ONLY `status = submitted`, ordered by `submitted_at`. Heading: **"Submitted Assessments Awaiting Review"**; a **"pending"** count badge is shown.
- **BR — Approve (`Approve & Lock` in the requirement):** code sets `status = 'reviewed'`, stamps `reviewed_at`, writes a `ba_audit_log` row (`status` → `reviewed`), and calls `BehaviouralScoreService::computeForPeriod`. **Divergence (DOC-BA-REV-001):** requirement calls the state **"Approved"** and mandates a permanent lock; the code uses `reviewed` and applies **no** lock.
- **BR — Send Back:** `sendBack()` reverts to `draft`, clears `submitted_at` and `reviewed_by`, copies `reviewer_remarks`. Redirects to the `review-queue` tab. **Divergence (VAL-BA-REV-001):** the UI marks the remarks box `required` but the server does not validate it.
- **BR — Approval Workflow Constraint (BC-CFG-01):** approval is globally toggled in Configuration; when disabled the queue is hidden and submissions bypass review. (Not enforced inside queue code — noted, not asserted destructively.)
- **BUG-BA-001 (mandatory proof target):** the read-only guard in `bulkRate()` / `autoSave()` checks **only** `$item->isLocked()` (`status === 'locked'`). Because no assessment ever reaches `locked`, ratings remain writable after `submit` and after `approve` (`reviewed`) — cached scores can silently diverge from the "frozen" sheet.

### Illegal transitions (expected rejections)
| From | Trigger | Result | Message intent |
|------|---------|--------|----------------|
| submitted | submit | rejected, status unchanged | "Only draft assessments can be submitted." |
| draft | approve | rejected, status unchanged | "Only submitted assessments can be approved." |
| draft | send-back | rejected, status unchanged | "Cannot send back this assessment." |

### Permissions (Source: `BaReviewPolicy`, controller `Gate::authorize`)
| Action | Permission |
|--------|-----------|
| View queue | `tenant.behavioural-assessment.reviews.viewAny` |
| Open review sheet | `tenant.behavioural-assessment.reviews.view` |
| Approve / Send Back | `tenant.behavioural-assessment.reviews.update` |
| Submit / enter ratings | `tenant.behavioural-assessment.assessments.update` |
| Guest | redirected to `/login` |

---

## 3. Manual Test Cases

> **Preconditions for every case:** BehaviouralAssessment enabled in `modules_statuses.json`; tenant reachable at `DUSK_TENANT_URL`; logged in as the tenant admin (`root@tenant.com`) unless the case states otherwise. Endpoint/state cases need at least one row in `ba_assessment_periods`, `sch_employees`, and `sch_class_section_jnt` (else the automation `markTestSkipped`s).

### Band 01–09 — Schema / configuration truth

#### MTC-01 — Table, model, relationships & FSM helpers configured (TC-P01 · `_01`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `ba_assessments` schema | Table exists with `id, period_id, teacher_id, class_section_id, status, submitted_at, reviewed_by, reviewed_at, reviewer_remarks, is_active, created_by, updated_by, created_at, updated_at, deleted_at` |
| 2 | Open the create-migration | Contains `Schema::create('ba_assessments'`, the status ENUM, `submitted_at`/`reviewed_at` timestamps, the `uq_ba_assessment` unique key, `softDeletes()` |
| 3 | Inspect `BaAssessment` model | `getTable()='ba_assessments'`; fillable = period_id, teacher_id, class_section_id, reviewed_by, status, submitted_at, reviewed_at, reviewer_remarks, is_active, created_by, updated_by; uses `SoftDeletes` |
| 4 | Inspect relationships | `period()/teacher()/reviewer()/classSection()` are BelongsTo; `ratings()/studentRemarks()` are HasMany; `isDraft()`/`isLocked()` exist |
| DB | `SELECT` column list of `ba_assessments` | Matches step 1 |

#### MTC-02 — Runtime prefix diverges from DDL doc (DOC-BA-001) (TC-X01 · `_02`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `ba_assessments` exists | Present |
| 2 | Confirm `bha_assessments` (stale DDL-doc name) does NOT exist | Absent — model binds to live `ba_` |
| DB | `SHOW TABLES LIKE 'bha_assessments'` | Empty |

#### MTC-03 — `ba_audit_log` is immutable (TC-P03 · `_03`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `ba_audit_log` table & model | Table exists; `getTable()='ba_audit_log'` |
| 2 | Check immutability | `$timestamps=false`; no `SoftDeletes`; no `updated_at` column; no `deleted_at` column |
| 3 | Check entity constants | `ENTITY_ASSESSMENT='assessment'`, `ENTITY_ASSESSMENT_RATING='assessment_rating'` |

#### MTC-04 — Status ENUM matches DDL (TC-P02 · `_04`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW COLUMNS FROM ba_assessments` → `status` | Type contains `'draft'`, `'submitted'`, `'reviewed'`, `'locked'` (MySQL only; skip otherwise) |

### Band 10–19 — Business rules

#### MTC-10 — Queue lists only submitted assessments (TC-P04 · `_10`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `reviewIndex()` source | Query filters `where('status','submitted')` |
| 2 | Visit `/behavioural-assessment/reviews` | Page renders heading **"Submitted Assessments Awaiting Review"** |

#### MTC-11 — Pending count badge (TC-P05 · `_11`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit the queue index | A **"pending"** count badge is displayed |

#### MTC-12 — Review Queue tab present (TC-P06 · `_12`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/behavioural-assessment/assessments-page?tab=review-queue` | The **"Review Queue"** tab is shown |

#### MTC-13 — Approve: submitted → reviewed + audit row (TC-P07 / TC-SM02 · `_13`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a `submitted` assessment | Row exists with `status='submitted'` |
| 2 | POST `reviews/{id}/approve` | 200/302 redirect |
| 3 | Refresh the assessment | `status='reviewed'`; `reviewed_at` stamped |
| DB | `SELECT * FROM ba_audit_log WHERE entity_type='assessment' AND entity_id={id} AND field_name='status' AND new_value='reviewed'` | Row exists (immutable audit trail) |

#### MTC-14 — Send Back: submitted → draft + clears review fields (TC-P08 / TC-SM03 · `_14`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a `submitted` assessment | Present |
| 2 | POST `reviews/{id}/send-back` with `reviewer_remarks="Please expand the remarks for Roll 12."` | 200/302 |
| 3 | Refresh | `status='draft'`; `submitted_at` NULL; `reviewed_by` NULL; `reviewer_remarks` persisted |

#### MTC-15 — Approve confirmation text says "reviewed", not "locked" (DOC-BA-REV-001) (TC-SM12 · `_15`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `resources/views/assessment/review-show.blade.php` | Confirmation text contains **"mark it as reviewed"** — not the requirement's "Approved…locked" wording |

#### MTC-16 — Approve sets `reviewed`, not `Approved`/`locked` (DOC-BA-REV-001) (TC-SM12 · `_16`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `approve()` in the controller | Sets `'status' => 'reviewed'`; does NOT set `'status' => 'locked'` |

#### MTC-17 — Approve/Send-Back redirect to review-queue tab (TC-P10 · `_17`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read controller redirects | Contain `['tab' => 'review-queue']` |

### Band 20–29 — State machine + BUG-BA-001

#### MTC-20 — `isLocked()` true only for `locked` (BUG-BA-001) (TC-SM10 · `_20`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `isLocked()` on draft/submitted/reviewed | All `false` |
| 2 | `isLocked()` on locked | `true` (a value the workflow never sets) |
| 3 | `isDraft()` on draft / submitted | `true` / `false` |

#### MTC-21 — bulkRate/autoSave guard only on `isLocked()` (BUG-BA-001) (TC-SM10 · `_21`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `bulkRate()` / `autoSave()` | Each guards on `if ($item->isLocked())` only |
| 2 | Search for a `status !== 'draft'` (or submitted/reviewed) guard in the rating writers | **Absent** — no read-only enforcement for submitted/reviewed |

#### MTC-22 — Ratings still editable after submit (BUG-BA-001) (TC-SM08 · `_22`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a `submitted` assessment; resolve a student/criterion/rating-level probe | Present (else skip) |
| 2 | POST `assessments/{id}/bulk-rate` with one rating | 200/302 — NOT blocked |
| DB | `SELECT` the rating from `ba_assessment_ratings` | Row persisted (**defect: sheet was already submitted**) |
| 3 | Refresh assessment | `status` still `submitted` (bulk-rate does not change status) |
| Cleanup | Delete the seeded rating | Removed |

#### MTC-23 — Ratings still editable after approve/reviewed (BUG-BA-001) (TC-SM09 · `_23`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a `reviewed` assessment + probe | Present (else skip) |
| 2 | POST `assessments/{id}/bulk-rate` | 200/302 |
| DB | `SELECT` the rating | Row persisted (**defect: cached scores can diverge from the approved sheet**) |
| Cleanup | Delete the seeded rating | Removed |

#### MTC-24 — submit illegal from submitted (TC-N01 / TC-SM05 · `_24`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `submitted`; POST `assessments/{id}/submit` | Rejected; `status` remains `submitted` |

#### MTC-25 — approve illegal from draft (TC-N02 / TC-SM06 · `_25`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `draft`; POST `reviews/{id}/approve` | Rejected; `status` remains `draft` |

#### MTC-26 — send-back illegal from draft (TC-N03 / TC-SM07 · `_26`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `draft`; POST `reviews/{id}/send-back` | Rejected; `status` remains `draft` |

#### MTC-27 — send-back from reviewed un-freezes (BUG-BA-REV-002) (TC-SM04 · `_27`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `reviewed`; POST `reviews/{id}/send-back` | Accepted; `status` reverts to `draft` (**defect: requirement says the freeze is permanent**) |

#### MTC-28 — `locked` is a dead state for assessments (TC-SM11 · `_28`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Search the controller for `'status' => 'locked'` | Not present — no path ever locks an assessment |

#### MTC-29 — Legal chain draft → submit → approve (TC-P11 / TC-SM01 · `_29`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `draft`; POST `submit` | `status='submitted'`, `submitted_at` set |
| 2 | POST `approve` | `status='reviewed'` |

### Band 30–39 — Validation

#### MTC-30 — send-back empty remarks NOT rejected server-side (VAL-BA-REV-001) (TC-N12 · `_30`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed `submitted`; POST `send-back` with `reviewer_remarks=""` | No 422; `status='draft'`; `reviewer_remarks` persisted empty/null (**defect: UI marks it required, server does not**) |

#### MTC-31 — send-back has no required-remarks rule at source (VAL-BA-REV-001) (TC-N12 / TC-X03 · `_31`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `sendBack()` | No `'reviewer_remarks' => ['required', …]` rule |
| 2 | Read `review-show.blade.php` | `name="reviewer_remarks"` present and marked `required` (client-only enforcement) |

#### MTC-32 — FormRequest rules reference live `ba_` tables (TC-X05 · `_32`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaAssessmentRequest` | Contains `exists:ba_assessment_periods,id`, `exists:sch_class_section_jnt,id`, `exists:sch_employees,id` |

### Band 40–49 — Integration / FK

#### MTC-40 — period_id FK is RESTRICT (TC-D01 · `_40`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| DB | Inspect FK `ba_assessments.period_id → ba_assessment_periods` | DELETE_RULE = RESTRICT (or NO ACTION) |

#### MTC-41 — reviewed_by FK is SET NULL (TC-D02 · `_41`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| DB | Inspect FK `ba_assessments.reviewed_by → sch_employees` | DELETE_RULE = SET NULL |

#### MTC-42 — Approve invokes score service (TC-D03 / TC-P09 · `_42`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `approve()` | Calls `computeForPeriod(` |
| 2 | Check `BehaviouralScoreService::computeForPeriod` | Method exists |

#### MTC-43 — Assessment uses soft deletes (TC-D04 · `_43`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `BaAssessment` | Uses `SoftDeletes`; `deleted_at` column present |

### Band 50–59 — Permissions

#### MTC-50 — Guest redirected to login (TC-N07 · `_50`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit `/behavioural-assessment/reviews` | Redirected to `/login` |

#### MTC-51 — Limited user 403 on queue index (TC-N08 · `_51`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a NON-super-admin user with no roles/permissions; login | — |
| 2 | GET the queue index | HTTP 403 (`reviews.viewAny` denied) |

#### MTC-52 — Limited user 403 on review sheet (TC-N09 · `_52`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As the limited user, GET `reviews/999999` | 403 (Gate runs before findOrFail — 403 even for a missing id) |

#### MTC-53 — Limited user 403 on approve (TC-N10 · `_53`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As the limited user, POST `reviews/999999/approve` | 403 |

#### MTC-54 — Limited user 403 on send-back (TC-N11 · `_54`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As the limited user, POST `reviews/999999/send-back` | 403 |

#### MTC-55 — Policy maps permission strings (TC-P12 · `_55`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaReviewPolicy` | Contains `tenant.behavioural-assessment.reviews.{viewAny,view,update,delete,restore,forceDelete,status}` |
| 2 | Check approve/sendBack methods | `function approve` and `function sendBack` present (reuse `reviews.update`) |

#### MTC-56 — Review controller methods are gated (TC-X04 · `_56`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read the controller | Contains `Gate::authorize('tenant.behavioural-assessment.reviews.viewAny')`, `…reviews.view`, `…reviews.update` |

### Band 60–69 — UI/UX

#### MTC-60 — Breadcrumb & heading (TC-P13 · `_60`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit the queue index | Shows **"Review Queue"** and **"Submitted Assessments Awaiting Review"** |

#### MTC-61 — Columns present (TC-P13 · `_61`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit the queue index | Columns **Period**, **Teacher**, **Class / Section**, **Submitted** are visible |

#### MTC-62 — Empty state or table renders (TC-P14 · `_62`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit the queue index | Page shows either **"No assessments pending review."** or a `<table>` |

### Band 70–79 — Edge cases

#### MTC-70 — Review sheet invalid id → 404 (TC-N04 · `_70`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | As permitted admin, GET `reviews/987654321` | 404 (findOrFail after Gate) |

#### MTC-71 — Approve invalid id → 404 (TC-N05 · `_71`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `reviews/987654321/approve` | 404 |

#### MTC-72 — Send-back invalid id → 404 (TC-N06 · `_72`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `reviews/987654321/send-back` | 404 |

#### MTC-73 — reviewShow references unimported `BaStudentRemark` (BUG-BA-REV-001, candidate) (TC-X02 · `_73`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read the controller | `BaStudentRemark::` is referenced |
| 2 | Check imports / FQN | Symbol is neither `use`-imported nor fully-qualified → latent fatal/500 when the review sheet opens (a future fix that adds the import will correctly fail this test for re-review) |

### Band 90–99 — Tenancy + Security

#### MTC-90 — Tenant context initialized (TC-T01 · `_90`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm tenancy | `tenancy()->initialized` is true; `ba_assessments` reachable |

#### MTC-91 — Cross-tenant direct-id isolation (TC-T02 · `_91`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Resolve a second tenant domain | If a second tenant exists, its `tenant` resolves; otherwise skip (single-tenant env) |

#### MTC-92 — FormRequest `authorize()` returns bare true (SEC-BA-002) (TC-S01 · `_92`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaAssessmentRequest::authorize()` | Returns bare `true` (mitigated by controller Gate — documented, not exploited) |

#### MTC-93 — Review grid escapes output (no raw Blade) (TC-N13 / TC-S02 · `_93`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `review-show.blade.php` | No `{!! !!}` unescaped output — reviewer remarks & grid render through `{{ }}` |

---

## 4. Known Source Defects to keep in view during manual runs

| ID | Severity | Manual case(s) |
|----|----------|----------------|
| **BUG-BA-001** | P1 (P0 if result-integration on) | MTC-20, MTC-21, MTC-22, MTC-23 |
| BUG-BA-REV-002 | P2 | MTC-27 |
| VAL-BA-REV-001 | P3 | MTC-30, MTC-31 |
| DOC-BA-REV-001 | Doc | MTC-15, MTC-16, MTC-28 |
| BUG-BA-REV-001 (candidate) | P1 | MTC-73 |
| DOC-BA-001 | Doc | MTC-02 |
| SEC-BA-002 | Info | MTC-92 |
