# std_ Medical Incident — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | StudentProfile |
| Feature / Screen | MedicalIncident |
| URL prefix | `/student-profile` (name prefix `student-profile.`) |
| Index URL | `GET /student-profile/medical-incidents` |
| Create URL | `GET /student-profile/medical-incidents/create` |
| Store URL | `POST /student-profile/medical-incidents` |
| Show URL | `GET /student-profile/medical-incidents/{id}` |
| Edit URL | `GET /student-profile/medical-incidents/{id}/edit` |
| Update URL | `PUT /student-profile/medical-incidents/{id}` |
| Delete URL | `DELETE /student-profile/medical-incidents/{id}` |
| Trash URL | `GET /student-profile/medical-incidents/trash/view` (NOTE: `/trash/view`, not `/trash`) |
| Restore URL | `GET /student-profile/medical-incidents/{id}/restore` (NOTE: **GET**, not POST) |
| Force Delete URL | `DELETE /student-profile/medical-incidents/{id}/force-delete` |
| Toggle Follow-up | `POST /student-profile/medical-incidents/{id}/toggle-follow-up` |
| Toggle Parent Notified | `POST /student-profile/medical-incidents/{id}/toggle-parent-notified` |
| AJAX students | `GET /student-profile/ajax/medical-incidents/get-students` |
| Controller | `Modules\StudentProfile\Http\Controllers\MedicalIncidentController` |
| Model | `Modules\StudentProfile\Models\MedicalIncident` (SoftDeletes, InteractsWithMedia) |
| Policy | `Modules\StudentProfile\Policies\MedicalIncidentPolicy` (EXISTS) |
| Validation | Inline `$request->validate()` (no dedicated FormRequest) |
| Primary table | `std_medical_incidents` |
| Migrations | `2026_06_15_151305_create_std_medical_incidents_table.php`, `2026_06_18_000004_add_deleted_at_to_std_medical_incidents.php` |
| CRUD type | Full CRUD + trash/restore/forceDelete + 2 AJAX toggles + AJAX student picker |
| Soft delete | Yes (`deleted_at`) |
| Pagination | 10 per page (index + trash) |
| Activity log | Tenant `activity_logs` (Modules\GlobalMaster\Models\ActivityLog); events: Updated, Deleted, Restored, Force Deleted, Toggled. store() logs NOTHING. |

### Prerequisites
- An active `Student` (`is_active = 1`) in `std_students` with a `user` relationship and `admission_no`.
- A `Dropdown` (`sys_dropdown_table`) with `type = 'MEDICAL_INCIDENT_TYPE'`.
- An active `User` (`is_active = 1`) for `reported_by`.
- Module `STUDENT` enabled in `modules_statuses.json` (see Validation Report — disabled = 404 on all routes).

---

## 2. Business Conditions (detailed)

### Activity-log events (verbatim from controller — assert exact strings)
| Action | Route verb | Event string logged |
|--------|-----------|---------------------|
| Create | POST store | (none — store does not log) |
| Update | PUT | `Updated` |
| Delete | DELETE | `Deleted` |
| Restore | GET | `Restored` |
| Force delete | DELETE | `Force Deleted` |
| Toggle follow-up | POST | `Toggled` |
| Toggle parent-notified | POST | `Toggled` |

### Validation rules (store vs update)
```
student_id        required | exists:std_students,id
incident_date     required | date
incident_type_id  required | exists:sys_dropdown_table,id
location          required | string | max:255      (⚠ column is VARCHAR(100) → DEV-MI-01)
description       required | string
first_aid_given   nullable | string | max:512      (column TEXT — OK)
action_taken      nullable | string | max:512      (⚠ column is VARCHAR(255) → DEV-MI-02)
reported_by       store: required|exists:sys_users,id   update: required|exists:users,id   (⚠ DEV-MI-03)
parent_notified   boolean
closure_date      nullable | date | after_or_equal:incident_date
follow_up_required boolean
```

### Create-form default flow
```
create.blade:
  #parentNotified  → old('parent_notified', true)   → checked   → stores parent_notified = 1
  #followUpRequired→ old('follow_up_required', false)→ unchecked → stores follow_up_required = 0
```

### Redirect flow (⚠ DEV-MI-07)
```
store()   → redirect route('student-profile.attendance.bulk')   (NOT the index)
destroy() → redirect route('student-profile.attendance.bulk')
update()  → redirect route('student-profile.medical-incidents.index')
restore() / forceDelete() → redirect route('student-profile.medical-incidents.trashed')
```

---

## 3. Test Cases (step-by-step)

