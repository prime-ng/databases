# Parent Portal — Digital Consent Forms: Test Case List

## 1. Module Information

| Field | Value |
|-------|-------|
| Module | ParentPortal |
| Feature | Digital Consent Forms |
| Controller | ParentConsentFormController |
| Routes | 3 routes (index, show, sign) |
| Priority | P1 — Standard |
| FRD Source | REQ-PPT-011 |

---

## 2. Assumptions & Prerequisites

- Parent is authenticated with a valid Sanctum session
- Active child is resolved and linked to the parent (can_access_parent_portal = 1)
- Active child has a current academic session (class_section_id available)
- `ppt_consent_forms` and `ppt_consent_form_responses` tables exist
- Dropdown reference data is seeded for form status and response options
- At least one Published consent form exists targeting the child's class/section

---

## 3. Test Case Summary

| Test Suite | Total TC | V1 | V2 | CR | Status |
|------------|----------|----|----|----|--------|
| UI / View / Screen | 5 | — | — | ◌ | ⬜ |
| Validation (Field-Level) | 6 | — | — | ◌ | ⬜ |
| Positive / Functional | 6 | — | — | ◌ | ⬜ |
| Negative / Error | 6 | — | — | ◌ | ⬜ |
| Security / Access Control | 4 | — | — | ◌ | ⬜ |
| Business Rules (BR) | 3 | — | — | ◌ | ⬜ |
| Integration / API | 1 | — | — | ◌ | ⬜ |
| Performance / Load | 0 | — | — | ◌ | ⬜ |
| Edge Case / Boundary | 4 | — | — | ◌ | ⬜ |
| **Total** | **35** | — | — | 0 | ⬜ |

---

## 4. Detailed Test Cases

### 4.1 UI / View / Screen Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-UI-01 | Consent forms list renders with three sections | Published forms exist (some signed, some pending, some closed) | GET /parent-portal/consent-forms | Page shows Pending, Signed, and Closed sections with correct count | — | ◌ | ⬜ |
| TC-CF-UI-02 | Form detail page shows full content | Published consent form exists | GET /parent-portal/consent-forms/{form} | Form title, HTML body content, deadline, and sign/decline buttons displayed | — | ◌ | ⬜ |
| TC-CF-UI-03 | Already-signed form shows response summary | Existing ConsentFormResponse record | GET /parent-portal/consent-forms/{form} where already signed | Response badge (Signed/Declined), signer_name, signed_at displayed; sign buttons hidden | — | ◌ | ⬜ |
| TC-CF-UI-04 | Closed form shows "Closed" label | Form past deadline OR status=Closed | View in list and detail | List shows form in Closed section; detail shows "Closed" message with no sign action | — | ◌ | ⬜ |
| TC-CF-UI-05 | Empty state when no forms exist | No published forms targeting child | GET /parent-portal/consent-forms | Empty state message shown | — | ◌ | ⬜ |

### 4.2 Validation (Field-Level) Tests

| TC ID | Test Case | Precondition | Input | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-VL-01 | response required | — | response empty | Validation error | — | ◌ | ⬜ |
| TC-CF-VL-02 | response must be Signed or Declined | — | response = "Approved" | Validation error: in:Signed,Declined | — | ◌ | ⬜ |
| TC-CF-VL-03 | signer_name required | — | signer_name empty | Validation error | — | ◌ | ⬜ |
| TC-CF-VL-04 | signer_name min 3 chars | — | signer_name = "AB" | Validation error: min:3 | — | ◌ | ⬜ |
| TC-CF-VL-05 | signer_name max 150 chars | — | signer_name = 151 chars | Validation error: max:150 | — | ◌ | ⬜ |
| TC-CF-VL-06 | decline_reason max 500 chars | response = Declined | Reason = 501 chars | Validation error: max:500 | — | ◌ | ⬜ |

