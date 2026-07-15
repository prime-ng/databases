# std_StudentCompleteProfile — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | StudentProfile (`STD`, prefix `std_`) |
| Feature | StudentCompleteProfile (read/composite: resume redirect + show + id-card + export + send-credentials) |
| URL prefix | `/student-profile` |
| Key routes | `student-profile.student.completeProfile` (`GET /student/{student}/complete-profile`), `.show` (`GET /student/{student}`), `.print-id-card` (`GET /student/{student}/print-id-card`), `.export` (`GET /student/export/{type}`), `.send-credentials` (`POST /students/send-credentials`), `.filter-dependencies` (`GET /student/filter-dependencies`) |
| Controller | `StudentController` (`completeProfile`, `show`, `printIdCard`, `export`, `sendCredentials`, `getFilterDependencies`, `getNextIncompleteTabForCreate`) |
| Models | `Student` (`std_students`) + `StudentProfile`, `StudentAddress`, `Guardian`, `StudentGuardianJnt`, `StudentAcademicSession`, `PreviousEducation`, `StudentDocument`, `StudentHealthProfile` |
| Views | `student/show.blade.php`, `student/id-card.blade.php`, `student/student_list.blade.php`, `student/index.blade.php`, `exports/pdf.blade.php`, `student/document_generate.blade.php` |
| Validation | Inline in controller (no FormRequest for this feature) |
| CRUD Type | READ / composite (no create/edit/delete matrix here) |
| Soft Delete | Yes (`std_students.deleted_at`) |
| Pagination | Index 12/page (student_management), 20/page (document_generate) |
| Activity Log | Not emitted by the read/export/id-card paths (destroy/restore/forceDelete elsewhere use `activityLog()` tenant sink) |
| DB scope | TENANT — tenant init required |
| Prerequisite | `STUDENT` module enabled in `modules_statuses.json`; `APP_ENV=testing` for Dusk |

## 2. Business Conditions (detailed)

### Resume ladder (`getNextIncompleteTabForCreate`)
```
no user_id / user            -> student_login_details
missing admission_no|first_name|dob -> student_details
no guardians                 -> parent_details
no sessions                  -> session_details
no previous education        -> student_previous_education
no health profile            -> student_health
all complete                 -> student_login_details (fallback)
```
`completeProfile()` → `redirect()->route('student-profile.student.editStudentDetails', ['student_id','user_id','activeTab'])`.

### Export behaviour (current source)
- `pdf` → builds a filtered `Student::with(['user','guardians'])->...->get()` (FULL load), renders `exports.pdf` and returns an **inline** `Pdf::...->download()` — **synchronous**.
- `excel` → `Excel::queue($export, 'exports/*.xlsx')` → redirect + flash `Export is being processed…` — **queued** (`StudentsExport implements ShouldQueue`).
- `csv` → `Excel::queue(... , CSV)` — **queued**.
- unknown type → `back()->with('error','Invalid export type')`.

### ID-card data (`StudentIdCardDataProvider::provide`)
Builds a flat variable map for `Template::render('STUDENT_ID_CARD', …)`. Identifier fields are passed **raw**: `admission_no`, `aadhar_id`, `student_qr_code` (= user `emp_code`). No hashing/UUID substitution. **[GAP-STD-25]**

## 3. Manual Test Cases

### MTC-01 — Schema & routes truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DESCRIBE std_students;` | columns per BC-DB-1 present; unique keys on `admission_no`,`user_id`,`aadhar_id` |
| 2 | Inspect model `Student` | table `std_students`, `SoftDeletes`, `aadhar_id` encrypted cast, `full_name` accessor |
| 3 | `php artisan route:list --name=student-profile.student` | 6 feature routes registered |

### MTC-10..15 — Resume redirect states
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a student in each completion state (login-only … fully-complete) | records created |
| 2 | Visit `/student-profile/student/{id}/complete-profile` for each | URL contains the expected `activeTab=` per ladder |
| 3 | Confirm target tab button carries CSS `active` | active tab matches |
| DB | `SELECT ... FROM std_students / std_student_guardian_jnt / std_student_academic_sessions ...` | state matches the tab chosen |

### MTC-16 — Redirect query params
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit complete-profile for a student with `user_id` | URL contains `student_id={id}` and `user_id={uid}` |

### MTC-17 — 500 stability
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit complete-profile for 8 students with varied missing relations | no page contains `Whoops` / 500 |

### MTC-30 — sendCredentials validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/student-profile/students/send-credentials` with `students=[uid]` and no `password_option` | 422 validation error (or 403/404 when module gated/disabled) |
| 2 | POST with `password_option=custom` and empty `custom_password` | 422 (`required_if`) |

### MTC-31 — Export invalid type
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/student-profile/student/export/foo` | redirect back, flash `Invalid export type` |

### MTC-40..42 — show() composite render
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/student-profile/student/{id}` | Profile Overview renders; `admission_no` shown as `Student ID:` |
| 2 | Inspect tab bar `#studentTabs` | tabs `#basic #profile #parent #academic #address #medical #documents` present |
| 3 | Review controller `show()` | eager-loads guardians.user, healthProfile, previousEducations, documents.documentType, addresses.city, sessions.* |

### MTC-50..52 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm gates | show/printIdCard=`tenant.student.view`; completeProfile/sendCredentials=`tenant.student.update`; export=`tenant.student.export` |
| 2 | As a user WITHOUT the ability | 403 |
| 3 | As a guest visit show() | redirect `/login` |
| 4 | Policy `view()` | true for global view, own student, or linked parent's child |

### MTC-60..62 — Index actions & ID card
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit index | `Complete Profile`, `Print ID Card`, export PDF/Excel buttons present |
| 2 | Visit `/student-profile/student/{id}/print-id-card` | id-card shell (`#id-card-content`, toolbar Back/Download/Print) renders |
| 3 | Force `Template::render` to throw (missing template) | redirect index + flash `Cannot generate ID card: …` |

### MTC-70..71 — Edge
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit show()/print-id-card for a non-existent id | 404 (not a 200 profile) |
| 2 | Review `getNextIncompleteTabForCreate` | all 6 ordered states handled |

### MTC-80 — [GAP-STD-25] ID-card PII exposure
| Step | Action | Expected (current defect behaviour) |
|------|--------|-------------------------------------|
| 1 | `(new StudentIdCardDataProvider)->provide(['student_id'=>$id])` | array key `admission_no` == raw student admission_no |
| 2 | Inspect same payload | keys `aadhar_id`, `student_qr_code` present as raw values; no hash()/UUID applied |
| Note | Defect: id-card/QR should encode a hash/UUID, not the raw admission number/emp_code | log GAP-STD-25 |

### MTC-81 — [PERF-STD-10] Export sync vs queue
| Step | Action | Expected (current source) |
|------|--------|---------------------------|
| 1 | Inspect `StudentsExport` | `implements … ShouldQueue` |
| 2 | Inspect `export()` excel/csv branches | `Excel::queue(...)` + flash `being processed` (queued) |
| 3 | Inspect `export()` pdf branch + `exportPDF()` | full `->get()` load then inline `->download()` — **synchronous** |
| Note | Audit PERF-STD-10 (Excel::download synchronous) is remediated for excel/csv; synchronous full-load risk persists in the PDF branch | log PERF-STD-10 |

### MTC-90..92 — Tenancy & security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `routes/web.php` | all student routes under `middleware('module:STUDENT')` |
| 2 | Request id-card for a foreign/non-existent id | not 200 (IDOR blocked) |
| 3 | GET export pdf with `?search=<script>alert(1)</script>` | payload NOT reflected verbatim |
