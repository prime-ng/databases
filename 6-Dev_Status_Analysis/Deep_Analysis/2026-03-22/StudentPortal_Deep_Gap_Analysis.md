# StudentPortal Module - Deep Gap Analysis Report

**Date:** 2026-03-22
**Branch:** Brijesh_SmartTimetable
**Auditor:** Senior Laravel Architect (AI)
**Module Path:** `/Users/bkwork/Herd/prime_ai/Modules/StudentPortal/`

---

## EXECUTIVE SUMMARY

The StudentPortal module is a student-facing portal providing dashboard, account management, academic information, fee invoice viewing/payment, complaint lodging, and notifications. The module is **severely underdeveloped** — only 3 controllers are wired (StudentPortalController, StudentPortalComplaintController, NotificationController), there are **zero Gate::authorize calls** in the entire module, **zero FormRequests**, **zero policies**, **zero Service classes**, and no EnsureTenantHasModule middleware. The complaint controller uses inline validation with `$request->validate()` and directly uses `$request->merge()` to mutate request data. The module has test files but they need verification.

**Risk Level: HIGH**
**Estimated Issues: 38**
**P0 (Critical): 5 | P1 (High): 10 | P2 (Medium): 14 | P3 (Low): 9**

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables
The StudentPortal module **does not have its own tables**. It shares the `std_*` prefix with StudentProfile and reads from `fee_*` tables (FeeInvoice), `cmp_*` tables (Complaints), and `sys_*` tables (Users, Notifications).

### 1.2 Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | No dedicated database tables — fully dependent on other modules' models | P3 |
| 2 | Direct DB queries to `sys_dropdowns` in ComplaintController (lines 46-53) bypass model layer | P2 |

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Route Group
- **Prefix:** `student-portal`
- **Name prefix:** `student-portal.`
- **Middleware:** `['auth', 'verified']`
- **EnsureTenantHasModule:** **MISSING**

### 2.2 Routes Defined
```
student-portal.dashboard         GET  /student-portal/dashboard
student-portal.account           GET  /student-portal/account
student-portal.academic-information  GET  /student-portal/academic-information
student-portal.view-invoice      GET  /student-portal/view-invoice/{invoice}
student-portal.pay-due-amount    GET  /student-portal/pay-due-amount/pay-now/{invoice}
student-portal.proceed-payment   GET  /student-portal/pay-due-amount/proceed-payment
student-portal.complaint.*       Resource (7 routes)
student-portal.complaint.subCategories  GET  Ajax
student-portal.complaint.categoryMeta   GET  Ajax
student-portal.test-notification GET
student-portal.all-notifications GET
student-portal.notifications.mark-all-read  POST
student-portal.notifications.mark-read      GET
```

### 2.3 Issues
| # | Issue | File | Line | Severity |
|---|-------|------|------|----------|
| 1 | **EnsureTenantHasModule middleware not applied** | `routes/tenant.php` | 332 | P0 |
| 2 | **No role-based access control** — any authenticated user (teacher, admin) can access student portal routes | `routes/tenant.php` | 332 | P0 |
| 3 | `test-notification` route exposed in production | `routes/tenant.php` | 349 | P1 |
| 4 | `proceed-payment` route uses GET but should be POST (initiates payment) | `routes/tenant.php` | 339 | P1 |
| 5 | Only 3 functional areas wired: Dashboard/Account/Academic, Complaints, Notifications | All | P1 |
| 6 | Missing features: Timetable view, Homework, Exam results, Attendance, Library, Transport | - | P2 |

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 Controllers Found (3)
- **StudentPortalController** (171 lines) — Dashboard, account, academic info, invoice view, payment
- **StudentPortalComplaintController** (248 lines) — Complaint CRUD
- **NotificationController** — Notification listing and mark-read

### 3.2 Critical: Zero Authorization
| # | Controller | Issue | Severity |
|---|------------|-------|----------|
| 1 | **StudentPortalController** | **Zero Gate::authorize calls** in all 12 methods. Any authenticated user can view any student's invoices via `viewInvoice($id)` and `payDueAmount($id)` without ownership check. | P0 |
| 2 | **StudentPortalComplaintController** | **Zero Gate::authorize calls** in all methods. Store method accepts arbitrary `complainant_user_id` without ownership validation. | P0 |
| 3 | **NotificationController** | **Zero Gate::authorize calls** | P1 |

