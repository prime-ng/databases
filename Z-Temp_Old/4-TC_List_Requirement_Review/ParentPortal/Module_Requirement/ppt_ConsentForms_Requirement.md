# Parent Portal — Digital Consent Forms Module Requirement

## 1. Module Overview

### 1.1 Purpose
The Digital Consent Forms feature enables schools to publish digital consent forms (field trips, activities, medical procedures, etc.) that parents view, sign (agree), or decline with a typed e-signature, IP address, and timestamp. Responses are legally immutable — no deletion or modification after submission. Deadlines are enforced; past-deadline forms show as "Closed."

### 1.2 Business Value
- Replaces paper consent slips with a fully digital, legally defensible workflow
- Immutable audit trail (signer_name + signed_ip + signed_at) for compliance
- Automated deadline enforcement — no manual follow-up to close forms
- Class/section targeting ensures the right parents receive the right forms
- Decline-with-reason captures parent objections explicitly

### 1.3 Scope
**In Scope:**
- List consent forms in three sections: Pending, Signed, Closed
- Class/section targeting (null = all classes, specific class, specific class+section)
- View consent form full content (HTML body)
- Sign (record typed name, IP, timestamp) or Decline (with required reason)
- Deadline enforcement — forms past deadline show as "Closed"; sign action blocked
- Allow_decline toggle — school controls whether decline is permitted
- Duplicate sign prevention via DB UNIQUE constraint
- Activity logging on all actions

**Out of Scope:**
- Consent form creation/editing/publishing (admin panel)
- PDF generation of signed forms (planned enhancement)
- Deadline reminder notifications (separate notification module)
- Admin response report (admin panel)

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Consent Form | Digital form issued by the school requiring parent authorization |
| Sign | Parent agrees to the consent form terms (e-signature) |
| Decline | Parent refuses consent, with required reason |
| e-Signature | Typed name + IP address + timestamp recorded as legal evidence |
| Immutable Response | Once submitted, response cannot be modified or deleted |
| Deadline | Date/time after which form closes and no responses accepted |

---

## 2. User Roles and Access

| Role | Capability |
|------|-----------|
| Parent / Guardian | View pending/signed/closed forms; sign or decline for own linked children |
| School Admin | Create, publish, close consent forms (admin panel) |
| System | Enforce deadline, prevent double-sign, record immutable audit trail |

---

## 3. Functional Requirements

### REQ-PPT-011: Digital Consent Forms
**Priority:** Standard (P1) | **Source:** FR-PPT-11 V2

**Description:** School publishes digital consent forms for events, trips, and activities. Parent views pending forms, reads the full content, and signs (agrees) or declines with a reason. Signed responses are immutable.

**Actors:** Initiates: School Admin (publish) | Signs: Parent | Notified: System + School Admin

**Business Rules:**
| BR | Rule |
|----|------|
| BR-PPT-014 | Parent cannot sign the same form twice — UNIQUE(consent_form_id, student_id, guardian_id) |
| BR-PPT-021 | Consent form responses are immutable — no deleted_at column; no delete or soft-delete |

**Acceptance Criteria:**
- AC1: Forms past their deadline show as "Closed" — sign action unavailable
- AC2: Signing records: signer name (typed), IP address, and exact timestamp — immutable from creation
- AC3: Parent cannot submit the same consent form twice — blocked by unique constraint with user-friendly error
- AC4: Declining a form requires a reason (minimum 10 chars enforced in controller logic)
- AC5: School admin can view which parents have/have not signed each form (admin panel)
- AC6: Push notification reminder 48h and 24h before deadline if unsigned (notification module)
- AC7: PDF copy of signed form downloadable (planned enhancement)

---

## 4. Business Rules Register

