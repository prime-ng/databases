# CRT — Certificate & Template Module: Table Summary
**Module:** Certificate (`Modules\Certificate`) | **Date:** 2026-03-28
**Tables:** 10 (`crt_*`) | **DB:** tenant_db | **No `tenant_id` on any table**

---

## 1. Table Inventory (One-Line Descriptions)

| # | Table | Sub-Module | Description |
|---|---|---|---|
| 1 | `crt_certificate_types` | L1 Type | Master definitions — code, category, approval rule, serial format |
| 2 | `crt_templates` | L1 Template | HTML/CSS templates; one-to-many per type; one `is_default` per type |
| 3 | `crt_template_versions` | L1 Archive | Immutable snapshots of template content before each save |
| 4 | `crt_requests` | L2 Workflow | Certificate request workflow — 6-state FSM (pending → issued) |
| 5 | `crt_issued_certificates` | L3 Issuance | All generated certificates; `verification_hash` for QR lookup |
| 6 | `crt_tc_register` | L4 TC | Formal sequential TC logbook as mandated by Indian state boards |
| 7 | `crt_serial_counters` | L3 Serial | Per-type, per-year counters; SELECT FOR UPDATE prevents gaps |
| 8 | `crt_bulk_jobs` | L5 Bulk | Async `BulkGenerateCertificatesJob` tracker with progress + ZIP |
| 9 | `crt_id_card_configs` | L7 ID Cards | ID card template configurations (layout, size, QR placement) |
| 10 | `crt_student_documents` | L8 DMS | Incoming student documents with admin verification workflow |

---

## 2. Dependency Layers (DDL Creation Order)

```
Layer 1 — No crt_* dependencies:
  crt_certificate_types       (references sys_users only)
  crt_id_card_configs         (references sch_org_academic_sessions_jnt + sys_users)

Layer 2 — Depends on Layer 1:
  crt_templates               (→ crt_certificate_types CASCADE)
  crt_serial_counters         (→ crt_certificate_types RESTRICT)
  crt_bulk_jobs               (→ crt_certificate_types RESTRICT)
  crt_student_documents       (→ std_students, sys_media, sys_dropdown_table)

Layer 3 — Depends on Layer 2:
  crt_template_versions       (→ crt_templates CASCADE)
  crt_requests                (→ crt_certificate_types, std_students, sys_media)

Layer 4 — Depends on Layer 3:
  crt_issued_certificates     (→ crt_certificate_types, crt_templates RESTRICT, crt_requests SET NULL)

Layer 5 — Depends on Layer 4:
  crt_tc_register             (→ crt_issued_certificates RESTRICT)
```

**Drop order (down migration):** Layer 5 → 4 → 3 → 2 → 1

---

## 3. Audit Column Matrix

