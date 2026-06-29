# Certificate (CRT) — Complete FRD & Analysis Pack | 2026-06-29
**Module:** Certificate | **Code:** CRT | **Prefix:** `crt_` | **Type:** Tenant | **Database:** `tenant_db`
**Author:** Business Analyst (AI_Brain) | **Status:** v1.0 — single source of truth for downstream technical audit
**Sources read:** V2 requirement (`CRT_Certificate_Requirement.md`, 2026-03-26) · DDL (`Certificates_DDL_v1.sql`, 10 tables) · Tenant migrations (`database/migrations/tenant/` — 10 `crt_*` create migrations + 1 `std_students.tc_issued` alter) · Live code (`Modules/Certificate/` — 10 controllers, 10 models, 3 services, 10 FormRequests, 7 policies, 1 job, 4 seeders, 39 views) · Browser test suite (`tests/Browser/Modules/Certificate/` — 10 test classes, ~45 methods) · V1 screen-spec folder (`Certificate_v2/`, 13 screens) · Module Knowledge file (`CRT_Certificate.md`)

> **ID contract:** the `REQ-/BR-/RPT-/ENH-/NFR-/RISK-` IDs assigned here are **stable**. The DB Architect, Technical Auditor, Status Analyzer, and Testing Architect MUST reuse these IDs and never renumber them.

---

## Section 0 — Index / Table of Contents

| # | Section | Register |
|---|---------|----------|
| 1 | Module Overview (Purpose, Value, Scope In/Out, Terminology) | Business |
| 2 | User Roles & Access (Actors, Role–Feature Matrix) | Business |
| 3 | Functional Requirements (REQ-CRT-001…012) | Business |
| 4 | Business Rules Register (BR-CRT-001…020) | Business |
| 5 | Data Requirements (business entities + privacy) | Business |
| 6 | Workflows (4 process flows + exception paths) | Business |
| 7 | Reporting & Analytics (RPT-CRT-001…005 + KPIs) | Business |
| 8 | Future Enhancement Log (ENH-CRT-001…010) | Business |
| 9 | Non-Functional Requirements (NFR-CRT-001…013) | Business |
| 10 | Gap Analysis Readiness Index (coverage flags + totals) | Mixed |
| 11 | Requirements Traceability Matrix (RTM) | Mixed |
| 12 | Requirement Conditions Catalog (keyed to BR-) | Business |
| 13 | Validation & Edge-Case Catalog | Business |
| 14 | State Machine (FSM) Catalog | Business |
| 15 | Data Dictionary — Business View | Business |
| 16 | Cross-Module Dependency Map | Mixed |
| 17 | Risk Register (RISK-CRT-001…008) | Business |
| 18 | Prioritization (MoSCoW) & Effort / Sprint Tasks | Mixed |
| 19 | User Stories + Acceptance Criteria (Gherkin) | Business |
| 20 | Technical Data Dictionary (table→column→model) | **Technical** |

---

## Section 1 — Module Overview

### 1.1 Business Purpose
The Certificate module is the school's single, controlled factory for every official document it issues to students and staff — Bonafide certificates, Transfer Certificates, Character and Conduct certificates, Migration certificates, achievement and sports certificates, and student/staff identity cards. Today many schools produce these in ad-hoc word-processor templates, which leads to inconsistent wording, missing serial numbers, no central record of what was issued to whom, and documents that are trivially forged. This module standardises the templates, runs every request through an approval gate, stamps each document with a unique, tamper-evident verification code and a scannable QR code, and keeps a complete, auditable register of every certificate the school has ever issued.

### 1.2 Business Value
- **One trustworthy register:** every certificate — whether requested through the portal, issued directly by an administrator, or produced in a bulk batch — lands in a single searchable register with a unique number, issue date, and issuing authority.
- **Forgery-proof and verifiable anywhere:** a bank, embassy, or university can scan the QR code on any certificate and instantly confirm its authenticity on a public web page, without phoning the school.
- **Approval discipline:** sensitive documents (Transfer and Character certificates) only print after the right authority approves, and Transfer Certificates are blocked until fees are cleared.
- **Legal compliance:** a formal, gap-free Transfer Certificate register is maintained automatically, as required by Indian state education boards.
- **Time saved at scale:** hundreds of achievement certificates or ID cards can be produced in a single batch instead of one at a time.

### 1.3 Scope

**In scope**
1. Defining certificate types (category, approval requirement, validity, serial-number format).
2. Designing reusable HTML certificate templates with auto-filled merge fields, versioning, and a default template per type.
3. A certificate request workflow with submission, review, approval/rejection, and automatic generation.
4. Generation and issuance: unique numbering, QR embedding, PDF production, storage, revocation, and duplicate-copy handling.
5. Transfer Certificate handling: fee-clearance gate, the legally mandated TC register, and updating the student's leaving status.
6. Achievement certificates and asynchronous bulk generation for many students at once.
7. Digital verification: a no-login public verification page and a third-party verification interface protected by an access key.
8. ID card configuration and printable ID card sheets for students and staff.
9. A Document Management area for incoming student documents (birth certificate, previous TC, Aadhaar, etc.) with a verification status.
10. Reports: issued register, pending requests, type analytics, the TC register, and a verification activity log.
11. A simplified portal view for students and parents to request and download their own certificates.

**Out of scope**
1. Source student master data (names, photos, class, date of birth) — owned by **Student Profile**.
2. Class, section, and academic-session masters — owned by **School Setup**.
3. Fee balances and the rule that defines what "dues" means — owned by **Student Fee / Finance**; this module only reads the outstanding amount.
4. Email/SMS delivery infrastructure — owned by **Notification**.
5. The general school-leaving / withdrawal admission process and its own Transfer Certificate record — owned by **Admission** (see overlap note in Section 16).
6. Front-office walk-in certificate request intake — partially owned by **Front Office** (see overlap note in Section 16).

### 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| Certificate Type | A named category of document (Bonafide, Transfer Certificate, Character, etc.) with its own approval rule, validity, and numbering format. |
| Template | A reusable document layout with placeholders that the system fills with real student/school data at the moment of issue. |
| Merge Field | A placeholder inside a template (e.g. "student name", "class & section") replaced with actual data when the certificate is generated. |
| Certificate Request | A formal ask — from a student, parent, or staff member — for a particular certificate, which moves through an approval workflow. |
| Issued Certificate | A finished, numbered, PDF document recorded in the register, with a verification code. |
| Verification Code | A tamper-evident code unique to each certificate, used by the QR code and the public verification page to confirm authenticity. |
| Transfer Certificate (TC) | A legally mandated leaving document issued when a student departs the school. |
| TC Register | The formal, sequential, gap-free logbook of all Transfer Certificates required by state boards. |
| Serial Counter | The per-type, per-year counter that guarantees sequential, gap-free certificate numbers. |
| Bulk Job | A background task that produces certificates for many students at once and bundles them into a downloadable archive. |
| Revocation | Marking an already-issued certificate as invalid without deleting it; verification then reports it as "revoked". |
| Duplicate Copy | A re-issue of a certificate already given to the same person for the same type; it carries a visible "DUPLICATE COPY" watermark. |
| Document Management (DMS) | The area where incoming student documents are uploaded, categorised, and marked verified or rejected. |
| ID Card Configuration | The saved layout (size, orientation, field positions, QR placement) used to print student or staff identity cards. |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions

| Role | Who They Are | Relationship to This Module |
|------|-------------|----------------------------|
| School Admin | The school's system administrator/office head | Full control: configures types and templates, approves requests, issues and revokes certificates, runs bulk jobs, manages DMS, views all reports. |
| Principal | The school's head of institution | Final approving authority for Transfer and Character certificates; the named signing authority printed on documents. |
| Clerk / Front Office | Administrative office staff | Submit requests on behalf of walk-in students/parents, upload incoming documents, record physical handover of issued certificates. |
| Class Teacher | A teacher responsible for a class | Views certificates issued to students of their own class (read-only). |
| Student | An enrolled student (portal user) | Submits requests for their own certificates and downloads their own issued documents. |
| Parent | A guardian (portal user) | Submits requests for their ward and downloads the ward's issued documents. |
| Third Party / External | A bank, embassy, university, or employer | Uses only the public verification page or the keyed verification interface; no login, no access to school data. |
| System | The platform acting automatically | Generates certificate numbers, embeds QR codes, dispatches bulk jobs, records verification activity, and sends notifications. |

### 2.2 Role-Feature Access Matrix

| Feature | School Admin | Principal | Clerk / Front Office | Class Teacher | Student / Parent | Third Party |
|---------|--------------|-----------|----------------------|---------------|------------------|-------------|
| Certificate Type setup | Full | View | No Access | No Access | No Access | No Access |
| Template design & versions | Full | View | No Access | No Access | No Access | No Access |
| Submit certificate request | Full | Full | Full (on behalf) | No Access | Own / Ward only | No Access |
| Approve / Reject request | Full | Full (TC, Character) | No Access | No Access | No Access | No Access |
| Generate / Issue certificate | Full | Full | Issue & record handover | No Access | No Access | No Access |
| Revoke certificate | Full | Full | No Access | No Access | No Access | No Access |
| Transfer Certificate & TC register | Full | Full (authorises) | View | No Access | No Access | No Access |
| Bulk / Achievement generation | Full | View | No Access | No Access | No Access | No Access |
| ID card config & printing | Full | View | Print | No Access | No Access | No Access |
| Document Management (DMS) | Full | View | Upload | No Access | No Access | No Access |
| Public / keyed verification | View | View | View | View | View | Verify only |
| Reports & verification log | Full | View | View | Own class only | No Access | No Access |
| Portal — own certificates | n/a | n/a | n/a | n/a | Own / Ward | No Access |

> Multi-tenancy: each school's certificate data lives in its own database; cross-school access is structurally impossible. Permissions above are enforced per-school.

---

## Section 3 — Functional Requirements

### 3.1 Certificate Type Management
**Requirement ID:** REQ-CRT-001
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION]