| ID | Rule | Enforcement Point |
|----|------|-------------------|
| BR-PPT-014 | No double-sign — UNIQUE(consent_form_id, student_id, guardian_id) | DB unique constraint + controller check |
| BR-PPT-021 | Responses immutable — no deleted_at on ppt_consent_form_responses | DB schema design |
| — | Only published/closed forms are visible to parents | Controller index query (status_option_id filter via PptDropdownResolver) |
| — | Form eligibility = class_id null OR matches child's class/section | isFormEligible() private method |
| — | signer_name required, min 3 chars | SignParentConsentFormRequest |
| — | decline_reason required when response=Declined | Controller inline check (empty validation) |
| — | allow_decline=false blocks decline action | Controller check |
| — | Closed form (deadline past or status=Closed) blocks sign | Controller + isClosed() model method |

---

## 5. Data Requirements

### Table: `ppt_consent_forms`
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | int unsigned PK | Yes | Auto-increment |
| title | varchar(200) | Yes | Form name |
| content | longtext | Yes | HTML body |
| class_id | int unsigned | No | FK → sch_classes.id; null = all classes |
| section_id | int unsigned | No | FK → sch_sections.id; null = all sections |
| deadline | timestamp | Yes | After this, form closes |
| allow_decline | tinyint(1) | Yes | Default 1 |
| status_option_id | int unsigned | Yes | FK → sys_dropdowns (Draft/Published/Closed) via PptDropdownResolver |
| is_active | tinyint(1) | Yes | Default 1 |
| created_by | int unsigned | No | FK → sys_users |
| created_at | timestamp | No | |
| updated_at | timestamp | No | |
| deleted_at | timestamp | No | SoftDeletes enabled |

### Table: `ppt_consent_form_responses` (IMMUTABLE — NO deleted_at)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | int unsigned PK | Yes | Auto-increment |
| consent_form_id | int unsigned | Yes | FK → ppt_consent_forms.id (CASCADE) |
| student_id | int unsigned | Yes | FK → std_students.id (CASCADE) |
| guardian_id | int unsigned | Yes | FK → std_guardians.id (CASCADE) |
| response_option_id | int unsigned | Yes | FK → sys_dropdowns (Signed/Declined) via PptDropdownResolver |
| decline_reason | text | No | Required when response=Declined |
| signer_name | varchar(150) | Yes | Typed e-signature |
| signed_ip | varchar(45) | No | IPv4/IPv6 |
| signed_at | timestamp | Yes | Business timestamp (immutable) |
| is_active | tinyint(1) | Yes | Default 1 |
| created_by | bigint unsigned | No | |
| created_at | timestamp | Yes | |
| updated_at | timestamp | Yes | |

**Key Constraints:**
- UNIQUE(consent_form_id, student_id, guardian_id) — BR-PPT-014
- NO deleted_at column — BR-PPT-021
- Foreign keys to sch_classes, sch_sections, sys_users on ppt_consent_forms
- Foreign keys to ppt_consent_forms, std_students, std_guardians on ppt_consent_form_responses

---

## 6. Workflow

### Workflow: Consent Form Signing (WF-5)
**Trigger:** Parent views unsigned consent form within deadline
**End States:** Signed (immutable), Declined (immutable)

| Step | Actor | Action |
|------|-------|--------|
| 1 | Parent | Open consent form; read full content |
| 2 | Parent | Click "I Agree" or "Decline" |
| 3 | System | Validate: not past deadline; not already signed; decline_reason provided if declining; allow_decline=true |
| 4 | System | Create ppt_consent_form_responses with signed_at, signed_ip, signer_name — immutable from this point |
| 5 | System | Notify school admin of response (via notification module) |

**Exception Path:** Past deadline → form shows as Closed; sign action unavailable with error message.
Double-sign attempt → DB constraint violation → "You have already responded to this form."
**Notifications:** Step 5 (admin: new response); 48h/24h pre-deadline reminder to parent if unsigned.

---

## 7. Finite State Machine (FSM)

### FSM: Consent Form Response States