### 4.3 Positive / Functional Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-PF-01 | Parent signs consent form | Published form within deadline, not yet signed | POST /consent-forms/{form}/sign with response=Signed, signer_name="Ramesh Sharma" | ConsentFormResponse created; redirect to list with success "Consent recorded. Thank you for signing." | — | ◌ | ⬜ |
| TC-CF-PF-02 | Parent declines consent form | allow_decline=true, within deadline | POST /sign with response=Declined, decline_reason="Not comfortable with the activity" | Response recorded as Declined; redirect with "Decline recorded. The school has been notified." | — | ◌ | ⬜ |
| TC-CF-PF-03 | Pending form appears in Pending section | Unsigned form within deadline | View list | Form displayed in Pending section | — | ◌ | ⬜ |
| TC-CF-PF-04 | Signed form appears in Signed section | Form already signed | View list | Form displayed in Signed section | — | ◌ | ⬜ |
| TC-CF-PF-05 | Closed unsigned form appears in Closed section | Form past deadline, unsigned | View list | Form displayed in Closed section | — | ◌ | ⬜ |
| TC-CF-PF-06 | Form targeting null class_id shown to all parents | Form with class_id=null | Access as parent of any class | Form visible | — | ◌ | ⬜ |

### 4.4 Negative / Error Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-NE-01 | Sign already-signed form | Existing ConsentFormResponse for (form, student, guardian) | POST /sign with same data | Error: "You have already responded to this form." | — | ◌ | ⬜ |
| TC-CF-NE-02 | Sign past-deadline form | Form deadline is past; status=Published | POST /sign | Error: "This consent form is closed and can no longer be signed." | — | ◌ | ⬜ |
| TC-CF-NE-03 | Decline when allow_decline=false | Form with allow_decline=0 | POST /sign with response=Declined | Error: "This form does not allow declining." | — | ◌ | ⬜ |
| TC-CF-NE-04 | Decline without decline_reason | allow_decline=true | POST /sign with response=Declined, reason empty | Error: "Decline reason is required." | — | ◌ | ⬜ |
| TC-CF-NE-05 | Sign with inactive form | Form with is_active=0 | Access GET /show or POST /sign | isFormEligible() returns false → 403 | — | ◌ | ⬜ |
| TC-CF-NE-06 | Access form not targeting child's class | Form with class_id different from child's class | GET /show | 403 "You do not have access to this consent form." | — | ◌ | ⬜ |

### 4.5 Security / Access Control Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-SC-01 | Unauthenticated access | No auth session | Access any consent form route | Redirected to login | — | ◌ | ⬜ |
| TC-CF-SC-02 | Sign for child of different class | Form targeting class X; child in class Y | POST /sign | isFormEligible() → 403 | — | ◌ | ⬜ |
| TC-CF-SC-03 | Unauthorized parent resolves to no guardian | User with no linked guardian record | Access any route | BaseRequest.authorize() fails → 403 | — | ◌ | ⬜ |
| TC-CF-SC-04 | IDOR — another guardian's signed form | Different guardian_id | (No direct IDOR — scoped by child via resolveChild) | Parent sees only forms for own linked children | — | ◌ | ⬜ |

### 4.6 Business Rule Tests

| TC ID | Test Case | BR | Steps | Expected Result | V | CR | Status |
|-------|-----------|-----|-------|-----------------|---|----|--------|
| TC-CF-BR-01 | No double-sign for same form+student+guardian | BR-PPT-014 | Sign same form twice | Second attempt blocked: "already responded" | — | ◌ | ⬜ |
| TC-CF-BR-02 | Two different guardians sign same form for same child | BR-PPT-014 | Guardian A signs; Guardian B signs | Both succeed (UNIQUE includes guardian_id) | — | ◌ | ⬜ |
| TC-CF-BR-03 | Response immutability — no soft deletes | BR-PPT-021 | Inspect table schema | ppt_consent_form_responses has NO deleted_at column | — | ◌ | ⬜ |

### 4.7 Integration / API Tests

| TC ID | Test Case | Precondition | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------------|-------|-----------------|---|----|--------|
| TC-CF-IN-01 | Activity log created on sign | — | POST /sign | sys_activity_logs entry with event=Signed/Declined, context includes student and form IDs | — | ◌ | ⬜ |

### 4.8 Performance / Load Tests

*(No performance tests defined.)*

### 4.9 Edge Case / Boundary Tests