#### Business Description
The School Admin defines each kind of certificate the school issues. Each type carries a short unique code, a category (administrative, legal, character, achievement, or identity), whether it needs approval before printing, an optional validity period, and the format used to build its serial numbers. Types can be switched off so they stop appearing on the request form without losing any historical records. Every type is the anchor for its templates, requests, issued certificates, and serial counters.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Principal (view), portal users (see only active, portal-eligible types)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-004 | Each certificate type's code is unique within the school (max 10 characters, alphanumeric); a duplicate code is rejected. | Validation |
| BR-CRT-016 | Switching a type to inactive hides it from the request form but preserves all existing records and history. | Workflow |
| BR-CRT-017 | A certificate type that has issued certificates cannot be permanently deleted; only soft-deletion/deactivation is allowed. | Workflow |

#### Acceptance Criteria
1. A new type can be created with a name, unique code, category, approval flag, optional validity, and serial format; a duplicate code is rejected with a clear message.
2. Setting "requires approval" to off causes future requests of that type to skip the approval queue and proceed straight to generation.
3. A type with no validity period produces certificates that never expire; a type with a validity period produces certificates that auto-expire after that many days.
4. Deactivating a type removes it from the portal request form but leaves its issued certificates fully accessible.

#### Integration with Other Modules
- Receives from: None (self-contained master).
- Sends to: drives REQ-CRT-002 (templates), REQ-CRT-003/004 (requests/issuance), REQ-CRT-010 (numbering).

#### Enhancement Notes (Future)
Seed a starter library of common types so a new school is not faced with a blank screen (see ENH-CRT-003).

---

### 3.2 Certificate Template Designer
**Requirement ID:** REQ-CRT-002
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION]

#### Business Description
The School Admin designs the visual layout of each certificate as a reusable template containing placeholders (such as student name, class & section, date of birth, certificate number, issue date, principal name, school name). Page size, orientation, and an optional signature-block position are configurable. Each time a template is saved, the previous content is archived as an immutable version so the school can see its history and restore an earlier version. Exactly one template per type is marked the default used for generation, and templates can be previewed against sample data before use.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Principal (view)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-006 | A template that is referenced by any issued certificate cannot be permanently deleted. | Workflow |
| BR-CRT-012 | At most one template per certificate type may be the default at any time; marking one default automatically clears the previous default. | Workflow |
| BR-CRT-018 | Every placeholder used in the template body must be declared in the template's variable list; an undeclared placeholder is rejected on save. | Validation |
| BR-CRT-019 | Saving an edited template first archives the current content as a new version before overwriting; archived versions are never altered or deleted (except when the whole template is removed). | Workflow |

#### Acceptance Criteria
1. A template can be created and edited with body content, declared variables, page size, orientation, and optional signature placement.
2. Saving an edit creates a new archived version with an incremented version number; the version history is viewable and any prior version can be restored.
3. Marking a template as default clears the default flag on all other templates of the same type.
4. A preview renders the template filled with sample student data as a PDF.
5. Attempting to permanently delete a template that has issued certificates is blocked.

#### Integration with Other Modules
- Receives from: School Setup / Student Profile (sample data for preview).
- Sends to: REQ-CRT-004 (generation uses the default template).

#### Enhancement Notes (Future)
Ship board-specific TC templates and a starter template marketplace (ENH-CRT-003, ENH-CRT-009).

---

### 3.3 Certificate Request Workflow
**Requirement ID:** REQ-CRT-003
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [APPROVAL] [NOTIFICATION]

#### Business Description
Students, parents, or staff submit a request for a certificate, stating its purpose and optionally attaching a supporting document. Each request receives an auto-generated request number and enters a status lifecycle: pending → under review → approved or rejected → generated → issued. The Admin or Principal reviews the request, checks eligibility, and either approves it (which triggers generation) or rejects it with a mandatory reason. Requesters can track progress, and the system notifies them at key stages.

#### Actors
- **Initiates:** Student, Parent, Clerk, or Admin
- **Processes / Approves:** School Admin, Principal
- **Views / Receives notification:** Requester (status updates)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-013 | Rejecting a request requires a rejection reason; rejection without a reason is blocked. | Validation |
| BR-CRT-014 | Supporting documents are stored against the request as attachments (PDF/image, size-limited). | Validation |
| BR-CRT-020 | When the type does not require approval, a submitted request advances straight to approved and generation is triggered automatically. | Workflow |
| BR-CRT-021 | A second pending/under-review/approved request for the same student and same certificate type is blocked as a duplicate. | Validation |

#### Acceptance Criteria
1. Submitting a request produces a unique, year-wise sequential request number.
2. A request for a non-approval type advances immediately to approved and generation begins.
3. An approver can add optional remarks on approval; a rejecter must enter a reason or the rejection is blocked.
4. A duplicate active request for the same student and type is refused with a clear message.
5. The requester can see the current status and the timestamp of each stage.

#### Integration with Other Modules
- Receives from: Student Profile (beneficiary student), System Media (attachments).
- Sends to: Notification (submission, approval, rejection); REQ-CRT-004 (generation on approval).

#### Enhancement Notes (Future)
Auto-link a duplicate request to the original issued certificate (ENH-CRT-007).

---

### 3.4 Certificate Generation & Issuance
**Requirement ID:** REQ-CRT-004
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [DATA_ENTRY]

#### Business Description
On approval (or on direct issue for achievement types), the system assembles the certificate: it resolves all merge fields from the student and school records, allocates the next sequential certificate number, computes a tamper-evident verification code, embeds a QR code, renders the chosen template to a PDF, stores the file, and records the issued certificate in the register. Issued certificates can be downloaded by authorised users and can be revoked. A re-issue to the same person for the same type is flagged a duplicate and watermarked.

#### Actors
- **Initiates:** School Admin (approval or direct issue), System (on auto-approval)
- **Processes / Approves:** System
- **Views / Receives notification:** Requester, Admin, authorised viewers

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-003 | A second issuance of the same type to the same recipient is marked a duplicate and rendered with a "DUPLICATE COPY" watermark. | Workflow |
| BR-CRT-004 | The certificate number is unique within the school and follows the type's configured format. | Validation |
| BR-CRT-005 | A revoked certificate remains in the register; verification reports it as "revoked" rather than "not found". | Workflow |
| BR-CRT-015 | Certificate numbers are allocated using a locked, transactional counter so that simultaneous generation never produces duplicate or out-of-sequence numbers. | Concurrency |
| BR-CRT-022 | A revoked or not-yet-issued certificate cannot be downloaded; downloads are restricted to issued, non-revoked certificates and to authorised users. | Permission |

#### Acceptance Criteria
1. A generated certificate has a unique number in the configured format and a unique verification code.
2. The merge fields (name, class & section, dates, school details) appear correctly filled in the PDF.
3. The PDF is stored and downloadable by authorised users; each download is recorded in the audit trail.
4. Revoking a certificate records who revoked it, when, and why, and verification then reports it revoked.
5. A re-issue to the same recipient and type is flagged duplicate and carries the watermark.

#### Integration with Other Modules
- Receives from: Student Profile, School Setup (merge data); Verification service (code + QR).
- Sends to: Audit Log (download/issue events); REQ-CRT-007 (verification).

#### Enhancement Notes (Future)
Notify before a dated certificate expires (ENH-CRT-005); DigiLocker sync (ENH-CRT-001).

---

### 3.5 Transfer Certificate (TC)
**Requirement ID:** REQ-CRT-005
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [APPROVAL] [INTEGRATION]

#### Business Description
The Transfer Certificate is a legally mandated leaving document. It can only be issued after the student's fees are cleared (unless an administrator records a justified override), and after any rejected incoming documents are resolved. On issue, the system creates a formal, sequential, gap-free entry in the TC register capturing all state-board-required fields, marks the student as having been issued a TC, and updates the student's status to withdrawn.

#### Actors
- **Initiates:** School Admin / Clerk (request); Principal (authorises)
- **Processes / Approves:** Principal, School Admin
- **Views / Receives notification:** Requester, Office

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-001 | A Transfer Certificate cannot be generated while the student has outstanding fees, unless an administrator records an override justification. | Validation |
| BR-CRT-002 | TC register serial numbers are sequential and year-wise with no gaps. | Concurrency |
| BR-CRT-008 | A student with any rejected incoming document cannot be issued a Transfer Certificate until the document is resolved. | Validation |
| BR-CRT-011 | Once a TC is issued, the student is marked as TC-issued and their status changes to withdrawn. | Workflow |
| BR-CRT-023 | Date of leaving and reason for leaving are mandatory inputs for a Transfer Certificate. | Validation |

#### Acceptance Criteria
1. TC generation is blocked when fees are outstanding and proceeds only with a recorded override justification.
2. A TC register entry is created automatically on issue, with a sequential, gap-free serial number for the year.
3. Date of leaving and reason for leaving must be supplied or generation is blocked.
4. After issue, the student is flagged TC-issued and their status becomes withdrawn.
5. The TC register can be viewed and printed as a formal table.

#### Integration with Other Modules
- Receives from: Student Fee / Finance (outstanding amount); Student Profile (snapshot data).
- Sends to: Student Profile (TC-issued flag, withdrawn status); Audit Log.

#### Enhancement Notes (Future)
Board-specific TC formats (ENH-CRT-009). **Open governance question (Q-CRT-1):** reconcile with the Admission module's separate Transfer Certificate record — see Section 16.

---

### 3.6 Achievement & Bulk Certificates
**Requirement ID:** REQ-CRT-006
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [SCHEDULED]

#### Business Description
The School Admin can issue achievement, sports, merit, or participation certificates directly — without a prior request or approval — to a single student or to many at once. Bulk generation runs as a background task that produces each certificate, bundles them into a downloadable archive, and reports progress. Individual failures inside a batch are logged and do not stop the rest of the batch.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** System (background worker)
- **Views / Receives notification:** School Admin (progress, completion)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-009 | A bulk generation of more than 200 certificates must run as a background task; synchronous processing above that threshold is forbidden. | Workflow |
| BR-CRT-024 | An individual student's failure within a bulk batch is logged and the batch continues for the remaining students. | Workflow |

#### Acceptance Criteria
1. An achievement certificate can be issued directly to a student without any request workflow.
2. A bulk run accepts a type plus a class/section and/or an explicit list of students.
3. A bulk run above 200 certificates is dispatched to the background queue rather than processed immediately.
4. On completion, a downloadable archive of the certificates is available and progress can be polled while running.
5. A failure on one student is recorded in the job's error log and the remaining students still succeed.