| From State | Event | Guard | To State | Side-Effects |
|------------|-------|-------|----------|-------------|
| Unsigned | Parent signs | Within deadline; not already signed; signer_name valid | Signed | Immutable record created (signed_at + IP); school admin notified |
| Unsigned | Parent declines | Within deadline; not already responded; decline_reason provided | Declined | Immutable record created; school admin notified |
| Unsigned | Deadline passes | — | Closed | No action possible; form shows as "Closed" |
| Signed | — | — | (immutable terminal) | Cannot be updated, cancelled, or deleted |
| Declined | — | — | (immutable terminal) | |
| Closed | — | — | (terminal) | Read-only view only |

**Illegal transitions:** Any → deletion (no deleted_at column). Signed → Unsigned. Declined → Signed.

---

## 8. Screen Specifications

| Screen | Route | Controller@Method | View | Description |
|--------|-------|-------------------|------|-------------|
| Consent Forms List | GET /consent-forms | index | consent-forms/index | Three sections: Pending (signable), Signed (responded), Closed (past deadline, unsigned) |
| Consent Form Detail | GET /consent-forms/{consentForm} | show | consent-forms/show | Full form content, existing response (if any), sign/decline form |
| Sign Action | POST /consent-forms/{consentForm}/sign | sign | — | Processes sign or decline; redirects to list |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method |
|--------|-----|------|-------------------|
| GET | /consent-forms | consent-forms.index | ParentConsentFormController@index |
| GET | /consent-forms/{consentForm} | consent-forms.show | ParentConsentFormController@show |
| POST | /consent-forms/{consentForm}/sign | consent-forms.sign | ParentConsentFormController@sign |

All routes prefixed with `/parent-portal/consent-forms` and named with `parent-portal.consent-forms.` prefix.

---

## 10. Controller Analysis

### ParentConsentFormController

**Constructor Dependencies:**
- `ParentContextService` — resolves active child context

**Key Methods:**

| Method | Request | Authorization | Validation | Error Handling |
|--------|---------|---------------|------------|---------------|
| index | — | None (child scoped) | — | — |
| show | — | isFormEligible() abort_unless | Route model binding | 403 if not eligible |
| sign | SignParentConsentFormRequest | isFormEligible() abort_unless + BaseRequest authorize | response: Signed/Declined; signer_name: min:3 max:150; decline_reason: max:500 | Already responded → error; Closed form → error; allow_decline=false → error; decline_reason empty → error |

**Key Behavioral Rules:**
1. `isFormEligible()` checks: form.is_active AND (class_id null OR matches child class/section)
2. Index query filters: is_active=true AND status in [Published, Closed] (Dropdown resolved IDs)
3. Form targeting logic: null class_id → all; specific class_id + null section → whole class; specific class_id + section_id → section only
4. Existing responses keyed by consent_form_id for O(1) lookup in list
5. Pending = forms not yet responded AND not Closed
6. Signed = forms with existing response regardless of deadline
7. Closed = forms past deadline AND unsigned
8. Guardian ID resolved from auth user via `std_guardians.user_id` lookup
9. `signed_ip` recorded from `$request->ip()`

**Sign Method Flow:**
1. Check form eligibility (403 if not)
2. Check existing response (error if exists)
3. Check form not closed (error if closed)
4. If declined: check allow_decline (error if false) + decline_reason required
5. Resolve guardian_id from auth user
6. Create ConsentFormResponse with all fields
7. Log activity (Signed or Declined event)
8. Redirect to list with success message

---

## 11. Validation Rules & Edge Cases

| Field | Rules | Boundary | Invalid Example |
|-------|-------|----------|----------------|
| response | required, in:Signed,Declined | — | "Approved" |
| signer_name | required, string, min:3, max:150 | 3 chars = valid; 2 chars = invalid | "AB" (2 chars) |
| decline_reason | nullable, string, max:500 | Max 500 chars | — |