### 3.3 Stub Methods in StudentPortalController
| # | Method | Line | Issue | Severity |
|---|--------|------|-------|----------|
| 1 | `index()` | 122-125 | Returns view with no data | P2 |
| 2 | `create()` | 130-133 | Returns view with no data | P2 |
| 3 | `store()` | 138-140 | Empty method | P2 |
| 4 | `show($id)` | 145-148 | Returns view with no data | P2 |
| 5 | `edit($id)` | 153-156 | Returns view with no data | P2 |
| 6 | `update()` | 161-163 | Empty method | P2 |
| 7 | `destroy($id)` | 168-170 | Empty method | P2 |

### 3.4 IDOR Vulnerabilities
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | `StudentPortalController.php` | 81 | `viewInvoice($id)` uses `FeeInvoice::findOrFail($id)` — **no ownership check**. Any student can view any invoice. | P0 |
| 2 | `StudentPortalController.php` | 87 | `payDueAmount($id)` — same IDOR vulnerability. Any student can initiate payment for any invoice. | P0 |
| 3 | `StudentPortalComplaintController.php` | 42-193 | `store()` method — `complainant_user_id` can be set to any user's ID | P1 |

### 3.5 Inline Validation
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | `StudentPortalController.php` | 97-102 | `proceedPayment` uses `$request->validate()` inline | P1 |
| 2 | `StudentPortalComplaintController.php` | 56-85 | Multi-stage inline `$request->validate()` — complex logic in controller | P1 |

### 3.6 Request Mutation
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | `StudentPortalComplaintController.php` | 45-54 | `$request->merge()` used to mutate request data by doing DB lookups inline — should be in FormRequest or Service | P2 |

---

## SECTION 4: MODEL AUDIT

No models exist in the StudentPortal module. All models are imported from other modules:
- `Modules\StudentFee\Models\FeeInvoice`
- `Modules\Complaint\Models\Complaint`
- `Modules\Complaint\Models\ComplaintCategory`
- `Modules\Payment\Models\PaymentGateway`
- `App\Models\User`

### Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | No local models — entire module depends on external modules | P3 |
| 2 | No student ownership model/trait to verify portal access is limited to the logged-in student's data | P1 |

---

## SECTION 5: SERVICE LAYER AUDIT

**No Service classes exist in the StudentPortal module.**

| # | Issue | Severity |
|---|-------|----------|
| 1 | No `app/Services/` directory exists | P1 |
| 2 | Payment processing logic uses `PaymentService` from Payment module (good pattern) | PASS |
| 3 | Complaint creation logic (ticket generation, status lookup) embedded in controller | P2 |

---

## SECTION 6: FORMREQUEST AUDIT

**Zero FormRequest classes exist.**

| # | Issue | Severity |
|---|-------|----------|
| 1 | No `app/Http/Requests/` directory | P1 |
| 2 | Needed: StoreComplaintRequest, ProcessPaymentRequest, at minimum | P1 |

---

## SECTION 7: POLICY AUDIT

**Zero policies exist in the StudentPortal module.**

### 7.1 No Policy Registrations
There are no StudentPortal-specific policies registered in AppServiceProvider.

### 7.2 Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | No policies for any StudentPortal action | P0 |
| 2 | Need: StudentPortalPolicy (viewOwnData, viewOwnInvoice, createComplaint, viewOwnNotifications) | P1 |
| 3 | No ownership verification anywhere — must ensure student can only access their own data | P1 |

---

## SECTION 8: VIEW AUDIT

### Views Found
- Academic Information: details, invoice, payment-page + 7 partials
- Account: index + 5 partials (billing-payments, notification-settings, privacy-settings, profile-information, security-settings, sidebar-menu)
- Auth: login
- Complaint: create, index
- Dashboard: index
- Notification: index + 3 partials
- Components: layouts/master

### Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | Account settings views exist (notification-settings, privacy-settings, security-settings) but no backend controllers handle updates | P2 |
| 2 | Complaint show/edit/destroy views reference `studentportal::show/edit` which are generic stubs | P2 |

---

## SECTION 9: SECURITY AUDIT

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | CSRF Protection | PASS | Web middleware |
| 2 | Auth Middleware | PASS | Applied |
| 3 | Module Middleware | **FAIL** | Not applied |
| 4 | Role-Based Access | **FAIL** | No check that user is a STUDENT type |
| 5 | Gate/Policy | **FAIL** | Zero calls |
| 6 | IDOR Protection | **FAIL** | viewInvoice and payDueAmount have no ownership check |
| 7 | FormRequest | **FAIL** | Zero FormRequests |
| 8 | Payment Security | WARN | Amount validation exists but no server-side invoice amount verification |
| 9 | Request Mutation | **FAIL** | $request->merge() used to inject DB values |
| 10 | SQL Injection | PASS | Uses Eloquent |
| 11 | XSS | PASS | Blade escaping |
| 12 | Test Notification Route | **FAIL** | Debug route exposed in production |
| 13 | Input sanitization | WARN | Complaint description accepts arbitrary HTML |
| 14 | File upload | WARN | Complaint image upload — size/type limits need review |