#### Integration with Other Modules
- Receives from: Student Profile, School Setup (class/section filters).
- Sends to: REQ-CRT-004 (per-certificate generation); Audit Log.

#### Enhancement Notes (Future)
Browser preview of the printable sheet before committing (ENH-CRT-008).

---

### 3.7 Digital Verification (QR + Keyed Interface)
**Requirement ID:** REQ-CRT-007
**Priority:** Core (P0)
**Category Tags:** [INTEGRATION] [DASHBOARD]

#### Business Description
Every issued certificate carries a QR code that points to a no-login public verification page. The page reports whether the certificate is valid, expired, or revoked, and shows only minimal, privacy-safe details. A keyed verification interface lets approved third-party institutions check certificates programmatically. Every verification attempt is recorded for audit, and the public page is rate-limited to deter scraping.

#### Actors
- **Initiates:** Third party (scan or keyed call)
- **Processes / Approves:** System
- **Views / Receives notification:** School Admin (verification log)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-010 | The public verification result must not expose the full name, date of birth, class, or address; it shows only first name + last initial, certificate type, school name, issue date, and status. | Permission |
| BR-CRT-025 | Every verification attempt (found, not found, revoked, expired) is recorded with the time, originating address, and result. | Workflow |
| BR-CRT-026 | The public verification page is rate-limited per originating address to prevent bulk enumeration. | Permission |
| BR-CRT-027 | The keyed third-party verification interface rejects calls without a valid access key. | Permission |

#### Acceptance Criteria
1. Scanning a certificate's QR code opens the public page and shows valid / expired / revoked correctly.
2. The public page never shows full name, date of birth, class, or address.
3. A revoked certificate shows "revoked" rather than "not found".
4. Every verification attempt is recorded in the verification activity log, which the Admin can filter by date and result.
5. Repeated rapid requests from one address are throttled.

#### Integration with Other Modules
- Receives from: None (reads own register).
- Sends to: Audit Log (verification events).

#### Enhancement Notes (Future)
Per-IP hourly rate limit tuning (ENH-CRT-006). **Note:** the keyed third-party interface is currently a non-functional placeholder — see Section 10 and Section 16.

---

### 3.8 ID Card Generation
**Requirement ID:** REQ-CRT-008
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION] [REPORT]

#### Business Description
The School Admin defines ID card layouts for students and staff — choosing card size, orientation, field positions, colours, and QR placement, tied to an academic session. The system then produces printable ID card sheets, arranging multiple cards per page. Student cards include photo, name, class & section, admission number, blood group (when available), and a QR code; staff cards include photo, name, designation, and employee identifier.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin, Clerk (printing)
- **Views / Receives notification:** Office

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-007 | ID cards must display the blood group when it is present in the student profile, and leave the field blank (not hidden) when it is absent. | Validation |
| BR-CRT-028 | The printable sheet arranges cards in a grid according to the configured cards-per-sheet (and card size). | Calculation |

#### Acceptance Criteria
1. A card configuration can be created for students or staff with size, orientation, layout, and cards-per-sheet, tied to a session.
2. A printable ID card sheet is produced with photos embedded (a placeholder shown when no photo exists) and a QR code per card.
3. Blood group is shown when present and left blank when absent.
4. Cards are arranged in the configured grid on the sheet.

#### Integration with Other Modules
- Receives from: Student Profile (photo, blood group, identifiers), School Setup (session).
- Sends to: None.

#### Enhancement Notes (Future)
Handover tracking — recording which student physically received their card — is desired but **not yet provided** (no data store exists for it); see ENH-CRT-011 and Section 10.

---

### 3.9 Document Management System (DMS)
**Requirement ID:** REQ-CRT-009
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description
The office uploads incoming student documents — birth certificate, previous Transfer Certificate, migration certificate, caste/disability certificates, Aadhaar, photos — categorises them, and stores them against the student. An administrator reviews each document and marks it verified or rejected (with mandatory remarks on rejection). A document's verification status feeds the certificate eligibility checks, most importantly the Transfer Certificate gate.

#### Actors
- **Initiates:** Clerk / School Admin (upload)
- **Processes / Approves:** School Admin (verify/reject)
- **Views / Receives notification:** Office

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-029 | Only allowed document formats up to the size limit may be uploaded. | Validation |
| BR-CRT-030 | Rejecting a document requires remarks; a rejected document cannot satisfy any certificate eligibility check until resolved. | Validation |

#### Acceptance Criteria
1. A document can be uploaded with a category drawn from the configured category list and stored against the student.
2. An administrator can mark a document verified, or rejected with mandatory remarks.
3. A rejected document blocks the dependent certificate eligibility check (e.g. Transfer Certificate).
4. Document downloads are recorded in the audit trail.

#### Integration with Other Modules
- Receives from: Student Profile (student), System Dropdowns (categories), System Media (file storage).
- Sends to: REQ-CRT-005 (TC eligibility gate).

#### Enhancement Notes (Future)
Bulk upload via an archive + mapping file for annual admissions (ENH-CRT-010).

---

### 3.10 Certificate Number Format Configuration
**Requirement ID:** REQ-CRT-010
**Priority:** Standard (P1)
**Category Tags:** [CONFIGURATION]

#### Business Description
The School Admin can configure the serial-number format per certificate type using tokens for the type code, full and short year, and 4- or 6-digit sequence. The counter resets each year, and the admin can preview a sample number before saving. This lets the school match the numbering conventions different boards expect.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** System (number allocation)
- **Views / Receives notification:** School Admin

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-031 | The serial counter is maintained per type per year and resets at the start of each year. | Calculation |
| (cross-ref) BR-CRT-015 | Number allocation is transactional and locked to guarantee gap-free sequences. | Concurrency |

#### Acceptance Criteria
1. A type's serial format can be set using the supported tokens, with a default of type-code + year + 6-digit sequence.
2. A sample number is previewed from the chosen format before saving.
3. Each new year starts the sequence afresh for that type.

#### Integration with Other Modules
- Receives from: REQ-CRT-001 (type code).
- Sends to: REQ-CRT-004 (number allocation).

#### Enhancement Notes (Future)
Different formats per board profile (ENH-CRT-002).

---

### 3.11 Reports & Analytics
**Requirement ID:** REQ-CRT-011
**Priority:** Standard (P1)
**Category Tags:** [REPORT] [DASHBOARD]

#### Business Description
The module provides an issued-certificates register (filterable and exportable), a pending-requests report that highlights overdue requests, a type-analytics view showing volume by type and over time, the formal TC register print, and a verification activity log. All reports are confined to the school's own data.

#### Actors
- **Initiates:** School Admin, Principal
- **Processes / Approves:** System
- **Views / Receives notification:** Admin, Principal, Class Teacher (own class)

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CRT-032 | Reports are confined to the school's own data with no cross-school leakage. | Permission |
| BR-CRT-033 | The pending-requests report highlights requests past their required-by date. | Calculation |

#### Acceptance Criteria
1. The issued register can be filtered (type, date range, class/section) and exported.
2. The pending report highlights overdue requests distinctly.
3. The type-analytics view shows counts by type and a time trend.
4. The TC register is available as a formatted, printable table.
5. The verification activity log is filterable by date and result.

#### Integration with Other Modules
- Receives from: own register and request data.
- Sends to: None.

#### Enhancement Notes (Future)
None.

---

### 3.12 Student & Parent Portal Access
**Requirement ID:** REQ-CRT-012
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW]