**Additional Controller-Level Validation:**
- decline_reason required (not just nullable) when response=Declined (controller enforces)
- allow_decline must be true when response=Declined (controller enforces)
- Form must not be closed (isClosed() check)
- No existing response for same (form, student, guardian)

**Edge Cases:**
- Form with allow_decline=false → "Declined" option may not be shown in UI; controller blocks anyway
- Form with deadline in past but status still "Published" → isClosed() checks both deadline and status
- Two parents of same child both sign the same form → both succeed (UNIQUE is on guardian_id, so each parent can have their own response)
- Two guardians with same user_id → both resolve to same guardian record
- form.deadline is null in DDL but marked NOT NULL — always present
- Accessing a form targeting a different class → 403 "You do not have access to this consent form."

---

## 12. Cross-Module Dependencies

| Module | Tables Used | Dependency Type |
|--------|-------------|-----------------|
| ParentPortal | ppt_consent_forms, ppt_consent_form_responses | Primary data |
| StudentProfile | std_students, std_guardians, std_student_guardian_jnt | Child ownership |
| SchoolSetup | sch_classes, sch_sections | Form targeting |
| Prime (Dropdown) | sys_dropdowns | Status/response option resolution |
| SysConfig | sys_users | Auth user lookup |

---

## 13. Known Issues / Gaps

| # | Gap Description | Severity | Impact | Status |
|---|----------------|----------|--------|--------|
| GI-01 | `SignParentConsentFormRequest` does not enforce `decline_reason` min length (FRD says 10 chars, controller checks only empty) | Low | Business rule deviation; only empty check exists | Open |
| GI-02 | DDL `ppt_consent_forms.status` = ENUM, but Model uses `status_option_id` (dropdown FK) — implementation mismatch from DDL | Medium | DDL designed as ENUM but code uses dropdown reference data | Open |
| GI-03 | No explicit Gate policy for consent form ownership | Low | Relies on isFormEligible() inline check | Open |
| GI-04 | PDF confirmation generation not implemented (FRD AC7) | Medium | Feature gap; signed confirmation not downloadable | Open |
| GI-05 | No deadline reminder notifications implemented in this module | Low | Delivered by external notification module | Open |
| GI-06 | `signed_ip` nullable in model but should be recorded in all cases | Low | Could be empty if IP not resolved | Open |

---

## 14. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-PPT-007 | Child ownership enforced via isFormEligible() |
| NFR-PPT-009 | CSRF protection on all POST routes |
| NFR-PPT-013 | All parent actions logged to sys_activity_logs |
| NFR-PPT-021 | Consent form responses immutable after creation |
| NFR-PPT-016 | Mobile-first responsive design |

---

## 15. Future Enhancements

| ID | Enhancement | Priority |
|----|------------|----------|
| ENH-01 | PDF confirmation download after signing | P1 |
| ENH-02 | Deadline reminder push notifications (48h + 24h) | P1 |
| ENH-03 | Admin response tracking dashboard (who signed/declined/pending) | P2 |
| ENH-04 | Bulk sending of forms to selected class groups | P2 |
| ENH-05 | Multi-language consent forms | P3 |

---

## 16. Traceability Matrix

| Requirement | BR | Screen | Workflow | Controller Method | Test Scope |
|-------------|----|--------|----------|-------------------|------------|
| List forms | — | Consent Forms List | — | index | Tab sections, targeting, deadline |
| View form detail | — | Consent Form Detail | WF-5 Step 1 | show | Content display, existing response |
| Sign form | BR-PPT-014 | Sign Action | WF-5 Step 2–4 | sign | Double-sign prevention, deadline |
| Decline form | BR-PPT-014, BR-PPT-021 | Sign Action | WF-5 Step 2–4 | sign | decline_reason, allow_decline |
| Immutable response | BR-PPT-021 | — | — | — | No deleted_at, no update |
| Form targeting | — | List/Detail | — | isFormEligible() | Class/section matching |
