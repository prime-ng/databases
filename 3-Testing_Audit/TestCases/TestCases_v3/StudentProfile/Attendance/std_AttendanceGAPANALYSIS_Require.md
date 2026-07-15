# std_Attendance — Gap Analysis & Coverage

**Feature:** StudentProfile / Attendance · **Test file:** `std_Attendance_TestCas.php` (44 methods, ONE file)

---

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 schema truth | test_01, test_20, test_40–43 | Full |
| MTC-02 bulk apply + save | test_12, test_14 | Full |
| MTC-03 individual override | test_13, test_15 | Full |
| MTC-04 clear all | test_16 | Full |
| MTC-05 upsert idempotency | test_19 | Full |
| MTC-06 scan validation | test_30, test_31, test_32, test_39 | Full |
| MTC-07 manual validation | test_33, test_34, test_35, test_44 | Full |
| MTC-08 bulk store validation | test_36, test_37, test_38 | Full |
| MTC-09 permissions | test_50, test_51, test_52, test_53 | Full |
| MTC-10 FK integrity | test_40, test_41, test_42, test_43 | Full |
| MTC-11 defect/gap verification | test_94, test_95, test_96, test_97, test_98 | Full |
| (reload/persist) | test_17, test_18 | Full |
| (UI/empty state) | test_60, test_61, test_62 | Full |
| (edge: all statuses / period default) | test_70, test_71 | Full |
| (tenancy/security) | test_90, test_91 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive (TC-P) | 16 | 15 | 1 | 0 | 94% |
| Negative (TC-N) | 14 | 14 | 0 | 0 | 100% |
| Dependency (TC-D) | 7 | 7 | 0 | 0 | 100% |
| Tenancy (TC-T) | 1 | 1 | 0 | 0 | 100% |
| Security (TC-S) | 1 | 1 | 0 | 0 | 100% |
| Defect/Gap proofs | 5 | 5 | 0 | 0 | 100% |

**Gates:** Negative 100% ✅ · Positive ≥90% (94%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy 100% ✅

*Partial:* TC-P09 (reload prefill) asserts DB persistence + page renders but does not scrape the checked radio's `checked` attribute after reload (pre-check attribute is server-rendered; DB assertion is the load-bearing check).

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR bulk apply/override/save/mixed/clear) | 5 | 5 | 100% |
| State-Machine (correction Pending/Approved/Rejected) | 1 (schema) | 1 | 100% schema — controller impl: 0% (gap) |
| Validation Rules (scan/manual/bulk) | 12 | 12 | 100% |
| Integration Points (FKs to std_students/sch_class_section_jnt/sys_users) | 4 | 4 | 100% |
| Permissions (create/viewAny gates + policy) | 2 | 2 | 100% |

Every Source-tagged item has ≥1 TC.

---

## 4. Cross-Reference Findings (source-defect scan)

| # | Check | Compare | Finding | Status | ID / Test |
|---|-------|---------|---------|--------|-----------|
| 1 | Enum case | DDL ENUM (Title Case) vs FormRequest `in:` | scan/manual `in:Present,...,Half Day,...` **matches** DDL exactly ✅; **bulk store has NO `in:` rule** on per-student status | Defect | BUG-STD-ATT-01 / test_97 |
| 2 | Route registration | controller method `getAttendanceReport` vs routes/web.php | method exists, **no route registered** (dead method) | Defect | BUG-STD-ATT-02 / test_96 |
| 3 | Gate vs Policy | `Gate::authorize('tenant.attendance.*')` vs AttendancePolicy | gates present, policy methods present ✅ | OK | test_50/51 |
| 4 | Fillable vs DDL | model `$fillable` vs columns | fillable covers all writable columns ✅ | OK | test_01 |
| 5 | Cast vs DDL | `attendance_date=>date`, `marked_at=>datetime` | consistent with DATE/TIMESTAMP ✅ | OK | test_01 |
| 6 | Service delegation | controller vs service | no service — logic inline (acceptable for this feature) | Note | — |
| 7 | State machine vs impl | corrections FSM (DDL) vs controller | **schema declares Pending/Approved/Rejected; no controller/route implements it** | Gap | GAP-STD-ATT-03 / test_98 |
| 8 | Validation vs rules | requirement vs `validate()` | bulk missing per-status enum (see #1) | Defect | BUG-STD-ATT-01 |
| 9 | Error message vs source | expected vs controller strings | strings asserted verbatim ✅ | OK | test_39 |
| 10 | Permissions vs policy | matrix vs policy+gates | consistent `tenant.attendance.*` ✅ | OK | test_50/51 |
| 11 | Integration FK vs migration | requirement FKs vs DDL `foreign()` | all four FKs present with correct onDelete ✅ | OK | test_40–43 |

**Additional notes:**
- `StudentAttendance` has **no SoftDeletes** trait, yet a `student-attendance/trashed.blade.php` view exists → orphaned view (minor; no route). Documented, not asserted as a hard failure.
- Model imports `HasFactory` on `StudentAttendanceCorrection` but not on `StudentAttendance` (inconsistent; not a defect).

---

## 5. Audit Defect Disposition

| Audit ID | Description | Disposition | Test |
|----------|-------------|-------------|------|
| BUG-STD-P3-01 | stray `// dd($request->all());s` | **Remediated** — not present in current AttendanceController or StudentController; test asserts absence (regression guard) | test_94 |
| GAP-STD-22 | attendance < 75% automated notification | **Confirmed gap** — no threshold/notification logic; test asserts absence | test_95 |

---

## Legend
Full = every step automated · Partial = automated with a documented limitation · Gap = not automated (feature unimplemented in source).