#### Business Description
Students and parents access a simplified view to submit requests, track status in real time, and download their own (or their ward's) issued certificates. They can only ever see their own records, and can only download certificates that are issued and not revoked.

#### Actors
- **Initiates:** Student, Parent
- **Processes / Approves:** System
- **Views / Receives notification:** Student, Parent

#### Business Rules
| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| (cross-ref) BR-CRT-022 | Download is available only for issued, non-revoked certificates. | Permission |
| BR-CRT-034 | A portal user sees only their own (or their ward's) requests and certificates; other students' records are never visible. | Permission |

#### Acceptance Criteria
1. A portal user sees only their own/ward's requests and issued certificates.
2. A new request can be submitted choosing from active, portal-eligible types.
3. Download is offered only when a certificate is issued and not revoked.
4. Each request shows its current status and per-stage timestamps.

#### Integration with Other Modules
- Receives from: Student Profile (identity), REQ-CRT-003/004.
- Sends to: REQ-CRT-003 (request submission).

#### Enhancement Notes (Future)
None — depends on the Student Portal module being delivered.

---

## Section 4 — Business Rules Register

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-CRT-001 | A Transfer Certificate cannot be generated while the student has outstanding fees, unless an administrator records an override justification. | REQ-CRT-005 | Validation | P0 |
| BR-CRT-002 | TC register serial numbers are sequential and year-wise with no gaps. | REQ-CRT-005 | Concurrency | P0 |
| BR-CRT-003 | A second issuance of the same type to the same recipient is marked duplicate and watermarked "DUPLICATE COPY". | REQ-CRT-004 | Workflow | P1 |
| BR-CRT-004 | Certificate number is unique within the school and follows the type's configured format. | REQ-CRT-004 | Validation | P0 |
| BR-CRT-005 | A revoked certificate stays in the register; verification reports "revoked", not "not found". | REQ-CRT-004 | Workflow | P0 |
| BR-CRT-006 | A template referenced by any issued certificate cannot be permanently deleted. | REQ-CRT-002 | Workflow | P1 |
| BR-CRT-007 | ID cards display blood group when present and leave it blank when absent. | REQ-CRT-008 | Validation | P1 |
| BR-CRT-008 | A student with any rejected incoming document cannot be issued a Transfer Certificate until resolved. | REQ-CRT-005, REQ-CRT-009 | Validation | P1 |
| BR-CRT-009 | A bulk generation of more than 200 certificates must run as a background task. | REQ-CRT-006 | Workflow | P1 |
| BR-CRT-010 | Public verification must not expose full name, date of birth, class, or address. | REQ-CRT-007 | Permission | P0 |
| BR-CRT-011 | Once a TC is issued, the student is marked TC-issued and their status changes to withdrawn. | REQ-CRT-005 | Workflow | P0 |
| BR-CRT-012 | At most one default template per type; marking one default clears the previous. | REQ-CRT-002 | Workflow | P0 |
| BR-CRT-013 | Rejecting a request requires a rejection reason. | REQ-CRT-003 | Validation | P0 |
| BR-CRT-014 | Supporting documents are stored as request attachments (format/size limited). | REQ-CRT-003 | Validation | P1 |
| BR-CRT-015 | Certificate numbers are allocated via a locked, transactional counter to prevent duplicates/gaps. | REQ-CRT-004, REQ-CRT-010 | Concurrency | P0 |
| BR-CRT-016 | Deactivating a type hides it from the request form but preserves history. | REQ-CRT-001 | Workflow | P1 |
| BR-CRT-017 | A type with issued certificates cannot be permanently deleted. | REQ-CRT-001 | Workflow | P1 |
| BR-CRT-018 | Every placeholder used in a template must be declared in its variable list. | REQ-CRT-002 | Validation | P1 |
| BR-CRT-019 | Editing a template archives the prior content as an immutable version before overwriting. | REQ-CRT-002 | Workflow | P1 |
| BR-CRT-020 | When a type needs no approval, a submitted request advances straight to approved and generation triggers. | REQ-CRT-003 | Workflow | P0 |
| BR-CRT-021 | A second active request for the same student and type is blocked as a duplicate. | REQ-CRT-003 | Validation | P1 |
| BR-CRT-022 | Only issued, non-revoked certificates may be downloaded, and only by authorised users. | REQ-CRT-004, REQ-CRT-012 | Permission | P0 |
| BR-CRT-023 | Date of leaving and reason for leaving are mandatory for a Transfer Certificate. | REQ-CRT-005 | Validation | P1 |
| BR-CRT-024 | An individual failure in a bulk batch is logged and the batch continues. | REQ-CRT-006 | Workflow | P1 |
| BR-CRT-025 | Every verification attempt is recorded with time, address, and result. | REQ-CRT-007 | Workflow | P1 |
| BR-CRT-026 | The public verification page is rate-limited per originating address. | REQ-CRT-007 | Permission | P1 |
| BR-CRT-027 | The keyed third-party verification interface rejects calls without a valid access key. | REQ-CRT-007 | Permission | P1 |
| BR-CRT-028 | The printable ID sheet arranges cards per the configured cards-per-sheet and size. | REQ-CRT-008 | Calculation | P1 |
| BR-CRT-029 | Only allowed document formats up to the size limit may be uploaded. | REQ-CRT-009 | Validation | P1 |
| BR-CRT-030 | Rejecting a document requires remarks; a rejected document blocks dependent eligibility checks. | REQ-CRT-009 | Validation | P1 |
| BR-CRT-031 | The serial counter is per type per year and resets each year. | REQ-CRT-010 | Calculation | P1 |
| BR-CRT-032 | Reports are confined to the school's own data. | REQ-CRT-011 | Permission | P0 |
| BR-CRT-033 | The pending report highlights requests past their required-by date. | REQ-CRT-011 | Calculation | P2 |
| BR-CRT-034 | A portal user sees only their own/ward's records. | REQ-CRT-012 | Permission | P0 |

**Total business rules: 34** (BR-CRT-001 … BR-CRT-034).

---

## Section 5 — Data Requirements

### 5.1 Certificate Type
**What it represents:** A named category of document the school issues, with its own rules.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Name / Code | Display name and unique short code | Yes | Code unique, max 10 chars (BR-CRT-004) |
| Category | Administrative / Legal / Character / Achievement / Identity | Yes | Config-driven set |
| Requires approval | Whether requests need approval | Yes | Drives workflow (BR-CRT-020) |
| Validity period | Days until expiry; blank = no expiry | No | Drives certificate expiry |
| Serial format | Token pattern for numbering | Yes | Defaults provided (REQ-CRT-010) |
| Active flag | Whether shown on request form | Yes | BR-CRT-016 |
**Relationships:** Contains templates, serial counters; referenced by requests and issued certificates.
**Data Retention:** Retained indefinitely; soft-deletable; cannot be permanently removed once it has issued certificates.
**Privacy Classification:** Internal.

### 5.2 Certificate Template
**What it represents:** A reusable document layout with merge placeholders.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Template body | Layout content with placeholders | Yes | Placeholders must be declared (BR-CRT-018) |
| Declared variables | List of placeholders used | Yes | |
| Page size / orientation | Print dimensions | Yes | |
| Signature placement | Optional signature-block position | No | |
| Default flag | Whether this is the type's default | Yes | One per type (BR-CRT-012) |
| Version number | Current version | Yes | Prior content archived (BR-CRT-019) |
**Relationships:** Belongs to a type; contains immutable archived versions; referenced by issued certificates.
**Data Retention:** Templates soft-deletable unless referenced by issued certificates; versions are immutable and never soft-deleted.
**Privacy Classification:** Internal.

### 5.3 Certificate Request
**What it represents:** A formal ask for a certificate moving through approval.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Request number | Year-wise unique reference | Yes | Auto-generated |
| Type | The certificate type requested | Yes | |
| Requester / Beneficiary | Who asked / which student it is for | Yes / Conditional | Beneficiary blank for staff certs |
| Purpose | Stated reason | Yes | |
| Required-by date | Desired delivery date | No | Drives urgency (BR-CRT-033) |
| Supporting attachment | Optional uploaded document | No | BR-CRT-014 |
| Status | pending → under review → approved/rejected → generated → issued | Yes | FSM (Section 14) |
| Approval / Rejection details | Approver, time, remarks, rejection reason | Conditional | Reason mandatory on reject (BR-CRT-013) |
**Relationships:** Belongs to a type and a student; produces an issued certificate.
**Data Retention:** Retained; soft-deletable.
**Privacy Classification:** Confidential (links a named student to a purpose).

### 5.4 Issued Certificate
**What it represents:** A finished, numbered certificate recorded in the register.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Certificate number | Unique serial | Yes | BR-CRT-004 |
| Type / Template | Origin definitions | Yes | |
| Recipient | Student or staff (by type) | Yes | |
| Issue / Validity dates | When issued / when it expires | Yes / No | Blank validity = no expiry |
| Verification code | Tamper-evident code | Yes | Unique; powers QR verification |
| File reference | Location of the stored PDF | Yes | |
| Revocation details | Revoked flag, time, who, reason | Conditional | BR-CRT-005 |
| Duplicate flag | Whether this is a re-issue | Yes | BR-CRT-003 |
**Relationships:** Belongs to a type, template, optional request; may have one TC register entry.
**Data Retention:** Never hard-deleted; revocation replaces deletion.
**Privacy Classification:** Confidential.

### 5.5 TC Register Entry
**What it represents:** The legal, sequential logbook line for a Transfer Certificate.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Serial number / Year | Gap-free yearly sequence | Yes | BR-CRT-002 |
| Student snapshot | Name, father's name, date of birth | Yes / Yes / Yes | Snapshot at issue |
| Class at leaving | Class & section when leaving | Yes | |
| Admission / Leaving dates | Original join and leaving date | Yes | |
| Conduct | Conduct remark | Yes | Defaults to "Good" |
| Reason for leaving | Mandatory reason | Yes | BR-CRT-023 |
| Duplicate-entry flag | Whether for a re-issued TC | Yes | |
| Prepared by | Authorising officer | Yes | |
**Relationships:** Belongs to one issued certificate.
**Data Retention:** Legally mandated; never delete.
**Privacy Classification:** Confidential / Sensitive.

### 5.6 Serial Counter
**What it represents:** The per-type, per-year number allocator.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Type / Year | The counter's scope | Yes | One per type per year |
| Last sequence number | Highest number issued so far | Yes | Locked on increment (BR-CRT-015) |
**Relationships:** Belongs to a type.
**Data Retention:** Retained; resets yearly.
**Privacy Classification:** Internal.

### 5.7 Bulk Job
**What it represents:** A background batch-generation task and its progress.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Type / Filter | What and for whom | Yes | Class/section/student list |
| Counts | Total / processed / failed | Yes | |
| Status | queued → processing → completed/failed | Yes | FSM (Section 14) |
| Archive reference | Location of the result archive | Conditional | On completion |
| Error log | Per-student failures | Conditional | BR-CRT-024 |
**Relationships:** Belongs to a type; produces many issued certificates.
**Data Retention:** Retained; soft-deletable.
**Privacy Classification:** Internal.

### 5.8 ID Card Configuration
**What it represents:** A saved ID card layout for a session.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Card type | Student / Staff | Yes | |
| Session | Academic session it applies to | Yes | |
| Size / Orientation | Card dimensions | Yes | A5 / CR80 |
| Layout | Field positions, colours, QR placement | Yes | |
| Cards per sheet | Grid density | Yes | BR-CRT-028 |
**Relationships:** Belongs to a session.
**Data Retention:** Retained; soft-deletable.
**Privacy Classification:** Internal.

### 5.9 Student Document (DMS)
**What it represents:** An incoming document held against a student.
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Student | Owner | Yes | |
| Category | Document kind | Yes | Config-driven |
| Document name / date | Label and printed date | Yes / No | |
| File reference | Stored file | Yes | |
| Verification status | pending / verified / rejected | Yes | BR-CRT-030 |
| Remarks / Verifier | Notes and who verified | Conditional | Mandatory on reject |
**Relationships:** Belongs to a student.
**Data Retention:** Retained; soft-deletable.
**Privacy Classification:** Confidential / Sensitive (identity documents).

---

## Section 6 — Workflows

### 6.1 Certificate Request Lifecycle
**Trigger:** A student, parent, or staff member submits a request. **End State:** Certificate issued (or request rejected).
#### Steps
1. Requester submits (type, purpose, optional attachment) → status **pending**; a request number is allocated.
   - Decision: if the type needs no approval → status jumps to **approved** and generation triggers (BR-CRT-020).
   - Decision: if a duplicate active request exists for the same student+type → submission is refused (BR-CRT-021).
2. Admin/Principal opens the request → status **under review**.
3. Decision: **Approve** → status **approved**, generation triggers (Workflow 6.2). **Reject** → reason required → status **rejected** (terminal).
4. On successful generation → status **generated**; issued certificate recorded.
5. Office records physical handover → status **issued** (terminal).
#### Exception Paths
- Generation fails → status stays **approved**; error recorded; Admin retries.
- TC requested but fees outstanding or a rejected document exists → generation blocked (BR-CRT-001, BR-CRT-008) until resolved or overridden.
#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 1 | Requester | "Your certificate request has been received." |
| 3 (approve) | Requester | "Your request has been approved; the certificate is being prepared." |
| 3 (reject) | Requester | "Your request was rejected: <reason>." |

### 6.2 Certificate Generation (Request / Direct / TC)
**Trigger:** Approval, direct issue, or bulk run. **End State:** A stored, numbered, verifiable PDF in the register.
#### Steps
1. Resolve merge fields from student and school records.
2. Allocate the next number using the locked counter (BR-CRT-015).
3. Compute the verification code and embed the QR code.
4. Render the default template to a PDF and store it.
5. Record the issued certificate (duplicate flag set if a prior issue exists — BR-CRT-003).
6. If a Transfer Certificate: create the TC register entry, mark the student TC-issued, set status withdrawn (BR-CRT-011).
#### Exception Paths
- No active default template for the type → generation aborts with a clear error.
- TC fee/document gate fails → generation aborts before any record is written.
#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 5 | Requester (if request-based) | "Your certificate is ready." |

### 6.3 QR / Public Verification
**Trigger:** A third party scans the QR or opens the verification link. **End State:** A privacy-safe status is shown and the attempt is logged.
#### Steps
1. Look up the certificate by its verification code.
   - Decision: not found → show "not found".
   - Decision: revoked → show "revoked".
   - Decision: past validity → show "expired".
   - Otherwise → show "valid".
2. Record the attempt (time, address, result) and render minimal, privacy-safe details (BR-CRT-010, BR-CRT-025).
#### Exception Paths
- Excessive requests from one address → throttled (BR-CRT-026).
- Logging failure → never blocks the verification result (best-effort logging).
#### Notifications Triggered
None (read-only public flow).

### 6.4 Bulk Generation Job
**Trigger:** Admin starts a bulk run. **End State:** A downloadable archive (completed) or a failure report.
#### Steps
1. Job created → status **queued**.
2. Worker picks it up → status **processing**; generates each certificate, incrementing processed/failed counts.
   - Decision: an individual failure → log it and continue (BR-CRT-024).
3. All done → bundle the archive → status **completed**.
#### Exception Paths
- Fatal error → status **failed**; Admin notified with a retry option.
#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| 3 | Initiating Admin | "Your bulk certificate batch is ready to download." |

---

## Section 7 — Reporting & Analytics Requirements

### 7.1 Issued Certificates Register
**Report ID:** RPT-CRT-001 | **Purpose:** A complete, searchable record of every issued certificate. | **Audience:** School Admin, Principal | **Frequency:** As-needed.
| Column / KPI | What It Shows |
|--------------|---------------|
| Certificate number | The unique serial |
| Type / Recipient | What was issued and to whom |
| Issue / Validity dates | When issued / expiry |
| Status | Valid / expired / revoked |
**Filters:** Type, date range, class/section. **Export:** PDF, Excel. **Rules:** Confined to the school's data (BR-CRT-032).

### 7.2 Pending Requests Report
**Report ID:** RPT-CRT-002 | **Purpose:** Surface requests awaiting action, especially overdue ones. | **Audience:** School Admin | **Frequency:** Daily.
| Column / KPI | What It Shows |
|--------------|---------------|
| Request number / Type | The pending request |
| Days since submission | Age of the request |
| Required-by date | When it is needed; overdue highlighted (BR-CRT-033) |
**Filters:** Type, status, overdue-only. **Export:** On-screen, PDF.

### 7.3 Type Analytics
**Report ID:** RPT-CRT-003 | **Purpose:** Understand demand by certificate type and over time. | **Audience:** School Admin, Principal | **Frequency:** Monthly.
| Column / KPI | What It Shows |
|--------------|---------------|
| Volume by type | Count of certificates per type |
| Monthly trend | Issuance over time |
**Filters:** Date range, type. **Export:** On-screen chart.

### 7.4 Transfer Certificate Register
**Report ID:** RPT-CRT-004 | **Purpose:** The formal, legally mandated TC logbook. | **Audience:** School Admin, Principal | **Frequency:** As-needed.
| Column / KPI | What It Shows |
|--------------|---------------|
| Serial number / Year | Gap-free yearly sequence |
| Student / Father / Class at leaving | Required state-board fields |
| Admission / Leaving dates, Conduct, Reason | Required state-board fields |
**Filters:** Academic year. **Export:** PDF / printable table. **Rules:** Must remain gap-free (BR-CRT-002).

### 7.5 Verification Activity Log
**Report ID:** RPT-CRT-005 | **Purpose:** Audit of who verified which certificate and the result. | **Audience:** School Admin | **Frequency:** As-needed.
| Column / KPI | What It Shows |
|--------------|---------------|
| Time / Address | When and from where |
| Result | Valid / expired / revoked / not found |
| Certificate | The certificate checked (when found) |
**Filters:** Date range, result. **Export:** On-screen, PDF.

**KPI Catalog**
| KPI | Definition (business) | Source | Cadence |
|-----|-----------------------|--------|---------|
| Certificates issued (period) | Count of issued certificates in a period | Issued register | Monthly |
| Average approval turnaround | Mean time from request to issue | Requests | Monthly |
| Overdue request rate | Share of pending requests past required-by date | Pending report | Weekly |
| Verification volume | Count of verification attempts | Verification log | Monthly |

---

## Section 8 — Future Enhancement Log

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|------------------------|--------------|----------|--------|
| ENH-CRT-001 | DigiLocker integration | Government offices increasingly accept DigiLocker documents | V2 (S01) | P2 | Backlog |
| ENH-CRT-002 | Per-board serial-number profiles | Boards expect different numbering formats | V2 (S02) | P2 | Backlog |
| ENH-CRT-003 | Seeded starter templates | Faster onboarding; no blank canvas | V2 (S03) | P2 | Backlog |
| ENH-CRT-004 | E-signature / DSC stamp support | Schools increasingly use digital signatures | V2 (S04) | P2 | Backlog |
| ENH-CRT-005 | Certificate expiry reminders | Proactively warn before dated certificates lapse | V2 (S05) | P3 | Backlog |
| ENH-CRT-006 | Tunable per-IP verification rate limits | Harden against enumeration attacks | V2 (S06) | P2 | Backlog |
| ENH-CRT-007 | Auto-link duplicate requests to the original | Reduces admin confusion | V2 (S07) | P2 | Backlog |
| ENH-CRT-008 | Printable ID-sheet browser preview | Prevents wasted print sheets | V2 (S08) | P2 | Backlog |
| ENH-CRT-009 | State-board-specific TC templates | TC format compliance per board | V2 (S09) | P2 | Backlog |
| ENH-CRT-010 | Bulk DMS upload via archive + mapping file | Speeds annual batch admissions | V2 (S10) | P3 | Backlog |
| ENH-CRT-011 | ID card handover tracking | Record which student received their card | This analysis | P2 | Backlog |
| ENH-CRT-012 | Functional keyed verification interface | Programmatic third-party verification (currently a placeholder) | This analysis | P1 | Backlog |

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations
| NFR ID | Requirement | Standard |
|--------|-------------|----------|
| NFR-CRT-001 | Single certificate generation | Completes within 3 seconds |
| NFR-CRT-002 | Bulk throughput | More than 50 certificates per minute via background worker |
| NFR-CRT-003 | Public verification response | Within 500 milliseconds |
| NFR-CRT-004 | Admin list/register load | Within 2 seconds (paginated) |

### 9.2 Security Requirements (Business Language)
| NFR ID | Requirement | Rule |
|--------|-------------|------|
| NFR-CRT-005 | Access control | Each screen restricted to the correct role |
| NFR-CRT-006 | Data isolation | One school's data is never visible to another |
| NFR-CRT-007 | Audit trail | Every data-changing action and download records who and when |
| NFR-CRT-008 | Verification privacy | Public results expose only minimal, privacy-safe fields (BR-CRT-010) |
| NFR-CRT-009 | Tamper-evidence | Each certificate carries an unforgeable verification code |
| NFR-CRT-010 | Anti-scraping | Public verification is rate-limited (BR-CRT-026) |

### 9.3 Usability Requirements
| NFR ID | Requirement | Standard |
|--------|-------------|----------|
| NFR-CRT-011 | Mobile access | Core screens and the verification page work on mobile browsers |
| NFR-CRT-012 | Localisation | Certificate content supports Indian-language names (Hindi/Marathi/Tamil) |
| NFR-CRT-013 | Document quality | Generated PDFs render at print-acceptable quality |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary

| Requirement ID | Feature Name | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|-------------|---------|------|------------------|---------------|------------|--------------------|--------------------|
| REQ-CRT-001 | Certificate Type Management | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-CRT-002 | Certificate Template Designer | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-CRT-003 | Certificate Request Workflow | P0 | WORKFLOW, APPROVAL, NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-CRT-004 | Certificate Generation & Issuance | P0 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | Yes | Yes |
| REQ-CRT-005 | Transfer Certificate (TC) | P0 | WORKFLOW, APPROVAL, INTEGRATION | Yes | Yes | No | Yes | Yes |
| REQ-CRT-006 | Achievement & Bulk Certificates | P1 | WORKFLOW, SCHEDULED | Yes | Yes | No | Yes | Yes |
| REQ-CRT-007 | Digital Verification (QR + Keyed) | P0 | INTEGRATION, DASHBOARD | Yes | Yes | Yes | No | Yes |
| REQ-CRT-008 | ID Card Generation | P1 | DATA_ENTRY, CONFIGURATION, REPORT | Yes | Yes | No | No | Yes |
| REQ-CRT-009 | Document Management (DMS) | P1 | DATA_ENTRY, WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-CRT-010 | Certificate Number Format Config | P1 | CONFIGURATION | Yes | Yes | No | No | No |
| REQ-CRT-011 | Reports & Analytics | P1 | REPORT, DASHBOARD | No | Yes | No | No | Yes |
| REQ-CRT-012 | Student & Parent Portal Access | P1 | WORKFLOW | No | Yes | No | No | Yes |

### 10.2 Business Rules Coverage Summary

| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|--------------------|--------------------|---------------|
| BR-CRT-001 | TC blocked on fee dues (override allowed) | REQ-CRT-005 | Yes | Yes | Yes |
| BR-CRT-002 | TC serial gap-free yearly | REQ-CRT-005 | Yes | Yes | Yes |
| BR-CRT-003 | Duplicate issuance watermark | REQ-CRT-004 | No | Yes | Yes |
| BR-CRT-004 | Unique formatted number | REQ-CRT-004 | Yes | Yes | No |
| BR-CRT-005 | Revoked stays; reports revoked | REQ-CRT-004 | No | Yes | Yes |
| BR-CRT-006 | Referenced template not deletable | REQ-CRT-002 | Yes | Yes | Yes |
| BR-CRT-007 | Blood group shown/blank | REQ-CRT-008 | Yes | Yes | No |
| BR-CRT-008 | Rejected doc blocks TC | REQ-CRT-005/009 | Yes | Yes | Yes |
| BR-CRT-009 | >200 must queue | REQ-CRT-006 | Yes | Yes | Yes |
| BR-CRT-010 | Verification privacy | REQ-CRT-007 | No | Yes | Yes |
| BR-CRT-011 | TC → flag + withdrawn | REQ-CRT-005 | No | Yes | Yes |
| BR-CRT-012 | One default template | REQ-CRT-002 | Yes | Yes | Yes |
| BR-CRT-013 | Rejection reason required | REQ-CRT-003 | Yes | No | Yes |
| BR-CRT-014 | Attachment format/size | REQ-CRT-003 | Yes | No | No |
| BR-CRT-015 | Locked counter | REQ-CRT-004/010 | No | Yes | Yes |
| BR-CRT-016 | Inactive hides from form | REQ-CRT-001 | No | Yes | Yes |
| BR-CRT-017 | Used type not deletable | REQ-CRT-001 | Yes | Yes | Yes |
| BR-CRT-018 | Placeholders declared | REQ-CRT-002 | Yes | No | No |
| BR-CRT-019 | Archive version on edit | REQ-CRT-002 | No | Yes | Yes |
| BR-CRT-020 | Auto-approve no-approval type | REQ-CRT-003 | No | Yes | Yes |
| BR-CRT-021 | Duplicate request blocked | REQ-CRT-003 | Yes | Yes | Yes |
| BR-CRT-022 | Download only issued/non-revoked | REQ-CRT-004/012 | Yes | Yes | Yes |
| BR-CRT-023 | TC leaving fields mandatory | REQ-CRT-005 | Yes | No | Yes |
| BR-CRT-024 | Bulk failure logged, continues | REQ-CRT-006 | No | Yes | Yes |
| BR-CRT-025 | Verification logged | REQ-CRT-007 | No | Yes | No |
| BR-CRT-026 | Public page rate-limited | REQ-CRT-007 | No | No | Yes |
| BR-CRT-027 | Keyed interface needs key | REQ-CRT-007 | Yes | No | Yes |
| BR-CRT-028 | Cards-per-sheet grid | REQ-CRT-008 | No | No | No |
| BR-CRT-029 | Allowed formats/size | REQ-CRT-009 | Yes | No | No |
| BR-CRT-030 | Reject remarks; blocks eligibility | REQ-CRT-009 | Yes | Yes | Yes |
| BR-CRT-031 | Counter per type/year resets | REQ-CRT-010 | No | Yes | No |
| BR-CRT-032 | Reports school-scoped | REQ-CRT-011 | No | Yes | Yes |
| BR-CRT-033 | Overdue highlighted | REQ-CRT-011 | No | Yes | No |
| BR-CRT-034 | Portal sees own only | REQ-CRT-012 | No | Yes | Yes |

### 10.3 Report Coverage Summary

| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|---------|---------------|---------------|
| RPT-CRT-001 | Issued Certificates Register | P1 | 3 | Yes |
| RPT-CRT-002 | Pending Requests | P1 | 3 | Yes |
| RPT-CRT-003 | Type Analytics | P2 | 2 | No |
| RPT-CRT-004 | Transfer Certificate Register | P0 | 1 | Yes |
| RPT-CRT-005 | Verification Activity Log | P1 | 2 | No |

### 10.4 Total Scope Numbers

| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 12 |
| Total Business Rules (BR-) | 34 |
| Total Workflows defined | 4 |
| Total Reports required | 5 |
| Total Enhancements logged | 12 |
| Total P0 (Core) Requirements | 6 |
| Total P1 (Standard) Requirements | 6 |
| Total P2 (Enhanced) Requirements | 0 |

> **Implementation note (not part of scope denominators):** As of 2026-06-29 the module is approximately **70–75% built**. All 10 data tables exist as live tenant migrations; all 12 features have controllers, routes, and views; generation, TC, verification, serial-counter locking, rate-limiting, and DMS gating are implemented. **Known open items:** the keyed third-party verification interface is a non-functional placeholder (REQ-CRT-007 partial); ID card handover tracking has no data store (REQ-CRT-008 AC partial); the TC fee-override path is not yet implemented even though BR-CRT-001 allows it; no in-module unit/feature tests (a browser test suite of ~45 methods exists). See Section 11 RTM "Code Status" column.

---

## Section 11 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Test ref | Code Status |
|--------|---------|---------|-----------|----------|-----------|----------|-------------|
| REQ-CRT-001 | Type Management | 004,016,017 | Types index/form/show/trashed | — | — | CertificateTypeTest | DONE |
| REQ-CRT-002 | Template Designer | 006,012,018,019 | Templates index/form/show/versions/trashed/preview | — | — | CertificateTemplateTest | DONE |
| REQ-CRT-003 | Request Workflow | 013,014,020,021 | Requests index/create/show/trashed | 6.1 | RPT-CRT-002 | CertificateRequestTest | DONE |
| REQ-CRT-004 | Generation & Issuance | 003,004,005,015,022 | Issued index/show/trashed | 6.2 | RPT-CRT-001 | CertificateIssuedTest | DONE |
| REQ-CRT-005 | Transfer Certificate | 001,002,008,011,023 | TC register; issued | 6.1,6.2 | RPT-CRT-004 | (covered via issued/request) | PARTIAL — fee-override path not implemented |
| REQ-CRT-006 | Achievement & Bulk | 009,024 | Bulk-generate index | 6.4 | — | BulkGenerationTest | DONE |
| REQ-CRT-007 | Digital Verification | 010,025,026,027 | Public verify; verification-logs | 6.3 | RPT-CRT-005 | VerificationTest | PARTIAL — keyed interface is a placeholder; QR + public + logging DONE |
| REQ-CRT-008 | ID Card Generation | 007,028 | ID-cards index/create/edit/show/generate | — | — | IdCardConfigTest | PARTIAL — handover tracking absent |
| REQ-CRT-009 | DMS | 029,030 | Documents index/create/show/edit/trashed | — | — | StudentDocumentTest | DONE |
| REQ-CRT-010 | Number Format Config | 015,031 | (within Types form) | — | — | (within type tests) | DONE |
| REQ-CRT-011 | Reports & Analytics | 032,033 | Reports index | — | RPT-CRT-001..005 | CertificateReportTest | PARTIAL — analytics chart breadth unverified |
| REQ-CRT-012 | Portal Access | 022,034 | (Student Portal module) | 6.1 | — | (pending portal module) | NOT STARTED — depends on StudentPortal |

> RTM reconciles to §10.4: 12 REQ, 34 BR, 5 RPT, 4 workflows. "Code Status" is a BA-level read of the live tree for handoff; the Technical Auditor produces the authoritative 12-layer status.

---

## Section 12 — Requirement Conditions Catalog (keyed to BR-)

| Condition ID (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|---------------------|--------------|----------------------|------|---------|------------------------|
| BR-CRT-001 | Transfer Certificate | Fees must be cleared (or override recorded) before issue | Validation | TC generation | Block with outstanding-fee message |
| BR-CRT-004 | Type code / Certificate number | Must be unique within school | Validation | Save type / generate | Reject with duplicate message |
| BR-CRT-008 | Student documents | No rejected document outstanding before TC | Validation | TC generation | Block with rejected-document message |
| BR-CRT-009 | Bulk run size | Above 200 must queue | Workflow | Bulk submit | Force background processing |
| BR-CRT-010 | Verification result | Minimal fields only | Permission | Public verify | Suppress sensitive fields |
| BR-CRT-012 | Default template | Only one per type | Workflow | Mark default | Clear previous default |
| BR-CRT-013 | Rejection | Reason mandatory | Validation | Reject request | Block until reason supplied |
| BR-CRT-015 | Serial counter | Locked transactional increment | Concurrency | Generate | Serialize concurrent allocations |
| BR-CRT-018 | Template variables | Placeholders must be declared | Validation | Save template | Reject undeclared placeholder |
| BR-CRT-021 | Duplicate request | No second active request same student+type | Validation | Submit request | Block with duplicate message |
| BR-CRT-022 | Download | Issued + non-revoked + authorised only | Permission | Download | Deny download |
| BR-CRT-023 | TC leaving fields | Date & reason mandatory | Validation | TC generation | Block until supplied |
| BR-CRT-026 | Public page | Rate-limited per address | Permission | Public verify | Throttle excess requests |
| BR-CRT-027 | Keyed interface | Valid access key required | Permission | Keyed verify | Reject without key |
| BR-CRT-030 | Document rejection | Remarks mandatory; blocks eligibility | Validation | Reject document | Block until remarks supplied |
| BR-CRT-034 | Portal records | Own/ward only | Permission | Portal view | Hide others' records |

> Full 34-rule set in Section 4; this catalog highlights the enforceable conditions. Canonical copy may also live at `5-Requirement_Conditions/Certificate_Conditions.md` (pointing back here).

---

## Section 13 — Validation & Edge-Case Catalog

| Field/Rule | Valid example | Invalid example | Boundary | Empty/null | Concurrency case | Expected behaviour |
|------------|---------------|-----------------|----------|------------|------------------|--------------------|
| Type code | "BON" | "BONAFIDE2025X" (>10) | exactly 10 chars | blank | two admins same code | Reject duplicate/over-length |
| Serial number | BON-2026-000042 | duplicate number | sequence 999999→1000000 | n/a | two simultaneous generations | Locked counter yields unique sequential numbers (BR-CRT-015) |
| TC fee gate | dues = 0 | dues > 0, no override | dues exactly 0 | no fee record | fee paid mid-generation | Block unless override; recompute at generation time |
| TC serial (register) | 1,2,3… | gap (1,3) | year rollover to 1 | first TC of year | two TCs at once | Gap-free, locked per year (BR-CRT-002) |
| Default template | exactly one default | two defaults | toggling default | none default | two toggles at once | Exactly one default ends up set (BR-CRT-012) |
| Template placeholders | all declared | undeclared {{x}} | empty variable list | no placeholders | n/a | Reject undeclared (BR-CRT-018) |
| Rejection reason | "Incomplete docs" | empty | 1 char | null | n/a | Reject blocked without reason (BR-CRT-013) |
| Duplicate request | first request | second active same type | exactly one active | none | two submits at once | Block second (BR-CRT-021) |
| Bulk size | 50 | 201 sync attempt | exactly 200 / 201 | 0 students | n/a | >200 forced to queue (BR-CRT-009) |
| Verification result | VALID | exposes DOB | validity = today | unknown hash → NOT_FOUND | revoked mid-check | Minimal fields; correct status (BR-CRT-010, 005) |
| Download | issued, non-revoked | revoked download | just-issued | not-yet-issued | revoked mid-download | Deny revoked/non-issued (BR-CRT-022) |
| Blood group on ID | "O+" | n/a | n/a | absent → blank field | n/a | Shown when present; blank when absent (BR-CRT-007) |

---

## Section 14 — State Machine (FSM) Catalog

**Entity: Certificate Request**
| From State | Event/Action | Guard (condition) | To State | Side-Effects |
|------------|--------------|-------------------|----------|--------------|
| (none) | Submit | duplicate active check passes | pending | Request number allocated; submission notification |
| pending | Auto-advance | type needs no approval | approved | Triggers generation (BR-CRT-020) |
| pending | Open for review | — | under_review | — |
| under_review | Approve | — | approved | Triggers generation; approval notification |
| under_review | Reject | reason supplied | rejected (terminal) | Rejection notification |
| approved | Generation succeeds | template + gates pass | generated | Issued certificate created |
| approved | Generation fails | — | approved (retry) | Error recorded |
| generated | Record handover | — | issued (terminal) | — |
Terminal states: rejected, issued. Illegal transitions: pending→issued, rejected→anything, issued→anything.

**Entity: Bulk Job**
| From State | Event/Action | Guard | To State | Side-Effects |
|------------|--------------|-------|----------|--------------|
| (none) | Dispatch | size routing applied | queued | — |
| queued | Worker picks up | — | processing | — |
| processing | All done | — | completed | Archive built; completion notification |
| processing | Fatal error | — | failed | Admin notified; retry offered |
Terminal states: completed, failed.

**Entity: Issued Certificate (validity)**
| State | Meaning | Transition |
|-------|---------|------------|
| Valid | Not revoked, not past validity | → Expired (time) / → Revoked (admin) |
| Expired | Past validity date | terminal (unless reissued) |
| Revoked | Admin revoked | terminal; stays in register (BR-CRT-005) |

**Entity: Student Document (DMS)**
| From | Event | Guard | To | Side-Effects |
|------|-------|-------|----|--------------|
| pending | Verify | — | verified | Satisfies eligibility |
| pending | Reject | remarks supplied | rejected | Blocks eligibility (BR-CRT-030) |

> These states are config-driven where applicable (status sets can be extended by the school per platform decision D29).

---

## Section 15 — Data Dictionary (Business View)

| Business Entity | Key Information | Privacy |
|-----------------|-----------------|---------|
| Certificate Type | Name, code, category, approval flag, validity, serial format, active | Internal |
| Template | Body, declared variables, page size/orientation, default flag, version | Internal |
| Template Version | Archived body + variables, version number, saved by/at | Internal |
| Certificate Request | Request number, type, requester, beneficiary, purpose, status, approval/rejection details | Confidential |
| Issued Certificate | Number, type, template, recipient, dates, verification code, file, revocation, duplicate flag | Confidential |
| TC Register Entry | Serial/year, student snapshot, class at leaving, dates, conduct, reason | Confidential / Sensitive |
| Serial Counter | Type, year, last sequence number | Internal |
| Bulk Job | Type, filter, counts, status, archive, error log | Internal |
| ID Card Configuration | Card type, session, size, orientation, layout, cards-per-sheet | Internal |
| Student Document | Student, category, name/date, file, verification status, remarks | Confidential / Sensitive |

---

## Section 16 — Cross-Module Dependency Map

**Inbound (this module reads from):**
| Source Module | Data/Entity | Why |
|---------------|-------------|-----|
| Student Profile (STD) | Student name parts, date of birth, admission no, class/section (via academic-session link), profile (father/mother, blood group, nationality, religion), photo | Merge fields, ID cards, TC snapshot |
| School Setup (SCH) | Classes, sections, class-section link, academic sessions, organisation name, school profile (principal, address) | Merge fields, ID card session, TC |
| Student Fee / Finance (FIN) | Outstanding fee amount | TC fee-clearance gate (BR-CRT-001) |
| System Media (SYS) | Stored files | Attachments, DMS documents, photos |
| System Dropdowns (SYS) | Document categories, student status values | DMS categories; withdrawn status on TC |
| System Users (SYS) | User identities | Creator/approver/verifier references |

**Outbound (this module feeds):**
| Target Module | Mechanism | What |
|---------------|-----------|------|
| Notification (NTF) | Event/dispatch | Request submission, approval, rejection, bulk completion |
| Student Profile (STD) | Direct update | TC-issued flag + withdrawn status on TC issue (BR-CRT-011) |
| Audit Log (SYS) | Activity log write | Every data-changing action, downloads, and all verification attempts |

**Downstream (modules that depend on CRT):**
| Module | Usage |
|--------|-------|
| Student Portal (STP) | Display/download own certificates; submit requests (REQ-CRT-012) |
| Parent Portal | Request and download for ward |

**Module-boundary anomalies (governance — confirm before audit):**
- **Q-CRT-1 — Duplicate TC systems.** A separate `adm_transfer_certificates` table and Transfer Certificate flow exist in the **Admission** module, in parallel with this module's `crt_tc_register` and TC flow. Two TC records/numbering schemes risk conflicting legal registers. Decision needed on which is authoritative.
- **Q-CRT-2 — Duplicate certificate-request intake.** A `fof_certificate_requests` table exists in the **Front Office** module, overlapping REQ-CRT-003. Confirm whether front-office walk-in requests should funnel into this module's request workflow.

---

## Section 17 — Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Early-warning |
|---------|------|----------|-----------|--------|------------|---------------|
| RISK-CRT-001 | Two parallel TC systems (CRT vs Admission) produce conflicting legal registers | Compliance | M | H | Resolve Q-CRT-1; designate one authoritative TC register | Mismatched TC serials across modules |
| RISK-CRT-002 | TC fee-override path not implemented though policy allows it | Functional | H | M | Implement recorded-override flow (BR-CRT-001) | Admins blocked from legitimate overrides |
| RISK-CRT-003 | Keyed third-party verification interface is a non-functional placeholder | Functional | H | M | Implement keyed verify or remove the advertised interface (ENH-CRT-012) | Partners cannot integrate |
| RISK-CRT-004 | No in-module unit/feature tests for concurrency-critical logic (counter lock, duplicate detection) | Quality | H | H | Add feature/unit tests for BR-CRT-015, 003, 009, 001 | Regressions in numbering or duplicates |
| RISK-CRT-005 | Certificate files stored on a non-tenant-scoped local path | Security/Isolation | M | H | Confirm storage uses tenant-scoped disk per NFR-CRT-006 | Cross-tenant file path collisions |
| RISK-CRT-006 | ID card handover not trackable (no data store) | Functional | M | L | Add handover store (ENH-CRT-011) | Disputes over card receipt |
| RISK-CRT-007 | Hash enumeration on the public verification page | Security | M | M | Rate limiting in place (BR-CRT-026); tune per ENH-CRT-006 | Spike in verification-log volume |
| RISK-CRT-008 | Heavy bulk runs strain PDF rendering and queue | Performance | M | M | Enforce queue threshold (BR-CRT-009); monitor worker | Slow batches; growing queue backlog |

---

## Section 18 — Prioritization (MoSCoW) & Effort / Sprint Tasks

**MoSCoW**
- **Must (P0):** REQ-CRT-001, 002, 003, 004, 005, 007 — type/template foundation, requests, generation, TC, verification.
- **Should (P1):** REQ-CRT-006, 008, 009, 010, 011, 012 — bulk/achievement, ID cards, DMS, number config, reports, portal.
- **Could (P2):** the analytics-depth and overdue-highlight refinements within REQ-CRT-011.
- **Won't (this release):** the enhancement log (ENH-CRT-001…012) except ENH-CRT-012 (keyed interface) which is recommended for the next sprint.

**Remediation Sprint Tasks (gap-closing, since base build is ~70–75%)**
| # | Task | Type | Effort (h) | Depends on | Sequence |
|---|------|------|-----------|------------|----------|
| 1 | Implement TC fee-override capture + audit (BR-CRT-001) | Backend | 6 | REQ-CRT-005 | S1 |
| 2 | Implement keyed third-party verification interface (REQ-CRT-007, ENH-CRT-012) | Backend/API | 10 | REQ-CRT-007 | S1 |
| 3 | Add ID card handover store + mark-received flow (REQ-CRT-008) | Schema/Backend/Frontend | 10 | REQ-CRT-008 | S2 |
| 4 | Confirm/repair tenant-scoped certificate file storage (NFR-CRT-006, RISK-CRT-005) | Backend | 5 | REQ-CRT-004 | S1 |
| 5 | Feature/unit tests for counter lock, duplicate, bulk threshold, TC gate | Testing | 14 | REQ-CRT-004/005/006 | S2 |
| 6 | Resolve TC/cert-request module overlap (Q-CRT-1, Q-CRT-2) | Analysis/Backend | 8 | cross-module | S1 |
| 7 | Verify analytics chart + overdue highlighting (REQ-CRT-011) | Frontend | 5 | REQ-CRT-011 | S2 |
| 8 | Portal views once Student Portal module lands (REQ-CRT-012) | Frontend/Backend | 12 | StudentPortal | S3 |
> Estimates assume the existing schema and controllers stand; they cover gap-closing, not a full rebuild.

---

## Section 19 — User Stories + Acceptance Criteria (Gherkin)

**US-CRT-001 | P0 | REQ-CRT-001** — As a School Admin, I want to define certificate types so the school issues consistent documents.
- Scenario (happy): Given I am an Admin, When I create a type with a unique code, Then it appears in the type list.
- Scenario (boundary): Given a type code already exists, When I reuse it, Then the system rejects it.
- Scenario (permission): Given a user without type-setup rights, When they open the type form, Then access is refused.
- Definition of Done: created; audit logged; school-scoped.

**US-CRT-002 | P0 | REQ-CRT-002** — As a School Admin, I want to design and version templates so issued certificates look right and history is preserved.
- Scenario (happy): Given a template, When I edit and save, Then the prior content is archived as a new version.
- Scenario (boundary): Given an undeclared placeholder, When I save, Then it is rejected.
- Scenario (permission): Given a non-admin, When they try to delete a referenced template, Then it is blocked.
- Definition of Done: version archived; default uniqueness held; preview renders.

**US-CRT-003 | P0 | REQ-CRT-003** — As a Student/Parent, I want to request a certificate and track it.
- Scenario (happy): Given an active type, When I submit a request, Then I receive a request number and a submission notification.
- Scenario (boundary): Given a no-approval type, When I submit, Then it auto-approves and generation starts.
- Scenario (exception): Given an existing active request for the same type, When I submit again, Then it is blocked as duplicate.
- Definition of Done: number allocated; notification fired; status visible.

**US-CRT-004 | P0 | REQ-CRT-004** — As a School Admin, I want approved requests to generate a numbered, verifiable PDF.
- Scenario (happy): Given an approved request, When generation runs, Then a uniquely numbered PDF with a QR code is stored.
- Scenario (concurrency): Given two simultaneous generations, When numbers are allocated, Then both numbers are unique and sequential.
- Scenario (permission): Given a revoked certificate, When anyone tries to download it, Then download is denied.
- Definition of Done: unique number/code; download audited; duplicate watermark when applicable.

**US-CRT-005 | P0 | REQ-CRT-005** — As a Principal, I want TCs gated by fees and recorded in the formal register.
- Scenario (happy): Given fees cleared and leaving details supplied, When I issue a TC, Then a gap-free register entry is created and the student is marked withdrawn.
- Scenario (exception): Given outstanding fees, When I attempt a TC, Then it is blocked unless I record an override.
- Scenario (exception): Given a rejected document, When I attempt a TC, Then it is blocked.
- Definition of Done: register gap-free; student flagged; audit logged.

**US-CRT-006 | P1 | REQ-CRT-006** — As a School Admin, I want to bulk-issue achievement certificates.
- Scenario (happy): Given a class selection, When I run a bulk job, Then certificates are produced and bundled for download.
- Scenario (boundary): Given more than 200 students, When I run it, Then it is processed in the background.
- Scenario (exception): Given one student fails, When the batch runs, Then the rest still succeed and the failure is logged.
- Definition of Done: archive available; progress pollable; failures logged.

**US-CRT-007 | P0 | REQ-CRT-007** — As a third party, I want to verify a certificate by scanning its QR code.
- Scenario (happy): Given a valid certificate, When I scan it, Then I see "valid" with minimal details.
- Scenario (exception): Given a revoked certificate, When I scan it, Then I see "revoked".
- Scenario (privacy): Given any verification, When the page renders, Then no full name/DOB/class/address is shown.
- Definition of Done: correct status; attempt logged; rate-limited.

**US-CRT-008 | P1 | REQ-CRT-008** — As a School Admin, I want printable ID cards.
- Scenario (happy): Given a config, When I generate, Then a sheet with cards (photo + QR) is produced.
- Scenario (boundary): Given a student with no blood group, When the card prints, Then the field is blank not hidden.
- Definition of Done: grid per config; photo placeholder when absent.

**US-CRT-009 | P1 | REQ-CRT-009** — As a Clerk, I want to upload and have documents verified.
- Scenario (happy): Given a document, When I upload it with a category, Then it is stored as pending.
- Scenario (exception): Given a rejection, When the admin rejects without remarks, Then it is blocked.
- Definition of Done: rejected docs block TC eligibility; downloads audited.

**US-CRT-011 | P1 | REQ-CRT-011** — As a Principal, I want reports of issued and pending certificates.
- Scenario (happy): Given issued data, When I open the register, Then I can filter and export it.
- Scenario (boundary): Given overdue requests, When I open the pending report, Then they are highlighted.
- Definition of Done: school-scoped; export works.

**US-CRT-012 | P1 | REQ-CRT-012** — As a Student/Parent, I want to see and download only my own certificates.
- Scenario (happy): Given issued, non-revoked certificates, When I open the portal, Then I can download mine.
- Scenario (permission): Given another student's record, When I try to view it, Then it is not visible.
- Definition of Done: own-only scoping; download only when issued and non-revoked.

---

## Section 20 — Technical Data Dictionary (table → key columns → model)

> Technical register. Verified against `Certificates_DDL_v1.sql`, tenant migrations (`database/migrations/tenant/2026_06_16_0836*_create_crt_*`), and `Modules/Certificate/app/Models/`. PK/FK type = `INT UNSIGNED` throughout (DDL, migration `increments()`/`unsignedInteger()`, and models agree). All tables soft-delete EXCEPT `crt_template_versions` (immutable archive). No `tenant_id` column (database-per-tenant).

| Table | Model | Key columns | FK targets / notes |
|-------|-------|-------------|--------------------|
| `crt_certificate_types` | `CertificateType` | code (UNIQUE), category(ENUM), requires_approval, validity_days, serial_format | created_by/updated_by → sys_users |
| `crt_id_card_configs` | `IdCardConfig` | card_type(ENUM), academic_session_id, card_size(ENUM), orientation, template_json, cards_per_sheet | academic_session_id → sch_org_academic_sessions_jnt |
| `crt_templates` | `CertificateTemplate` | certificate_type_id, template_content(LONGTEXT), variables_json, page_size, orientation, is_default, version_no, signature_placement_json | certificate_type_id → crt_certificate_types ON DELETE CASCADE |
| `crt_serial_counters` | `SerialCounter` | certificate_type_id, academic_year, last_seq_no; UNIQUE(type, year) | locked increment in `QrVerificationService::incrementSerialCounter()` |
| `crt_bulk_jobs` | `BulkJob` | certificate_type_id, initiated_by, filter_json, total/processed/failed_count, status(ENUM), zip_path, error_log_json | drives `BulkGenerateCertificatesJob` |
| `crt_student_documents` | `StudentDocument` | student_id, document_category_id, media_id, verification_status(ENUM), verification_remarks, verified_by | student_id → std_students; category → sys_dropdown_table; media → sys_media |
| `crt_template_versions` | `TemplateVersion` | template_id, version_no, template_content, variables_json, saved_by, saved_at | NO deleted_at (immutable); template_id → crt_templates ON DELETE CASCADE |
| `crt_requests` | `CertificateRequest` | request_no(UNIQUE), certificate_type_id, requester_type(ENUM)+requester_id (polymorphic, no FK), beneficiary_student_id, status(ENUM 6), approved_by, rejection_reason, supporting_doc_media_id | beneficiary → std_students; supporting_doc → sys_media |
| `crt_issued_certificates` | `IssuedCertificate` | certificate_no(UNIQUE), verification_hash(UNIQUE), request_id(nullable), certificate_type_id, template_id, recipient_type(ENUM)+recipient_id (polymorphic), issue_date, validity_date, is_revoked, is_duplicate | template_id → crt_templates ON DELETE RESTRICT (BR-CRT-006) |
| `crt_tc_register` | `TcRegister` | sl_no + academic_year (UNIQUE), issued_certificate_id, student snapshot fields, date_of_leaving, reason_for_leaving, conduct, prepared_by | issued_certificate_id → crt_issued_certificates ON DELETE RESTRICT |
| (cross-module) `std_students.tc_issued` | — | boolean column added by `2026_06_15_155842_add_tc_issued_to_std_students_table` | written on TC issue (BR-CRT-011) |

**Tables referenced in V2 requirement but NOT created (by-design or open):**
- `crt_verification_logs` — **not created; by design.** Verification logging goes to `sys_activity_logs` (event `certificate.verify.qr`) via `QrVerificationService::logVerification()`; the admin log reader (`VerificationController::logs()`) queries `sys_activity_logs`. This is NOT a gap.
- `crt_id_card_issued` — **not created; open.** No data store for ID card handover tracking; REQ-CRT-008 handover (mark-received) is unimplemented (ENH-CRT-011).

**Implementation deviations noted for the auditor (technical register):**
- Fee gate reads `fin_fee_invoices` (sum of `net_payable` where `payment_status != 'paid'`), not a `fin_fee_dues` table; the **admin override path is not implemented** (the service throws unconditionally on dues > 0) — contradicts BR-CRT-001.
- Generated PDFs are written to `storage_path('app/tenant_certificates/...')` (local), not the stancl tenant-scoped disk implied by NFR-CRT-006 — confirm isolation (RISK-CRT-005).
- Withdrawn status resolved via `sys_dropdowns` (key `student_status`, value `Withdrawn`); confirm this matches the platform's status master table name.
- The API route (`routes/api.php`) maps `apiResource('certificates', CertificateController)`; `CertificateController` is a **non-functional stub** (empty store/update/destroy, view-returning index/show). The keyed verification interface described in REQ-CRT-007 AC4 is therefore not yet functional.

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-29 | Initial Complete FRD & Analysis Pack from V2 + DDL + live code/migrations/tests + V1 screen specs. Verified counts against live tree. | Business Analyst — AI_Brain |

*This Complete FRD is the single source of truth for the Certificate (CRT) module. All gap analyses, completion scoring, and test coverage must reference the REQ-/BR-/RPT-/ENH-/NFR-/RISK- IDs defined here and must not renumber them.*