---

## SECTION 10: PERFORMANCE AUDIT

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Eager Loading | PASS | `academicInformation()` eagerly loads relationships |
| 2 | N+1 | WARN | `notifications()->latest()->paginate(10)` — verify eager loading |
| 3 | Pagination | PASS | Notifications paginated |
| 4 | Complaint index | WARN | `Complaint::where('created_by', Auth::id())->get()` — not paginated |

---

## SECTION 11: ARCHITECTURE AUDIT

| # | Issue | Severity |
|---|-------|----------|
| 1 | Zero policies, zero FormRequests, zero services | P0 |
| 2 | Heavy cross-module dependency (StudentFee, Complaint, Payment, Notification) | P2 |
| 3 | No student-specific middleware to verify user_type === 'STUDENT' | P1 |
| 4 | 7 stub methods in StudentPortalController suggest incomplete scaffolding | P2 |
| 5 | Direct `DB::table('sys_dropdowns')` queries in ComplaintController bypass model | P2 |
| 6 | Hard-coded dropdown ID `(int) $request->complainant_type_id === 104` in ComplaintController:73,125 | P1 |

---

## SECTION 12: TEST COVERAGE

### 12.1 Tests Found
- Feature: ComplaintControllerTest, NotificationControllerTest, StudentPortalControllerTest
- Unit: ComplaintControllerTest, NotificationControllerTest, StudentPortalControllerTest
- Pest.php configuration file

### 12.2 Issues
| # | Issue | Severity |
|---|-------|----------|
| 1 | Tests exist but need verification — likely scaffolded without implementation | P2 |
| 2 | No IDOR attack tests | P1 |
| 3 | No payment flow tests | P2 |

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

| # | Gap | Severity |
|---|-----|----------|
| 1 | **Only 3 of ~10 planned features are wired**: Dashboard, Complaints, Notifications | P1 |
| 2 | Missing: Timetable viewing | P2 |
| 3 | Missing: Homework submission/viewing | P2 |
| 4 | Missing: Exam results viewing | P2 |
| 5 | Missing: Attendance history viewing | P2 |
| 6 | Missing: Library (book borrowing status) | P3 |
| 7 | Missing: Transport (route/bus details) | P3 |
| 8 | Account settings views exist but no backend: password change, notification preferences, privacy settings | P2 |
| 9 | Complaint show/edit/destroy are stubs | P2 |

---

## PRIORITY FIX PLAN

### P0 - Critical (Fix Immediately)
1. **Add ownership checks to viewInvoice() and payDueAmount()** — verify invoice belongs to logged-in student — `StudentPortalController.php:81,87`
2. **Add role-based middleware** to ensure only STUDENT users can access the portal group
3. **Add EnsureTenantHasModule middleware** to student-portal route group
4. **Create StudentPortalPolicy** with ownership-based authorization
5. **Remove test-notification route** from production — `routes/tenant.php:349`

### P1 - High (Fix This Sprint)
6. Add Gate::authorize to ALL controller methods
7. Create FormRequests: StoreComplaintRequest, ProcessPaymentRequest
8. Create student-specific middleware: `EnsureUserIsStudent`
9. Fix hard-coded dropdown ID 104 — use configuration or query by key
10. Remove `$request->merge()` pattern — move DB lookups to FormRequest/Service
11. Implement account settings backend (password change, notification preferences)
12. Paginate complaint index query

### P2 - Medium (Fix Next Sprint)
13. Implement timetable viewing functionality
14. Implement homework viewing functionality
15. Implement exam results viewing
16. Implement attendance history
17. Complete complaint show/edit/destroy stubs
18. Remove the 7 stub methods in StudentPortalController
19. Verify and complete test implementations
20. Add server-side invoice amount verification in proceedPayment

### P3 - Low (Backlog)
21. Add library book status viewing
22. Add transport route details
23. Migrate to proper Service classes for complaint and payment flows
24. Change proceedPayment route from GET to POST

---

## EFFORT ESTIMATION

| Priority | Items | Effort (person-days) |
|----------|-------|---------------------|
| P0 | 5 | 1.5 |
| P1 | 7 | 5 |
| P2 | 8 | 10 |
| P3 | 4 | 4 |
| **Total** | **24** | **20.5** |
