# 04 · Sensitive Operations — Highest-Risk Gaps Ranked

> The 🔴 Critical and 🟠 High missing-log gaps, ranked by blast radius. A missing log on a fee deletion or a grade write matters far more than one on a master-data toggle, even though each is "one ❌". Full enumerations are in `02_MISSING_CALLS.md`.
> Risk tiers: 🔴 money / grades / identity / access-control · 🟠 student records / portals / bulk operations.

---

## 🔴 Critical — money, grades, identity, access

### Financial (fees, payments, ledger)
| Module | Gap | Why it's critical |
|--------|-----|-------------------|
| **StudentPortal** | Razorpay `FeePaymentController::initiate/callback`, `PaymentDemoController::*`, mobile `MobileFeePaymentController::initiate/callback` — **no `sys_activity_logs` entry** | Payment initiation/confirmation with no central audit trail; disputes/refunds become unforensicable. *Partial mitigation:* `PaymentService` writes `ptm_*` rows (domain-only). |
| **StudentFee** | 10 missing incl. invoice/fee-record `destroy`, adjustments, `toggleStatus` | Money records mutated/deleted without trace. |
| **Accounting** | 6 missing incl. a zero-coverage controller (ledger/voucher posting); otherwise strong (15/21 full) | Financial postings must be immutable-audited. |
| **Payment** | 3 of 4 controllers zero-coverage | Gateway/transaction handling unlogged. |
| **Billing** | 4 missing across subscription/plan controllers | Tenant billing changes unlogged (revenue integrity). |

### Academic grades & results
| Module | Gap | Why |
|--------|-----|-----|
| **LmsExam** | 13 missing incl. attempt/result mutations | Exam scores altered without audit = integrity risk. |
| **StudentPortal / mobile** | `StudentExamAttemptController::submit`, `StudentQuizAttemptController::submit`, `StudentQuestAttemptController::submit` (+ mobile equivalents) — no central log | Grade-producing submissions unlogged centrally. *Partial:* domain `AttemptActivityLog`/`AttemptCheckpoint` tables. |
| **LmsQuiz (3) / LmsQuests (5)** | Attempt/grade mutations partial | Same integrity concern. |
| **Hpc** | Mostly compliant (4 full / 3 missing) — verify the 3 remaining | Academic evaluation records. |
| **MarksheetGeneration** | ✅ **0 missing** — exemplary; use as the reference for the others | — |

### Identity & access-control
| Module | Gap | Why |
|--------|-----|-----|
| **Admission** | 33 missing across 18 controllers (admit/reject/enroll) | Who was admitted/rejected and by whom must be traceable. |
| **StudentProfile** | 11 missing, 0 fully-compliant; PII record edits/deletes | Student identity data changes. |
| **Prime** | 34 missing — role/permission/org/user mutations | **Access-control changes with no audit trail** (security-critical). |
| **HrStaff** | 10 missing (staff records) | Staff identity/employment changes. |
| **Certificate** | 28 missing, 0 fully-compliant controllers | Credential issuance/revocation unlogged. |

---

## 🟠 High — student records, portals, bulk operations

| Module | Missing | Note |
|--------|:---:|------|
| **BehaviouralAssessment** | 49 | **0 fully-compliant controllers**; sensitive behavioural data on minors. |
| **SchoolSetup** | 131 | Largest raw gap; includes class/section/academic-structure mutations that everything else depends on. |
| **TimetableFoundation (40) / SmartTimetable** | ~60 | Scheduling changes affecting students/staff. |
| **StudentPortal / ParentPortal** | 18 / ~10 | Parent- and student-facing mutations (complaints, requests, profile edits). |
| **Feedback / Complaint** | ~50 | Grievance records — should be fully traceable. |
| **Syllabus / SyllabusBooks / QuestionBank** | ~35 | Academic content mutations. |
| **Notification** | 38 | Communication records. |

---

## Prioritization Logic

1. **Money + grades + access-control first** (StudentPortal payments/grades, StudentFee, Accounting, Prime roles, LmsExam) — these are the operations a regulator, auditor, or parent dispute will demand a trail for.
2. **Identity next** (Admission, StudentProfile, HrStaff, Certificate).
3. **Then bulk/high-volume student records** (BehaviouralAssessment, SchoolSetup structure, timetabling).
4. Medium/operational gaps (`02_MISSING_CALLS.md`, 🟡) can be closed structurally via the base-layer approach in `06_REMEDIATION_PLAN.md` rather than one-by-one.

**One-line takeaway:** the audit coverage is *inversely* correlated with risk in several modules — the areas that most need an audit trail (portals' payments/grades, admissions, behavioural, certificates) are among the least covered. Fixing the 172 🔴 gaps is the priority.
