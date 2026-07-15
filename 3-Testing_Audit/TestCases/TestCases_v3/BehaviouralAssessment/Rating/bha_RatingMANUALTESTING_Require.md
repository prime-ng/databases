# bha_Rating — Manual Testing Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | Rating (Ratings Grid) — `09-Ratings.md` |
| Primary URL | `/behavioural-assessment/assessments/{id}` (grid = `show`) |
| Save endpoints | `POST .../assessments/{id}/auto-save` (JSON autosave), `POST .../assessments/{id}/bulk-rate` (full grid), `POST .../assessments/{id}/submit` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController` |
| Models | `BaAssessmentRating` (`ba_assessment_ratings`), `BaAssessment` (`ba_assessments`), `BaAuditLog` (`ba_audit_log`), `BaStudentRemark` |
| Validation | Inline `$request->validate()` only — **no FormRequest** for the grid (VAL-BA-001) |
| Migrations | `2026_06_16_130625_create_ba_assessment_ratings_table.php`, `..._130617_create_ba_assessments_table.php` |
| CRUD type | Transactional grid (upsert per cell); parent assessment is CRUD |
| Soft delete | Yes (`deleted_at`) — but unique key omits `deleted_at` (DATA-BA-003) |
| Pagination | N/A (grid = all students × criteria for one assessment) |
| Activity / Audit | `ba_audit_log` (immutable), `entity_type='assessment_rating'` on each changed cell |
| Prefix note | File prefix `bha_`; live tables `ba_` (DOC-BA-001) |

---

## 2. Business Conditions (detailed)

**Lock constraint (requirement §"Lock Constraints"):** *"If the corresponding `ba_assessments` record is in Submitted or Approved status, or the `ba_assessment_periods` lock date has passed, the entire grid disables. All dropdowns turn read-only, and the save endpoints reject requests."*

**Actual implementation (BUG-BA-001):**
```
BaAssessment::isLocked()  ⇒  return $this->status === 'locked';
autoSave()/bulkRate()     ⇒  if ($item->isLocked()) { reject }   // only 'locked'
submit()  sets status 'submitted'   approve() sets 'reviewed'   // never 'locked'
period lock() sets ba_assessment_periods.status='locked'        // never cascades to ba_assessments
show.blade select/textarea disabled when: isLocked() || status !== 'draft' || !can(update)   // CLIENT only
```
⇒ A submitted / reviewed assessment (and one whose period is locked/past-deadline) is **read-only in the browser but writable via a direct POST** to `auto-save`/`bulk-rate`. After approval, scores are cached in `ba_computed_scores` and are **not** recomputed on later edits → published score silently diverges from the ratings + immutable audit trail.

**Autosave flow:** change dropdown cell → async `POST auto-save` with `ratings[studentId][criterionId]=levelId` → `updateOrCreate` on `ba_assessment_ratings` keyed `(assessment_id, student_id, criterion_id)` → each changed `rating_level_id` appended to `ba_audit_log` → returns `{success:true}`; indicator flips "Saving…" → "All Changes Saved in Cloud".

---

## 3. Test Cases (step-by-step)

### TC-SM02 / `_21` — Submitted assessment still accepts writes (BUG-BA-001) ★
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed grading graph (scale+level+category+criterion) and a `ba_assessments` row with `status='submitted'` (reuse existing period/teacher/class-section/student) | Rows created |
| 2 | As admin, `POST /assessments/{id}/auto-save` with `ratings[{student}][{criterion}]={level}` | HTTP 200 |
| 3 | Inspect JSON | `success = true`; message is **NOT** "Assessment is locked." |
| 4 | DB check | `SELECT * FROM ba_assessment_ratings WHERE assessment_id={id} AND student_id={s} AND criterion_id={c}` → **1 row exists** (rating written on a submitted assessment) |
| 5 | Verdict | **BUG-BA-001 confirmed** — read-only-after-submit not enforced server-side |

### TC-SM01 / `_20` — isLocked() root cause
| Step | Action | Expected |
|------|--------|----------|
| 1 | `(new BaAssessment(['status'=>'submitted']))->isLocked()` | `false` |
| 2 | `->isDraft()` for submitted | `false` |
| 3 | `(new BaAssessment(['status'=>'reviewed']))->isLocked()` | `false` |
| 4 | `(new BaAssessment(['status'=>'locked']))->isLocked()` | `true` (only state that trips the guard) |

### TC-SM04 / `_23` — endpoints ignore period lock/deadline
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `autoSave()`/`bulkRate()` source bodies | Contain `isLocked()` |
| 2 | Search bodies for `deadline` / `period->status` | **Absent** → period lock never consulted (BUG-BA-001) |

### TC-SM06 / `_26` — client vs server divergence
| Step | Action | Expected |
|------|--------|----------|
| 1 | `show.blade` disables selects/textareas when `status !== 'draft'` | Present (client read-only) |
| 2 | Direct `POST auto-save` on submitted assessment | `success:true` (server accepts) — divergence proven |

### TC-P05 / `_10` — autoSave persists (draft)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed draft assessment + grading graph | Rows created |
| 2 | `POST auto-save` with one cell | 200, `success:true` |
| 3 | DB check | Rating row exists with `rating_level_id = {level}` |

### TC-P06 / `_11` — upsert + audit
| Step | Action | Expected |
|------|--------|----------|
| 1 | autoSave cell → level A; then autoSave same cell → level B | Both 200 |
| 2 | `SELECT COUNT(*)` for the cell | **1** row (updated, not duplicated) |
| 3 | `SELECT COUNT(*) FROM ba_audit_log WHERE entity_type='assessment_rating'` before/after | after > before |

### TC-N01 / `_30` — scalar ratings rejected
| Step | Action | Expected |
|------|--------|----------|
| 1 | `POST auto-save` with `ratings='not-an-array'` | HTTP 422 |
| 2 | JSON | `errors.ratings` present |

### TC-N09 / `_50` — guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear cookies, visit `/assessments/create` | Redirect to `/login` |

### TC-N10 / `_51` — limited user 403 on auto-save
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create non-super-admin user, strip `is_super_admin`/roles/permissions | User has no `assessments.update` |
| 2 | `POST auto-save` as that user | HTTP 403 |

### TC-D01 / `_40` — cascade delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed draft assessment + one saved rating | Rating exists |
| 2 | `forceDelete()` the assessment | Row removed |
| 3 | DB check | `ba_assessment_ratings` for that assessment → 0 rows (FK CASCADE) |

### TC-D05 / `_44` — DATA-BA-003
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW INDEX FROM ba_assessment_ratings WHERE Non_unique=0` | uq present |
| 2 | Check unique columns | `(assessment_id,student_id,criterion_id)` — **no `deleted_at`** → recreate-after-soft-delete would 500 |

### TC-S01 / `_93` — BUG-BA-RAT-01 (discovered)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `BaAssessmentController` source | Contains `DB::transaction(` and `BaStudentRemark::` |
| 2 | Check imports | **No** `use Illuminate\Support\Facades\DB;` and **no** `use ...\BaStudentRemark;`, not `\DB::` either |
| 3 | Verdict | Unqualified symbols resolve to controller namespace → runtime `Error` on `show/reviewShow/bulkRate` (autoSave is clean — `_94`) |

*(Remaining TCs `_01–_04, _12, _13, _22, _24, _25, _31–_33, _41–_43, _45, _52–_55, _60–_62, _70–_72, _90–_92, _94` follow the same Step/Action/Expected pattern; see the TcList for the full BC↔TC↔method map.)*