| TC ID | Test Case | Steps | Expected Result | V | CR | Status |
|-------|-----------|-------|-----------------|---|----|--------|
| TC-CF-EC-01 | Form with deadline exactly now | Set deadline = current timestamp; sign immediately | isClosed() checks deadline->isPast(); borderline passes if deadline >= now | — | ◌ | ⬜ |
| TC-CF-EC-02 | Form targeting class+section with null section_id | class_id set, section_id null | isFormEligible matches entire class | Form visible to all children in that class | — | ◌ | ⬜ |
| TC-CF-EC-03 | Maximum signer_name length (150 chars) | Type 150-char name | Validation passes; field truncated to 150 | — | ◌ | ⬜ |
| TC-CF-EC-04 | Parent with no active child session | Child exists but no active class_section | Access list | Index resolves child; session=null; classId/sectionId null → only forms with null class_id are shown | — | ◌ | ⬜ |

---

## 5. Test Data Requirements

| Entity | Fields Required | Sample Data |
|--------|----------------|-------------|
| Parent (authenticated) | id, email | guardian@test.com |
| Child (student) | id, is_active=1 | student_id=1 |
| Guardian-Child Link | guardian_id, student_id, can_access_parent_portal=1 | jnt record |
| Class Section | id, class_id, section_id | class_section_id=1 |
| Consent Form | title, content, deadline, allow_decline, status_option_id (Published), class_id | Multiple variants |
| Consent Form Response | consent_form_id, student_id, guardian_id, response_option_id, signer_name | Sample responses |
| Dropdown Entries | ppt_consent_forms.status → Published, Closed, Draft | Seed data |
| Dropdown Entries | ppt_consent_form_responses.response → Signed, Declined | Seed data |

---

## 6. Environment & Setup

- **Backend:** Laravel 12, PHP 8.2+
- **Database:** MySQL 8, tenant_db with ppt_consent_forms, ppt_consent_form_responses tables
- **Auth:** Sanctum with web guard
- **Dropdown resolver:** PptDropdownResolver must have sys_dropdowns seeded for form status and response options
- **Dependencies:** SchoolSetup (sch_classes, sch_sections), StudentProfile (std_students, std_guardians)

---

## 7. Test Execution Notes

- POST /sign requires CSRF token
- Dropdown IDs must be resolved via PptDropdownResolver::id() — test environment must have seed data
- `signed_ip` is auto-recorded from request IP — verify in IPv4 and IPv6 environments
- Form eligibility = is_active AND (class_id null or matches child's class/section)
- Activity logging captures event = "Signed" or "Declined" based on response value

---

## 8. Known Issues

| # | Issue | Module | Severity | Status |
|---|-------|--------|----------|--------|
| KI-01 | `SignParentConsentFormRequest` does not enforce `decline_reason` min length (FRD says 10 chars) — controller only checks empty | ParentPortal | Low | Open |
| KI-02 | DDL declares `ppt_consent_forms.status` as ENUM, but Model uses `status_option_id` (dropdown FK) — mismatch | Database | Medium | Open |
| KI-03 | `signed_ip` is nullable in model but should always be populated | ParentPortal | Low | Open |
| KI-04 | PDF confirmation download not implemented | ParentPortal | Medium | Open |

---

## 9. Route Reference

| # | Method | URI | Name | Middleware |
|---|--------|-----|------|------------|
| 1 | GET | /parent-portal/consent-forms | parent-portal.consent-forms.index | auth, verified, ParentPortal |
| 2 | GET | /parent-portal/consent-forms/{consentForm} | parent-portal.consent-forms.show | auth, verified, ParentPortal |
| 3 | POST | /parent-portal/consent-forms/{consentForm}/sign | parent-portal.consent-forms.sign | auth, verified, ParentPortal |

Middleware stack: web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → ParentPortalMiddleware

---

## 10. Execution Status

| Test Suite | Total TC | Passed | Failed | Blocked | Skipped | Execution Date | Executed By |
|------------|----------|--------|--------|---------|---------|----------------|-------------|
| UI / View / Screen | 5 | — | — | — | — | — | — |
| Validation (Field-Level) | 6 | — | — | — | — | — | — |
| Positive / Functional | 6 | — | — | — | — | — | — |
| Negative / Error | 6 | — | — | — | — | — | — |
| Security / Access Control | 4 | — | — | — | — | — | — |
| Business Rules (BR) | 3 | — | — | — | — | — | — |
| Integration / API | 1 | — | — | — | — | — | — |
| Performance / Load | 0 | — | — | — | — | — | — |
| Edge Case / Boundary | 4 | — | — | — | — | — | — |
| **Total** | **35** | — | — | — | — | — | — |
