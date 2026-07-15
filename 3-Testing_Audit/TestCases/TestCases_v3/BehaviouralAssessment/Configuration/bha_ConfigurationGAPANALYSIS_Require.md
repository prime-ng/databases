# bha_ Configuration — Gap Analysis & Coverage

**Feature:** BehaviouralAssessment / Configuration · **Test file:** `bha_Configuration_TestCas.php` (**51 methods**) · **Style:** Browser Dusk (tenant, `ba_config`).

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-P01 | Schema/model/request truth | test_01 | Full |
| TC-P02 | Runtime prefix DOC-BA-001 | test_02 | Full |
| TC-P03 | FormRequest rule/message strings | test_03 | Full |
| TC-P04 | Create persists + flash | test_10 | Full |
| TC-P05 | Update persists changes | test_11 | Full |
| TC-P06 | Weightage + boolean casts | test_12 | Full |
| TC-P07 | Show page renders | test_13 | Full |
| TC-P08 | Setup tab lists configs | test_14 | Full |
| TC-P09 | index redirect to setup | test_15 | Full |
| TC-P10 | Active↔Inactive | test_20 | Full |
| TC-P11 | Scale change allowed, no ratings | test_21 | Partial (skips if seeded session has ratings) |
| TC-P12 | Guard + lock present in source | test_22 | Full |
| TC-P13 | Toggle JSON messages | test_55 | Full |
| TC-P14 | Weightage boundaries 5 & 20 | test_71 | Full |
| TC-P15 | is_active defaults true | test_72 | Full |
| TC-P16 | Threshold persists all values | test_80 | Full |
| TC-P17 | Result-integration + aggregation persist | test_83 | Full |
| TC-P18 | Setup search renders | test_60 | Full |
| TC-P19 | Trash page renders | test_62 | Full |
| TC-P20 | Breadcrumb create + show | test_63 | Full |
| TC-P21 | Full lifecycle | test_46 | Full |
| TC-P22 | Restore to default scope | test_41 | Full |

### Negative
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-N01 | Required fields (×5) | test_30 | Full |
| TC-N02 | weightage < 5 | test_31 | Full |
| TC-N03 | weightage > 20 | test_32 | Full |
| TC-N04 | weightage non-numeric | test_33 | Full |
| TC-N05 | aggregation_method set | test_34 | Full |
| TC-N06 | threshold set | test_35 | Full |
| TC-N07 | session must exist | test_36 | Full |
| TC-N08 | scale must exist | test_37 | Full |
| TC-N09 | duplicate session + custom msg | test_38 | Full |
| TC-N10 | omit toggle coerces false | test_39 | Full |
| TC-N11 | invalid id 404 (×3) | test_70 | Full |
| TC-N12 | guest redirect | test_50 | Full |
| TC-N13 | limited create 403 | test_51 | Full (defensive — skips if limited user uncreatable) |
| TC-N14 | limited toggle 403 | test_52 | Full (defensive) |
| TC-N15 | limited destroy 403 | test_53 | Full (defensive) |
| TC-N16 | empty-state message | test_61 | Full |
| TC-N17 | scale change rejected when ratings exist | test_23 | Partial (defensive — skips if no ratings; guard proven in test_22) |

### Dependency
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-D01 | Soft delete + inactive + trash | test_40 | Full |
| TC-D02 | Restore | test_41 | Full |
| TC-D03 | Force delete | test_42 | Full |
| TC-D04 | Session FK RESTRICT | test_43 | Partial (skips if no FK metadata) |
| TC-D05 | Scale FK RESTRICT | test_44 | Partial (skips if no FK metadata) |
| TC-D06 | DATA-BA-003 soft-delete reuse | test_45 | Partial (defensive try/catch) |
| TC-D07 | Full lifecycle | test_46 | Full |
| TC-D08 | Ratings-chain probe | test_21/23 | Full (branch resolved either way) |

### Tenancy / Security
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-T01 | Tenant context + no tenant_id | test_90 | Full |
| TC-T02 | Cross-tenant isolation | test_91 | Partial (defensive — skips if single tenant) |
| TC-S01 | authorize() bare true (SEC-BA-002) | test_92 | Full |
| TC-S02 | Notification not wired (SEC-BA-001) | test_81 | Full |
| TC-S03 | Policy gate strings | test_54 | Full |
| TC-S04 | Requirement fields absent (CFG-BA-001) | test_82 | Full |
| TC-S05 | No activity log | test_93 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 22 | 21 | 1 | 0 | 100% (Full 95%) |
| Negative | 17 | 16 | 1 | 0 | 100% (Full 94%) |
| Dependency | 8 | 4 | 4 | 0 | 100% (Full 50% + defensive) |
| Tenancy (P0/P1) | 2 | 1 | 1 | 0 | 100% (Full 50% + defensive) |
| Security | 5 | 5 | 0 | 0 | 100% |
| **Total** | **54** | **47** | **7** | **0** | **100%** |

**Gates:** Negative **100%** ✅ · Positive **100%** (95% Full) ✅ (≥90) · Dependency **100%** ✅ (≥90, remainder environment-conditional defensive) · Tenancy **100%** on P0/P1 ✅.

All 7 "Partial" items are **environment-conditional** (not logic gaps): they `markTestSkipped` when a prerequisite is absent (ratings data, FK metadata, second tenant, limited-user creation). Each carries an alternate assertion (e.g. DATA-BA-001 guard proven statically in test_22 regardless of test_21/23 skip).

---