| Table | `id` PK | `is_active` | `created_by` | `updated_by` | `created_at` | `updated_at` | `deleted_at` |
|---|---|---|---|---|---|---|---|
| `crt_certificate_types` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_templates` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_template_versions` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | **❌ NO** |
| `crt_requests` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_issued_certificates` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_tc_register` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_serial_counters` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_bulk_jobs` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_id_card_configs` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |
| `crt_student_documents` | ✅ INT UNS | ✅ | ✅ INT UNS | ✅ INT UNS | ✅ | ✅ | ✅ |

> `crt_template_versions` has **NO `deleted_at`** — versions are immutable archive records (DDL Rule 14).

---

## 4. Cross-Module FK Summary

| crt_* Table | Column | References | Type | On Delete |
|---|---|---|---|---|
| `crt_id_card_configs` | `academic_session_id` | `sch_org_academic_sessions_jnt.id` | SMALLINT UNS | RESTRICT |
| `crt_requests` | `beneficiary_student_id` | `std_students.id` | INT UNS | RESTRICT |
| `crt_requests` | `supporting_doc_media_id` | `sys_media.id` | INT UNS | SET NULL |
| `crt_student_documents` | `student_id` | `std_students.id` | INT UNS | RESTRICT |
| `crt_student_documents` | `document_category_id` | `sys_dropdown_table.id` | INT UNS | RESTRICT |
| `crt_student_documents` | `media_id` | `sys_media.id` | INT UNS | RESTRICT |
| All tables | `created_by`, `updated_by` | `sys_users.id` | INT UNS | RESTRICT |
| `crt_template_versions` | `saved_by` | `sys_users.id` | INT UNS | RESTRICT |
| `crt_requests` | `approved_by` | `sys_users.id` | INT UNS | SET NULL |
| `crt_issued_certificates` | `revoked_by` | `sys_users.id` | INT UNS | SET NULL |
| `crt_student_documents` | `verified_by` | `sys_users.id` | INT UNS | SET NULL |
| `crt_tc_register` | `prepared_by` | `sys_users.id` | INT UNS | RESTRICT |
| `crt_bulk_jobs` | `initiated_by` | `sys_users.id` | INT UNS | RESTRICT |

**Type verification (against tenant_db_v2.sql):**
- `sys_users.id` → INT UNSIGNED (not BIGINT as Phase 2 prompt template states)
- `std_students.id` → INT UNSIGNED
- `sys_media.id` → INT UNSIGNED
- `sys_dropdown_table.id` → INT UNSIGNED
- `sch_org_academic_sessions_jnt.id` → SMALLINT UNSIGNED
- Note: `sch_academic_sessions` table does NOT exist; correct table is `sch_org_academic_sessions_jnt`

**Cross-module schema change:**
`std_students.tc_issued TINYINT(1) DEFAULT 0` — added by CRT migration (BR-CRT-011).
This column does not exist in baseline `tenant_db_v2.sql`.

---

## 5. Critical UNIQUE Constraints

| Table | Constraint Name | Column(s) | Business Purpose |
|---|---|---|---|
| `crt_certificate_types` | `uq_crt_ct_code` | `code` | Type codes unique per tenant (AC1 FR-CRT-001) |
| `crt_issued_certificates` | `uq_crt_ic_certificate_no` | `certificate_no` | No duplicate cert numbers (BR-CRT-004) |
| `crt_issued_certificates` | `uq_crt_ic_verification_hash` | `verification_hash` | O(1) hash lookup for QR verification |
| `crt_serial_counters` | `uq_crt_sc_type_year` | `(certificate_type_id, academic_year)` | One counter per type per year (FR-CRT-010) |
| `crt_tc_register` | `uq_crt_tc_sl_year` | `(sl_no, academic_year)` | TC serial unique per year; no gaps (BR-CRT-002) |
| `crt_requests` | `uq_crt_req_request_no` | `request_no` | Request number unique per tenant |

**Composite INDEX (not unique):**
| Table | Index Name | Column(s) | Purpose |
|---|---|---|---|
| `crt_requests` | `idx_crt_req_student_type_status` | `(beneficiary_student_id, certificate_type_id, status)` | Duplicate request check (AC7 FR-CRT-003) |

---

## 6. ENUM Reference

| Table | Column | Values |
|---|---|---|
| `crt_certificate_types` | `category` | `'administrative','legal','character','achievement','identity'` |
| `crt_templates` | `page_size` | `'a4','a5','letter','custom'` |
| `crt_templates` | `orientation` | `'portrait','landscape'` |
| `crt_requests` | `requester_type` | `'student','parent','staff','admin'` |
| `crt_requests` | `status` | `'pending','under_review','approved','rejected','generated','issued'` |
| `crt_issued_certificates` | `recipient_type` | `'student','staff'` |
| `crt_bulk_jobs` | `status` | `'queued','processing','completed','failed'` |
| `crt_id_card_configs` | `card_type` | `'student','staff'` |
| `crt_id_card_configs` | `card_size` | `'a5','cr80'` |
| `crt_id_card_configs` | `orientation` | `'portrait','landscape'` |
| `crt_student_documents` | `verification_status` | `'pending','verified','rejected'` |

---

## 7. Notable Column Details

| Table | Column | Type | Key Detail |
|---|---|---|---|
| `crt_templates` | `template_content` | LONGTEXT | Full HTML/CSS; NOT TEXT or VARCHAR |
| `crt_templates` | `variables_json` | JSON | Array of merge field names; validated against template_content on save |
| `crt_templates` | `signature_placement_json` | JSON NULL | Optional; x/y/width/height for digital signature block |
| `crt_templates` | `is_default` | TINYINT(1) DEFAULT 0 | Application-enforced: only one per type; toggle clears others |
| `crt_template_versions` | `version_no` | SMALLINT UNSIGNED | Sequential per template; increment before each overwrite |
| `crt_template_versions` | — | (no deleted_at) | Immutable archive — DDL Rule 14 |
| `crt_issued_certificates` | `request_id` | INT UNS NULL | NULL for direct-issue; SET NULL on request delete |
| `crt_issued_certificates` | `validity_date` | DATE NULL | NULL = no expiry (open-ended) |
| `crt_issued_certificates` | `verification_hash` | VARCHAR(64) | HMAC-SHA256 hex of (cert_no+issue_date+recipient_id+APP_KEY) |
| `crt_issued_certificates` | `template_id` | INT UNS | ON DELETE RESTRICT — prevents template hard-delete (BR-CRT-006) |
| `crt_issued_certificates` | `recipient_id` | INT UNS | Polymorphic — no DB FK; app resolves via `recipient_type` |
| `crt_serial_counters` | `last_seq_no` | INT UNSIGNED DEFAULT 0 | Incremented via SELECT FOR UPDATE in DB transaction (BR-CRT-015) |
| `crt_serial_counters` | `academic_year` | SMALLINT UNSIGNED | 4-digit year; counter resets per year |
| `crt_bulk_jobs` | `filter_json` | JSON NULL | Stores `{class_id, section_id, student_ids[]}` filter criteria |
| `crt_bulk_jobs` | `error_log_json` | JSON NULL | Per-student failure log `[{student_id, error}]` |
| `crt_tc_register` | `sl_no` | SMALLINT UNSIGNED | Sequential TC number per year; UNIQUE(sl_no, academic_year) |
| `crt_requests` | `requester_id` | INT UNSIGNED | Polymorphic — no DB FK; resolved via `requester_type` |
| `crt_id_card_configs` | `template_json` | JSON | Full card layout config: field positions, QR placement |
| `crt_id_card_configs` | `cards_per_sheet` | TINYINT UNSIGNED DEFAULT 8 | For CR80 sheet layout (1–20) |

---

## 8. FK Constraint Summary (Intra-Module)

| Constraint Name | Table | Column | References | On Delete |
|---|---|---|---|---|
| `fk_crt_tpl_certificate_type_id` | `crt_templates` | `certificate_type_id` | `crt_certificate_types.id` | CASCADE |
| `fk_crt_sc_certificate_type_id` | `crt_serial_counters` | `certificate_type_id` | `crt_certificate_types.id` | RESTRICT |
| `fk_crt_bj_certificate_type_id` | `crt_bulk_jobs` | `certificate_type_id` | `crt_certificate_types.id` | RESTRICT |
| `fk_crt_tv_template_id` | `crt_template_versions` | `template_id` | `crt_templates.id` | CASCADE |
| `fk_crt_req_certificate_type_id` | `crt_requests` | `certificate_type_id` | `crt_certificate_types.id` | RESTRICT |
| `fk_crt_ic_request_id` | `crt_issued_certificates` | `request_id` | `crt_requests.id` | SET NULL |
| `fk_crt_ic_certificate_type_id` | `crt_issued_certificates` | `certificate_type_id` | `crt_certificate_types.id` | RESTRICT |
| `fk_crt_ic_template_id` | `crt_issued_certificates` | `template_id` | `crt_templates.id` | **RESTRICT** |
| `fk_crt_tc_issued_certificate_id` | `crt_tc_register` | `issued_certificate_id` | `crt_issued_certificates.id` | RESTRICT |

> `fk_crt_tpl_certificate_type_id` → CASCADE: templates cascade-delete with their type (soft-delete only in practice)
> `fk_crt_tv_template_id` → CASCADE: version archive cascade-deletes with its template
> `fk_crt_ic_template_id` → **RESTRICT**: prevents hard-deleting a template referenced by issued certs (BR-CRT-006)

---

## 9. Composite Index Summary

| Index Name | Table | Columns | Type | Query Optimised |
|---|---|---|---|---|
| `idx_crt_req_student_type_status` | `crt_requests` | `(beneficiary_student_id, certificate_type_id, status)` | INDEX | Duplicate request check (AC7 FR-CRT-003) |
| `uq_crt_sc_type_year` | `crt_serial_counters` | `(certificate_type_id, academic_year)` | UNIQUE | nextForType() serial counter lookup |
| `uq_crt_tc_sl_year` | `crt_tc_register` | `(sl_no, academic_year)` | UNIQUE | TC register year-wise uniqueness |
| `idx_crt_ic_recipient` | `crt_issued_certificates` | `(recipient_type, recipient_id)` | INDEX | "All certs for this student" query |

---

## 10. Artisan Commands

```bash
# Run all CRT seeders (install)
php artisan module:seed Certificate --class=CrtSeederRunner

# Run only type seeder (minimum for tests)
php artisan module:seed Certificate --class=CrtCertificateTypeSeeder

# Run migration (tenant DB)
php artisan tenants:migrate --path=Modules/Certificate/database/migrations

# Run migration rollback
php artisan tenants:migrate:rollback --path=Modules/Certificate/database/migrations

# Scheduled Artisan command (registered in routes/console.php)
# certificate:expire-certificates → runs daily at midnight
php artisan certificate:expire-certificates
```

**Seeder dependency order:**
```
CrtSeederRunner
  └─ CrtCertificateTypeSeeder   (no dependencies — must run first)
  └─ CrtTemplateSeeder          (depends on CrtCertificateTypeSeeder for certificate_type_id)
```