### TC-P04 — Create with required fields (test_10)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, visit create page | Form renders |
| 2 | POST store with student_id, incident_date, incident_type_id, location, description, reported_by; parent_notified=1, follow_up_required=0 | 200/201/302 success |
| 3 | `SELECT * FROM std_medical_incidents WHERE location=<loc>` | 1 row; parent_notified=1, follow_up_required=0 |
| 4 | Verify optional cols | first_aid_given, action_taken, closure_date all NULL |
| 5 | Cleanup | forceDelete row |

### TC-P11 — Update saves + logs 'Updated' (test_17)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident (location "Before Update") | row exists |
| 2 | Visit edit page; PUT update with location "After Update" | 200/302 |
| 3 | `SELECT location` | "After Update" |
| 4 | `SELECT * FROM activity_logs WHERE subject_id=<id> AND event='Updated'` | ≥1 row |

### TC-P13 — toggleFollowUp false→true (test_20)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident follow_up_required=0 | row exists |
| 2 | POST `/toggle-follow-up` `{follow_up_required:1}` | JSON `{success:true, follow_up_required:true, message:...}` |
| 3 | `SELECT follow_up_required` | 1 |
| 4 | activity_logs event=`Toggled` | ≥1 row (⚠ NOT 'Updated' — sibling test asserted 'Updated' incorrectly) |

### TC-P25 — Full lifecycle (test_25)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident | row exists |
| 2 | DELETE incident | 200/302; deleted_at set; activity 'Deleted' |
| 3 | GET `/{id}/restore` | 200/302; deleted_at null; activity 'Restored' |
| 4 | DELETE incident again, then DELETE `/{id}/force-delete` | 200/302; row gone; activity 'Force Deleted' |

### TC-N01..N06 — Required-field validation (test_30–35)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store omitting the field under test | HTTP 422 (JSON validation) |

### TC-N04 — location required + max 255 (test_33)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store location='' | 422 |
| 2 | POST store location=256 chars | 422 |

### TC-N09 — closure_date after_or_equal (test_38)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | incident_date=2025-03-10, closure_date=2025-03-09 | 422 |
| 2 | closure_date=2025-03-10 (same day) | success |

### TC-N10 — toggle missing field (test_39)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/toggle-follow-up` with empty body | 422 |
| 2 | POST `/toggle-parent-notified` with empty body | 422 |

### TC-N13 — invalid id 404 (test_44)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/medical-incidents/99999999` | 404 |
| 2 | GET `/medical-incidents/99999999/edit` | 404 |

### TC-N14 — force-delete non-trashed 404 (test_45)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident (NOT soft-deleted) | row exists |
| 2 | DELETE `/{id}/force-delete` | 404 (onlyTrashed()->findOrFail) |

### TC-N15..N19 — Permissions (test_50–54)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit index as guest | redirect to /login |
| 2 | As a user WITHOUT the gate, POST store / GET restore / DELETE force-delete / POST toggle | 403 each |

### TC-D02 — reported_by null on reporter delete (test_42)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create temp reporter User; create incident referencing it | row exists |
| 2 | forceDelete the reporter | incident survives |
| 3 | `SELECT reported_by` | NULL (fk_med_inc_reporter ON DELETE SET NULL) |

### TC-N21/N22 — DDL width mismatch proofs (test_70/71)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create incident with location=200 chars | Stored length ≤100 (truncated) OR DB rejects — documents DEV-MI-01 |
| 2 | Create incident with action_taken=400 chars | Stored length ≤255 OR DB rejects — documents DEV-MI-02 |

### TC-N20 — filters ignored (test_69)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident | row exists |
| 2 | Visit index `?search=ZZZ_NO_MATCH_ZZZ` | Record still appears — index() ignores search (DEV-MI-06) |

### TC-N24 — stored XSS escaped (test_90)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident description=`<script>window.__miXss=1;</script>DuskXssMarker` | row exists |
| 2 | Visit show page | `window.__miXss` undefined (Blade escapes); "DuskXssMarker" visible |

### TC-P17/P18 — Listing badges (test_61/62)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed parent_notified true/false | index shows `bg-success "Yes"` / `bg-secondary "No"` |
| 2 | Seed follow_up true/false | index shows `bg-warning "Required"` / `bg-info "Not Required"` |

### TC-P20 — View modal (test_65)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit index, click view link | `#incidentModal` opens; `#incidentDetails` loads AJAX content |

### TC-P21 — Show page (test_66)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident with no closure_date | Show page renders location, description, first aid; Status badge = "Open" |