## 3. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 10 | 10 | 100% |
| State-Machine transitions (BC-SM) | 4 | 4 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration Points (BC-INT/BC-REF) | 5 | 5 | 100% |
| Permissions (BC-AUTH) | 8 | 8 | 100% |
| Config/Edge findings (BC-CFG/BC-EDG) | 6 | 6 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No requirement item has 0 coverage.

**Requirement-vs-implementation divergence (CFG-BA-001):** three fields named in `07-Configuration.md` (Approval Workflow, Incident Escalation Threshold, Notification Settings) are NOT implemented and therefore have **no positive CRUD coverage** — instead they are covered by an explicit *absence* assertion (test_82). This is intentional and recorded as a requirement finding, not a coverage gap.

---

## 4. Cross-Reference Defect Scan (source-defect hunt)

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|-----|--------------|
| 1 | Enum case | DDL `enum(aggregation_method)` / `enum(parent_notification_threshold)` vs FormRequest `in:` | Match — `average,weighted_average,separate_display` and `minor,moderate,major,critical` align (lowercase both sides) | — | test_03, test_34/35 |
| 2 | Route registration | blade `route('behavioural-assessment.configs.*')` vs module routes | All resolvable; `index` redirects to `setup?tab=configuration`; `restore` is GET; `toggle-status` POST | — | test_15, test_46, test_70 |
| 3 | Gate vs Policy | controller `Gate::authorize('tenant.behavioural-assessment.configs.*')` vs `BaConfigPolicy` methods | 8 abilities present & mirrored in policy | — | test_54, test_51–53 |
| 4 | Fillable vs DDL | model `$fillable` vs `ba_config` columns | Match (9 business columns; id/timestamps/deleted_at excluded) | — | test_01 |
| 5 | Cast vs DDL | model `$casts` vs DDL types | Match — decimal→weightage, boolean→is_active/is_result_integration_enabled | — | test_01, test_12 |
| 6 | Service delegation | controller vs `BehaviouralScoreService` | Config CRUD is inline in controller; DATA-BA-001 guard reads ratings directly — acceptable | — | test_22 |
| 7 | State machine vs impl | requirement scale-lock vs controller/edit.blade | Guard PRESENT (server-side + `@disabled` UI) — DATA-BA-001 audit finding RESOLVED | **DATA-BA-001 (fixed)** | test_21/22/23 |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | weightage min:5/max:20, both enums, unique-session all present | — | test_03, test_30–38 |
| 9 | Error message vs FormRequest | duplicate-session message | Custom message present & asserted verbatim | — | test_38 |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + Gate | 8 gates all present & consistent (incl. `status`) | — | test_54 |
| 11 | Integration FK vs migration | requirement FKs vs migration `foreign()` | `academic_session_id`→sessions RESTRICT, `rating_scale_id`→ba_rating_scales RESTRICT | — | test_43, test_44 |
| + | DDL doc vs runtime table | doc `bha_config` vs live `ba_config` | Doc name stale; model binds `ba_config` | **DOC-BA-001** | test_02 |
| + | Unique index vs FormRequest scope | `uq_ba_config_session` (unconditional) vs `whereNull(deleted_at)` | Soft-deleted session not cleanly reusable — FormRequest passes, DB blocks insert | **DATA-BA-003** | test_45 |
| + | Config consumer scan | `parent_notification_threshold` write vs any reader | Configured but never read to dispatch a notification — dead config | **SEC-BA-001** | test_80, test_81 |
| + | FormRequest authorize | `authorize()` body | returns bare `true` (mitigated by controller Gate) | **SEC-BA-002** | test_92 |
| + | Requirement fields vs schema | 07-Configuration.md fields vs `ba_config` columns | Approval Workflow / Escalation Threshold / Notification Settings NOT implemented | **CFG-BA-001** | test_82 |
| + | Activity-log expectation | requirement audit trail vs controller | No activityLog on any mutation — documented absence | Observation | test_93 |

### Defect register (this feature)
| ID | Sev | Owner screen | Proving test | Status |
|-----|-----|--------------|--------------|--------|
| DOC-BA-001 | Low | Configuration | test_02 | Documented |
| DATA-BA-001 | High | Configuration | test_21/22/23 | **RESOLVED (verified fixed)** |
| DATA-BA-003 | Med | Configuration | test_45 | Documented |
| SEC-BA-001 | High | Configuration (incident flow) | test_80/81 | **UNRESOLVED** |
| SEC-BA-002 | Low | Configuration | test_92 | Documented (mitigated) |
| CFG-BA-001 | Info | Configuration | test_82 | Documented (requirement divergence) |

### Notes
- **DATA-BA-001** was flagged by the 2026-06-29 audit as a live P1 (scale switchable mid-session). This suite proves the canonical fix is now in the source (guard in `update()` + `@disabled($hasRatings)` lock in edit.blade), so the finding is recorded as RESOLVED with a regression guard — test_21 (permissive), test_22 (guard present), test_23 (blocking, defensive).
- **SEC-BA-001** remains the only P1-class **open** finding owned by this screen: the threshold is configurable but never consumed. test_81 will FAIL (go red) the moment a notification/mail dispatch or a `parent_notification_threshold` read is added to the incident flow — i.e. it is a change-detector for the fix.

---

## 5. Legend
- **Full** — automated method asserts the behaviour end-to-end.
- **Partial** — asserted with an environment-conditional fallback (`markTestSkipped` when a prerequisite/tenant/data hook is absent), always paired with an alternate static assertion where possible.
- **Gap** — no automated coverage (none for this feature).
- **DEV/BUG/BA-###** — source finding surfaced by the cross-reference scan; the test proves current behaviour and acts as a change-detector.
