# CRT — Certificate & Template Module: Development Plan
**Module:** Certificate (`Modules\Certificate`) | **Date:** 2026-03-28
**Status:** Ready to implement | **Dev progress:** 0% Greenfield
**Sources:** `CRT_FeatureSpec.md` + `CRT_Certificate_Requirement.md` v2

---

## Section 1 — Controller Inventory (9 controllers)

All controllers reside in `Modules/Certificate/app/Http/Controllers/`.
All web routes use middleware: `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Certificate']`.

---

### 1.1 CertificateTypeController

**File:** `CertificateTypeController.php`
**FR Coverage:** FR-CRT-001, FR-CRT-010

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `dashboard` | GET | `/certificate/dashboard` | `certificate.dashboard` | — | `CertificateTypePolicy@viewAny` |
| `index` | GET | `/certificate/types` | `certificate.types.index` | — | `CertificateTypePolicy@viewAny` |
| `create` | GET | `/certificate/types/create` | `certificate.types.create` | — | `CertificateTypePolicy@create` |
| `store` | POST | `/certificate/types` | `certificate.types.store` | `StoreCertificateTypeRequest` | `CertificateTypePolicy@create` |
| `show` | GET | `/certificate/types/{type}` | `certificate.types.show` | — | `CertificateTypePolicy@view` |
| `edit` | GET | `/certificate/types/{type}/edit` | `certificate.types.edit` | — | `CertificateTypePolicy@update` |
| `update` | PUT | `/certificate/types/{type}` | `certificate.types.update` | `StoreCertificateTypeRequest` | `CertificateTypePolicy@update` |
| `destroy` | DELETE | `/certificate/types/{type}` | `certificate.types.destroy` | — | `CertificateTypePolicy@delete` |
| `trashed` | GET | `/certificate/types/trashed` | `certificate.types.trashed` | — | `CertificateTypePolicy@viewAny` |
| `restore` | PUT | `/certificate/types/{type}/restore` | `certificate.types.restore` | — | `CertificateTypePolicy@restore` |
| `forceDelete` | DELETE | `/certificate/types/{type}/force-delete` | `certificate.types.forceDelete` | — | `CertificateTypePolicy@forceDelete` |
| `toggleStatus` | PATCH | `/certificate/types/{type}/toggle` | `certificate.types.toggleStatus` | — | `CertificateTypePolicy@update` |

**Notes:**
- `dashboard()` returns aggregate stats: pending requests count, issued today, expiring within 30 days, certificates by type (chart data).
- `toggleStatus()` flips `is_active`; `is_active=0` hides type from portal request form (AC6).
- `forceDelete()` blocked by FK if `crt_issued_certificates` references any certs of this type — propagates DB exception.

---

### 1.2 CertificateTemplateController

**File:** `CertificateTemplateController.php`
**FR Coverage:** FR-CRT-002, BR-CRT-012

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `index` | GET | `/certificate/templates` | `certificate.templates.index` | — | `CertificateTemplatePolicy@viewAny` |
| `create` | GET | `/certificate/templates/create` | `certificate.templates.create` | — | `CertificateTemplatePolicy@create` |
| `store` | POST | `/certificate/templates` | `certificate.templates.store` | `StoreCertificateTemplateRequest` | `CertificateTemplatePolicy@create` |
| `show` | GET | `/certificate/templates/{tpl}` | `certificate.templates.show` | — | `CertificateTemplatePolicy@view` |
| `edit` | GET | `/certificate/templates/{tpl}/edit` | `certificate.templates.edit` | — | `CertificateTemplatePolicy@update` |
| `update` | PUT | `/certificate/templates/{tpl}` | `certificate.templates.update` | `StoreCertificateTemplateRequest` | `CertificateTemplatePolicy@update` |
| `destroy` | DELETE | `/certificate/templates/{tpl}` | `certificate.templates.destroy` | — | `CertificateTemplatePolicy@delete` |
| `preview` | GET | `/certificate/templates/{tpl}/preview` | `certificate.templates.preview` | — | `CertificateTemplatePolicy@view` |
| `versions` | GET | `/certificate/templates/{tpl}/versions` | `certificate.templates.versions` | — | `CertificateTemplatePolicy@view` |
| `restoreVersion` | POST | `/certificate/templates/{tpl}/restore-version/{v}` | `certificate.templates.restoreVersion` | — | `CertificateTemplatePolicy@update` |

**Notes:**
- `update()` — before overwriting: (a) increment `version_no`, (b) INSERT into `crt_template_versions` with current content, (c) UPDATE template.
- `preview()` — renders template with dummy student data via DomPDF; returns inline PDF response (`Content-Disposition: inline`).
- `restoreVersion()` — creates a new version entry for current content first (same as update), then replaces content with the archived version.
- BR-CRT-012 enforcement in `store()`/`update()`: if `is_default=true`, wrap in DB::transaction, set all others to `is_default=0` first, then insert/update.
- `destroy()` — soft delete only; hard delete blocked by `fk_crt_ic_template_id` (RESTRICT).

---

### 1.3 CertificateRequestController

**File:** `CertificateRequestController.php`
**FR Coverage:** FR-CRT-003

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `index` | GET | `/certificate/requests` | `certificate.requests.index` | — | `CertificateRequestPolicy@viewAny` |
| `create` | GET | `/certificate/requests/create` | `certificate.requests.create` | — | `CertificateRequestPolicy@create` |
| `store` | POST | `/certificate/requests` | `certificate.requests.store` | `StoreCertificateRequestRequest` | `CertificateRequestPolicy@create` |
| `show` | GET | `/certificate/requests/{req}` | `certificate.requests.show` | — | `CertificateRequestPolicy@view` |
| `approve` | POST | `/certificate/requests/{req}/approve` | `certificate.requests.approve` | `ApproveCertificateRequestRequest` | `CertificateRequestPolicy@approve` |
| `reject` | POST | `/certificate/requests/{req}/reject` | `certificate.requests.reject` | `RejectCertificateRequestRequest` | `CertificateRequestPolicy@reject` |

**Notes:**
- `store()`: auto-generates `request_no = REQ-{YYYY}-{SEQ6}`; if `certificate_type.requires_approval = false`, immediately sets `status = 'approved'` and calls `CertificateGenerationService::generateFromRequest()`.
- `approve()`: sets `status = 'approved'`, `approved_by`, `approved_at`; calls `CertificateGenerationService::generateFromRequest()`; fires `CertificateRequestApproved` event.
- `reject()`: sets `status = 'rejected'`; `rejection_reason` validated as required (BR-CRT-013).

---

### 1.4 CertificateIssuedController

**File:** `CertificateIssuedController.php`
**FR Coverage:** FR-CRT-004, FR-CRT-005

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `index` | GET | `/certificate/issued` | `certificate.issued.index` | — | `CertificateIssuedPolicy@viewAny` |
| `show` | GET | `/certificate/issued/{cert}` | `certificate.issued.show` | — | `CertificateIssuedPolicy@view` |
| `download` | GET | `/certificate/issued/{cert}/download` | `certificate.issued.download` | — | `CertificateIssuedPolicy@download` |
| `revoke` | POST | `/certificate/issued/{cert}/revoke` | `certificate.issued.revoke` | `RevokeCertificateRequest` | `CertificateIssuedPolicy@revoke` |
| `tcRegister` | GET | `/certificate/tc-register` | `certificate.tc-register` | — | `CertificateIssuedPolicy@viewAny` |

**Notes:**
- `download()` — returns `Storage::temporaryUrl()` or signed route; download event logged to `sys_activity_logs`.
- `revoke()` — sets `is_revoked=1`, `revoked_at`, `revoked_by`, `revocation_reason`; download blocked after revocation.
- `tcRegister()` — returns printable TC register table (Admin / Principal only); sorted by `academic_year DESC, sl_no ASC`.

---

### 1.5 BulkGenerationController

**File:** `BulkGenerationController.php`
**FR Coverage:** FR-CRT-006, BR-CRT-009

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `index` | GET | `/certificate/bulk-generate` | `certificate.bulk-generate.index` | — | `BulkGenerationPolicy@create` |
| `generate` | POST | `/certificate/bulk-generate` | `certificate.bulk-generate.generate` | `BulkGenerateCertificatesRequest` | `BulkGenerationPolicy@create` |
| `status` | GET | `/certificate/bulk-generate/{job}/status` | `certificate.bulk-generate.status` | — | `BulkGenerationPolicy@view` |
| `download` | GET | `/certificate/bulk-generate/{job}/download` | `certificate.bulk-generate.download` | — | `BulkGenerationPolicy@download` |

**Notes:**
- `generate()` — count students from filter: if count ≤ 200 → synchronous loop; if count > 200 → `BulkGenerateCertificatesJob::dispatch()` (BR-CRT-009 — mandatory queue above threshold).
- `status()` — JSON endpoint polled every 3 seconds from Bulk Generation view (CRT-S13); returns `{status, processed_count, total_count, failed_count, percent}`.
- `download()` — only available when `crt_bulk_jobs.status = 'completed'`; returns ZIP from `zip_path`.

---

### 1.6 IdCardController

**File:** `IdCardController.php`
**FR Coverage:** FR-CRT-008, BR-CRT-007

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `indexConfig` | GET | `/certificate/id-card-config` | `certificate.id-card-config.index` | — | `IdCardPolicy@viewAny` |
| `createConfig` | GET | `/certificate/id-card-config/create` | `certificate.id-card-config.create` | — | `IdCardPolicy@create` |
| `storeConfig` | POST | `/certificate/id-card-config` | `certificate.id-card-config.store` | `StoreIdCardConfigRequest` | `IdCardPolicy@create` |
| `editConfig` | GET | `/certificate/id-card-config/{cfg}/edit` | `certificate.id-card-config.edit` | — | `IdCardPolicy@update` |
| `updateConfig` | PUT | `/certificate/id-card-config/{cfg}` | `certificate.id-card-config.update` | `StoreIdCardConfigRequest` | `IdCardPolicy@update` |
| `generateForm` | GET | `/certificate/id-cards/generate` | `certificate.id-cards.generateForm` | — | `IdCardPolicy@create` |
| `generate` | POST | `/certificate/id-cards/generate` | `certificate.id-cards.generate` | — | `IdCardPolicy@create` |
| `markReceived` | PATCH | `/certificate/id-cards/{issued}/received` | `certificate.id-cards.markReceived` | — | `IdCardPolicy@update` |

**Notes:**
- `generate()` — renders ID cards via DomPDF; fetches student photo from `sys_media`; shows placeholder if no photo.
- BR-CRT-007 enforcement in `generate()`: blood group from `std_profiles.blood_group`; render empty field (not hidden) when NULL.
- `markReceived()` — sets `card_received = true`, `received_at = now()`, `received_by = auth()->id()`.

---

### 1.7 DocumentManagementController

**File:** `DocumentManagementController.php`
**FR Coverage:** FR-CRT-009, BR-CRT-008

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `index` | GET | `/certificate/documents` | `certificate.documents.index` | — | `DocumentManagementPolicy@viewAny` |
| `upload` | POST | `/certificate/documents/upload` | `certificate.documents.upload` | `DocumentUploadRequest` | `DocumentManagementPolicy@create` |
| `show` | GET | `/certificate/documents/{doc}` | `certificate.documents.show` | — | `DocumentManagementPolicy@view` |
| `verify` | POST | `/certificate/documents/{doc}/verify` | `certificate.documents.verify` | `VerifyDocumentRequest` | `DocumentManagementPolicy@verify` |
| `download` | GET | `/certificate/documents/{doc}/download` | `certificate.documents.download` | — | `DocumentManagementPolicy@download` |

**Notes:**
- `upload()` — delegates to `DmsService::uploadDocument()`; validates MIME (pdf/jpeg/png) and size (max 5 MB).
- `verify()` — delegates to `DmsService::verifyDocument()`; sets `verification_status`, `verified_by`, `verified_at`; `verification_remarks` required when status = rejected.
- `download()` — logs to `sys_activity_logs` (user_id, document_id, timestamp); returns signed download URL.

---

### 1.8 VerificationController

**File:** `VerificationController.php`
**FR Coverage:** FR-CRT-007, BR-CRT-005, BR-CRT-010

| Method | HTTP | URI | Route Name | Middleware | FormRequest | Policy |
|---|---|---|---|---|---|---|
| `verify` | GET | `/verify/{hash}` | `certificate.verify.public` | **NONE** (public) | — | None — public endpoint |
| `logs` | GET | `/certificate/verification-logs` | `certificate.verification-logs` | auth, tenant | — | `CertificateIssuedPolicy@viewAny` |

**Notes:**
- `verify()` — **NO auth middleware**; accessible by third parties (banks, embassies, universities) without login.
- `verify()` — delegates to `QrVerificationService::verifyHash($hash)`; renders `public/verify.blade.php`.
- Response DTO (BR-CRT-010): **only** `{certificate_type, issued_to_display (first_name + last_initial), school_name, issue_date, validity_status}`. Full name, DOB, class, address **NOT exposed**.
- Rate limiting: `throttle:20,60` on the public `/verify/{hash}` route (20 verifications per IP per hour).
- `logs()` — admin view; filterable by date range, method (qr/api), result (VALID/EXPIRED/REVOKED/NOT_FOUND).

---

### 1.9 CertificateReportController

**File:** `CertificateReportController.php`
**FR Coverage:** FR-CRT-011

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|---|---|---|---|---|---|
| `issued` | GET | `/certificate/reports/issued` | `certificate.reports.issued` | — | `CertificateReportPolicy@view` |
| `pending` | GET | `/certificate/reports/pending` | `certificate.reports.pending` | — | `CertificateReportPolicy@view` |
| `analytics` | GET | `/certificate/reports/analytics` | `certificate.reports.analytics` | — | `CertificateReportPolicy@view` |

**Notes:**
- `issued()` — filterable by type, date range, class/section; exportable to Excel (`fputcsv` or `maatwebsite/excel`).
- `pending()` — highlights overdue requests (`required_by_date < today`) in red; sorted by `required_by_date ASC`.
- `analytics()` — JSON endpoint for Chart.js; returns monthly trend + breakdown by type.

---

## Section 2 — Service Inventory (3 services)

All services reside in `Modules/Certificate/app/Services/`.

---

### 2.1 CertificateGenerationService

```
File:        app/Services/CertificateGenerationService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  QrVerificationService (hash + QR + serial counter)
             DmsService (TC eligibility check — BR-CRT-008)
Fires:       CertificateGenerated (event → NTF module)
             CertificateRequestApproved (via controller — not directly here)
```

**Public Methods:**

```php
generateFromRequest(CertificateRequest $request): CertificateIssued
  // 14-step flow — see pseudocode below

generateDirect(CertificateType $type, int $recipientId, array $extraFields = []): CertificateIssued
  // Achievement/bulk generation without request workflow
  // Calls same generation core (Steps 3-14) with $request = null

generateTC(CertificateRequest $request, array $tcData): CertificateIssued
  // TC-specific: fee-clear gate (BR-CRT-001) + tc_register write + std_students write (BR-CRT-011)
  // Calls generateFromRequest() internally for the cert generation core
  // tc_data = {date_of_leaving, reason_for_leaving, date_of_birth, class_at_leaving, ...}

resolveMergeFields(int $studentId, array $extra = []): array
  // Builds {{placeholder}} → 'value' map from:
  //   std_students (first_name+middle_name+last_name, dob, admission_no, admission_date)
  //   std_profiles (father_name, mother_name, blood_group, nationality, religion)
  //   sch_org_academic_sessions_jnt (name → {{academic_session}})
  //   sch_classes + sch_sections ({{class_section}})
  //   sch_school_profiles ({{school_name}}, {{principal_name}}, {{school_address}})
  // CORRECTION: std_students has first_name + middle_name + last_name (not full_name)
  // {{student_name}} = trim("{$s->first_name} {$s->middle_name} {$s->last_name}")

generateCertificateNo(CertificateType $type): string
  // Delegates to QrVerificationService::incrementSerialCounter($type, $year)
  // Formats result using serial_format tokens
```

**14-Step Generation Pseudocode:**
```
generateFromRequest(CertificateRequest $request): CertificateIssued

  Step 1:  Verify $request->status == 'approved'; throw GenerationException if not
  Step 2:  Load CertificateType; load active default CertificateTemplate (is_default=1, is_active=1)
           Throw if no default template exists for this type
  Step 3:  $mergeFields = resolveMergeFields($request->beneficiary_student_id, $request->extra)
           // Builds ['{{student_name}}' => 'Rahul Sharma', '{{issue_date}}' => '27 Mar 2026', ...]
  Step 4:  DB::transaction begins
  Step 5:  $certificateNo = QrVerificationService::incrementSerialCounter($type, now()->year)
           // SELECT ... FOR UPDATE; returns formatted string e.g. BON-2026-000042
  Step 6:  Check if crt_issued_certificates WHERE recipient_id = $student_id AND certificate_type_id = $type->id EXISTS
           → $isDuplicate = (bool) existing cert found
  Step 7:  $certDto = (object)['certificate_no' => $certificateNo, 'issue_date' => today(),
                               'recipient_id' => $request->beneficiary_student_id]
           $hash = QrVerificationService::generateVerificationHash($certDto)
           // HMAC-SHA256 of (certificate_no . issue_date . recipient_id . APP_KEY) → 64-char hex
  Step 8:  $verifyUrl = route('certificate.verify.public', ['hash' => $hash])
           $qrBase64 = QrVerificationService::generateQrCode($verifyUrl)
           // Inject into $mergeFields: $mergeFields['{{qr_code}}'] = '<img src="data:image/png;base64,{$qrBase64}">'
  Step 9:  Replace all {{placeholder}} in $template->template_content with $mergeFields values
           If $isDuplicate: inject "DUPLICATE COPY" watermark CSS into rendered HTML (BR-CRT-003)
           Render via Barryvdh\DomPDF\Facade\Pdf::loadHTML($html)->setPaper($pageSize, $orient)
           $filePath = "certificates/{$type->code}/{$year}/{$certificateNo}.pdf"
           Storage::put("tenant_{$tenantId}/{$filePath}", $pdf->output())
  Step 10: $cert = CrtIssuedCertificate::create([
             'certificate_no' => $certificateNo,
             'request_id' => $request->id,
             'certificate_type_id' => $type->id,
             'template_id' => $template->id,
             'recipient_type' => 'student',
             'recipient_id' => $request->beneficiary_student_id,
             'issue_date' => today(),
             'validity_date' => $type->validity_days ? today()->addDays($type->validity_days) : null,
             'verification_hash' => $hash,
             'file_path' => $filePath,
             'is_duplicate' => $isDuplicate,
             'created_by' => auth()->id(), 'updated_by' => auth()->id(),
           ])
  Step 11: If $type->code == 'TC':
             // BR-CRT-001: Check fin_fee_dues
             $feeDues = DB::table('fin_fee_dues')
                          ->where('student_id', $request->beneficiary_student_id)
                          ->where('is_paid', 0)->sum('amount');
             if ($feeDues > 0 && !$request->override_justification) {
               DB::rollBack(); throw new FeeOutstandingException("Outstanding fees: {$feeDues}");
             }
             // Write TC register (sl_no via separate SELECT FOR UPDATE on serial counter for TC)
             $tcSlNo = QrVerificationService::incrementTcSlNo(now()->year);
             CrtTcRegister::create([...all tc_data fields..., 'sl_no' => $tcSlNo])
             // BR-CRT-011: Update std_students (direct write — not event)
             DB::table('std_students')
               ->where('id', $request->beneficiary_student_id)
               ->update(['tc_issued' => true])
             // Update student status to 'Withdrawn' via current_status_id
             $withdrawnStatusId = DB::table('sys_dropdown_table')
               ->where('key', 'std_students.current_status_id')
               ->where('value', 'Withdrawn')->value('id');
             DB::table('std_students')
               ->where('id', $request->beneficiary_student_id)
               ->update(['current_status_id' => $withdrawnStatusId]);
  Step 12: $request->update(['status' => 'generated'])
  Step 13: DB::transaction commits
  Step 14: event(new CertificateGenerated($cert))
           → NTF module listener sends email+SMS with download link to requester
```

**Events fired:**
- `CertificateGenerated` — fired in Step 14

---

### 2.2 QrVerificationService

```
File:        app/Services/QrVerificationService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  (none — standalone)
Fires:       (none — logs directly to sys_activity_logs)
```

**Public Methods:**

```php
generateVerificationHash(object $certDto): string
  // HMAC-SHA256 of ($certDto->certificate_no . $certDto->issue_date . $certDto->recipient_id . config('app.key'))
  // Returns 64-char lowercase hex string
  // IMMUTABLE after issuance — must use identical inputs at generation time

generateQrCode(string $verificationUrl): string
  // QrCode::format('png')->size(150)->generate($verificationUrl)
  // Returns base64-encoded PNG string
  // Embedded in HTML as: <img src="data:image/png;base64,{$base64}" width="100" height="100">

verifyHash(string $hash, Request $request): array
  // Returns DTO array for VerificationController

incrementSerialCounter(CertificateType $type, int $year): string
  // SELECT FOR UPDATE — see pseudocode below

incrementTcSlNo(int $year): int
  // Same SELECT FOR UPDATE pattern for TC register sl_no
  // Uses a dedicated counter row (certificate_type_id = TC type id, academic_year = year)
```

**`incrementSerialCounter()` Pseudocode — SELECT FOR UPDATE:**
```
incrementSerialCounter(CertificateType $type, int $year): string
  Step 1: DB::transaction begins
  Step 2: $counter = CrtSerialCounter::where([
                'certificate_type_id' => $type->id,
                'academic_year'       => $year,
              ])->lockForUpdate()
               ->firstOrCreate([
                 'certificate_type_id' => $type->id,
                 'academic_year' => $year,
                 'last_seq_no' => 0,
                 'is_active' => 1,
                 'created_by' => 1, 'updated_by' => 1,
               ])
  Step 3: $counter->increment('last_seq_no')
  Step 4: DB::transaction commits
  Step 5: return formatCertificateNo($type->serial_format, $type->code, $year, $counter->fresh()->last_seq_no)

formatCertificateNo(string $format, string $code, int $year, int $seq): string
  → replace '{TYPE_CODE}' with $code            (e.g. BON)
  → replace '{YYYY}'      with $year            (e.g. 2026)
  → replace '{YY}'        with substr($year, 2) (e.g. 26)
  → replace '{SEQ6}'      with str_pad($seq, 6, '0', STR_PAD_LEFT)   (e.g. 000042)
  → replace '{SEQ4}'      with str_pad($seq, 4, '0', STR_PAD_LEFT)   (e.g. 0042)
  Example: 'BON-2026-000042'
```

**`verifyHash()` response DTO:**
```
verifyHash(string $hash, Request $request): array
  → $cert = CrtIssuedCertificate::where('verification_hash', $hash)->first()
  → if (!$cert):  result = 'NOT_FOUND'
  → if $cert->is_revoked:  result = 'REVOKED'
  → if $cert->validity_date && $cert->validity_date->isPast():  result = 'EXPIRED'
  → else:  result = 'VALID'

  // Log to sys_activity_logs (BR-CRT-007 AC3)
  sys_activity_logs::create([
    'action'     => 'certificate_verification',
    'model_type' => CrtIssuedCertificate::class,
    'model_id'   => $cert?->id,
    'properties' => ['method' => 'qr', 'result' => $result, 'ip' => $request->ip(),
                     'user_agent' => $request->userAgent()],
  ])

  // Return privacy-respecting DTO (BR-CRT-010 — NO full_name, DOB, class, address)
  return [
    'result'           => $result,    // 'VALID'|'EXPIRED'|'REVOKED'|'NOT_FOUND'
    'certificate_type' => $cert?->type->name,
    'issued_to'        => $this->firstNameLastInitial($cert),  // "Rahul S." not "Rahul Sharma"
    'school_name'      => config('tenant.school_name'),
    'issue_date'       => $cert?->issue_date?->format('d M Y'),
    'validity_status'  => $result,
    'expires_on'       => $cert?->validity_date?->format('d M Y') ?? 'No Expiry',
  ]
```

---

### 2.3 DmsService

```
File:        app/Services/DmsService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  (none — uses sys_media polymorphic directly)
Fires:       (none)
```

**Public Methods:**

```php
uploadDocument(int $studentId, UploadedFile $file, array $meta): StudentDocument
  // Store file: Storage::putFile("tenant_{id}/documents/{studentId}/", $file)
  // Insert into sys_media (model_type='StudentDocument', model_id=null temporarily)
  // Insert into crt_student_documents (student_id, document_category_id, document_name, media_id, status='pending')
  // Update sys_media.model_id = $document->id
  // Log upload to sys_activity_logs
  // Returns StudentDocument model

verifyDocument(StudentDocument $doc, string $status, ?string $remarks, int $verifierId): void
  // Validates: $status in ['verified', 'rejected']; remarks required if rejected
  // $doc->update(['verification_status' => $status, 'verification_remarks' => $remarks,
  //               'verified_by' => $verifierId, 'verified_at' => now()])
  // Log verification action to sys_activity_logs

getDocumentsByStudent(int $studentId): Collection
  // CrtStudentDocument::with(['media', 'category'])->where('student_id', $studentId)->get()

hasVerifiedDocument(int $studentId, string $categoryCode): bool
  // $catId = DB::table('sys_dropdown_table')
  //            ->where('key', 'crt_student_documents.document_category_id')
  //            ->where('value', $categoryCode)->value('id')
  // return CrtStudentDocument::where('student_id', $studentId)
  //         ->where('document_category_id', $catId)
  //         ->where('verification_status', 'verified')  // 'rejected' does NOT qualify (BR-CRT-008)
  //         ->whereNull('deleted_at')->exists()
```

---

## Section 3 — FormRequest Inventory (10 FormRequests)

All FormRequests reside in `Modules/Certificate/app/Http/Requests/`.

| # | Class | Controller@Method | Key Validation Rules |
|---|---|---|---|
| 1 | `StoreCertificateTypeRequest` | `store`, `update` | `name` required string max:150; `code` required alphanumeric max:10; `category` in ENUM; `requires_approval` boolean; `validity_days` nullable integer min:1; `serial_format` required with valid tokens {TYPE_CODE}, {YYYY|YY}, {SEQ4|SEQ6}; `code` unique:crt_certificate_types,code except current on update |
| 2 | `StoreCertificateTemplateRequest` | `store`, `update` | `certificate_type_id` required exists:crt_certificate_types,id; `name` required string max:150; `template_content` required longText; `variables_json` required array — all `{{field}}` in template_content must appear in this array (custom Rule: `VariablesMatchPlaceholders`); `page_size` in ['a4','a5','letter','custom']; `orientation` in ['portrait','landscape']; `is_default` nullable boolean; `signature_placement_json` nullable array |
| 3 | `StoreCertificateRequestRequest` | `store` | `certificate_type_id` required exists:crt_certificate_types,id AND `is_active=1`; `requester_type` in ENUM; `beneficiary_student_id` required exists:std_students,id; `purpose` required string max:1000; `required_by_date` nullable date after:today; `supporting_doc_media_id` nullable exists:sys_media,id; custom Rule: no pending/under_review/approved request exists for same `(beneficiary_student_id, certificate_type_id)` |
| 4 | `ApproveCertificateRequestRequest` | `approve` | `approval_remarks` nullable string max:500 |
| 5 | `RejectCertificateRequestRequest` | `reject` | `rejection_reason` **required** string max:2000 (BR-CRT-013 — NOT NULL) |
| 6 | `RevokeCertificateRequest` | `revoke` | `revocation_reason` required string max:2000 |
| 7 | `BulkGenerateCertificatesRequest` | `generate` | `certificate_type_id` required exists:crt_certificate_types,id AND is_active=1; `class_id` nullable exists:sch_classes,id; `section_id` nullable exists:sch_sections,id; `student_ids` nullable array; `student_ids.*` exists:std_students,id; custom Rule: at least one of (`class_id`, `student_ids`) is provided |
| 8 | `StoreIdCardConfigRequest` | `storeConfig`, `updateConfig` | `card_type` required in ['student','staff']; `name` required string max:150; `academic_session_id` required exists:sch_org_academic_sessions_jnt,id; `card_size` in ['a5','cr80']; `orientation` in ['portrait','landscape']; `template_json` required array; `cards_per_sheet` integer min:1 max:20 |
| 9 | `DocumentUploadRequest` | `upload` | `student_id` required exists:std_students,id; `document_category_id` required exists:sys_dropdown_table,id; `document_name` required string max:255; `document_date` nullable date; `file` required file mimes:pdf,jpeg,png max:5120 (5 MB) |
| 10 | `VerifyDocumentRequest` | `verify` | `verification_status` required in ['verified','rejected']; `verification_remarks` required_if:verification_status,rejected string max:2000 |

---

## Section 4 — Blade View Inventory (~30 views)

All views reside in `Modules/Certificate/resources/views/certificate/`.

### Dashboard (1 view)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `dashboard.blade.php` | `certificate.dashboard` | `CertificateTypeController@dashboard` | Stats tiles: pending, issued today, expiring soon; quick links to each sub-module |

### Certificate Types (2 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `types/index.blade.php` | `certificate.types.index` | `index` | Paginated table: code, category, requires_approval badge, is_active toggle |
| `types/form.blade.php` | `certificate.types.create` / `edit` | `create`, `edit` | Form: name, code, category dropdown, validity_days, serial_format, requires_approval checkbox |

### Templates (4 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `templates/index.blade.php` | `certificate.templates.index` | `index` | Grouped by certificate type; default badge; Preview button per row |
| `templates/form.blade.php` | `certificate.templates.create` / `edit` | `create`, `edit` | **Template Designer (CRT-S05):** HTML/CSS textarea + merge field chip list + AJAX live preview pane; `fetch('/certificate/templates/{id}/preview')` on change |
| `templates/preview.blade.php` | `certificate.templates.preview` | `preview` | Inline `<embed>` PDF with dummy student data; used by both admin preview and AJAX pane |
| `templates/versions.blade.php` | `certificate.templates.versions` | `versions` | Timeline of version snapshots; version_no, saved_by, saved_at; Restore button per version |

### Requests (3 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `requests/index.blade.php` | `certificate.requests.index` | `index` | Tabs: Pending / Under Review / All; urgency badge for required_by_date; search by student name |
| `requests/create.blade.php` | `certificate.requests.create` | `create` | Step form: select type → student → purpose → attach supporting doc |
| `requests/show.blade.php` | `certificate.requests.show` | `show` | Student profile panel + attached doc viewer + Approve / Reject action buttons |

### Issued (2 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `issued/index.blade.php` | `certificate.issued.index` | `index` | Searchable/filterable register; Download and Revoke buttons per row |
| `issued/show.blade.php` | `certificate.issued.show` | `show` | Full metadata + embedded QR preview + download link + revoke action |

### Bulk Generation (1 view)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `bulk/generate.blade.php` | `certificate.bulk-generate.index` | `index` | **CRT-S13:** Class/section picker + student_ids multi-select + JS polling `/{job}/status` every 3s + progress bar + ZIP download button on completion |

### ID Cards (3 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `id-cards/config-index.blade.php` | `certificate.id-card-config.index` | `indexConfig` | Config list by card_type; Preview layout button |
| `id-cards/config-form.blade.php` | `certificate.id-card-config.create` / `edit` | `createConfig`, `editConfig` | Layout editor: field positions, colors, QR placement, cards_per_sheet |
| `id-cards/generate.blade.php` | `certificate.id-cards.generateForm` | `generateForm` | Filter form: class/section/config → preview grid → generate PDF + markReceived per row |

### Document Management (3 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `dms/index.blade.php` | `certificate.documents.index` | `index` | Student search → paginated document list with verification status badges |
| `dms/upload.blade.php` | `certificate.documents.upload` | (form in index) | Drag-and-drop upload; category picker from sys_dropdown_table; document_name input |
| `dms/show.blade.php` | `certificate.documents.show` | `show` | Inline PDF/image viewer (embedded via URL) + Verify / Reject action panel |

### Verification & TC (2 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `verification/logs.blade.php` | `certificate.verification-logs` | `VerificationController@logs` | Paginated verification log; filter by method, date range, result |
| `tc/register.blade.php` | `certificate.tc-register` | `CertificateIssuedController@tcRegister` | Formal printable register table sorted by sl_no; print button |

### Reports (3 views)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `reports/issued.blade.php` | `certificate.reports.issued` | `issued` | Filter + paginated table; Export CSV/Excel button |
| `reports/pending.blade.php` | `certificate.reports.pending` | `pending` | Overdue highlighted red; sorted by required_by_date; urgency indicator |
| `reports/analytics.blade.php` | `certificate.reports.analytics` | `analytics` | Chart.js bar chart (monthly trend) + pie chart (by type); data from JSON endpoint |

### Public Verification (1 view)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `public/verify.blade.php` | `certificate.verify.public` | `VerificationController@verify` | **No login.** VALID/EXPIRED/REVOKED/NOT_FOUND banner; strict DTO: first name + last initial + school name only (BR-CRT-010); QR decode info |

### Portal (1 view)
| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `portal/my-certificates.blade.php` | `portal.certificate.index` | (portal controller) | Student/parent portal: own requests + issued certs + download links; status timeline per request (FR-CRT-012) |

### Shared Partials (~4 files)
| View File | Used By | Description |
|---|---|---|
| `_partials/pagination.blade.php` | All list views | Standard paginator with page-size selector |
| `_partials/export-buttons.blade.php` | Report views | Export CSV / Export Excel buttons |
| `_partials/status-badge.blade.php` | Request/issued lists | Colour-coded status badge (pending=yellow, approved=blue, issued=green, rejected=red) |
| `_partials/qr-preview.blade.php` | `issued/show`, `tc/register` | Inline QR code image + verification URL text |

**View count:** 1 dashboard + 2 types + 4 templates + 3 requests + 2 issued + 1 bulk + 3 id-cards + 3 DMS + 2 verification/TC + 3 reports + 1 public + 1 portal + 4 partials = **30 views** ✅

---

## Section 5 — Complete Route List

### 6.1 Web Routes (`tenant.php` — prefix: `certificate`)
**Middleware:** `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Certificate']`

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 1 | GET | `/certificate/dashboard` | `certificate.dashboard` | `CertificateTypeController@dashboard` | FR-001 |
| 2 | GET | `/certificate/types` | `certificate.types.index` | `CertificateTypeController@index` | FR-001 |
| 3 | GET | `/certificate/types/create` | `certificate.types.create` | `CertificateTypeController@create` | FR-001 |
| 4 | POST | `/certificate/types` | `certificate.types.store` | `CertificateTypeController@store` | FR-001 |
| 5 | GET | `/certificate/types/{type}` | `certificate.types.show` | `CertificateTypeController@show` | FR-001 |
| 6 | GET | `/certificate/types/{type}/edit` | `certificate.types.edit` | `CertificateTypeController@edit` | FR-001 |
| 7 | PUT | `/certificate/types/{type}` | `certificate.types.update` | `CertificateTypeController@update` | FR-001 |
| 8 | DELETE | `/certificate/types/{type}` | `certificate.types.destroy` | `CertificateTypeController@destroy` | FR-001 |
| 9 | GET | `/certificate/types/trashed` | `certificate.types.trashed` | `CertificateTypeController@trashed` | FR-001 |
| 10 | PUT | `/certificate/types/{type}/restore` | `certificate.types.restore` | `CertificateTypeController@restore` | FR-001 |
| 11 | DELETE | `/certificate/types/{type}/force-delete` | `certificate.types.forceDelete` | `CertificateTypeController@forceDelete` | FR-001 |
| 12 | PATCH | `/certificate/types/{type}/toggle` | `certificate.types.toggleStatus` | `CertificateTypeController@toggleStatus` | FR-001 |
| 13 | GET | `/certificate/templates` | `certificate.templates.index` | `CertificateTemplateController@index` | FR-002 |
| 14 | GET | `/certificate/templates/create` | `certificate.templates.create` | `CertificateTemplateController@create` | FR-002 |
| 15 | POST | `/certificate/templates` | `certificate.templates.store` | `CertificateTemplateController@store` | FR-002 |
| 16 | GET | `/certificate/templates/{tpl}` | `certificate.templates.show` | `CertificateTemplateController@show` | FR-002 |
| 17 | GET | `/certificate/templates/{tpl}/edit` | `certificate.templates.edit` | `CertificateTemplateController@edit` | FR-002 |
| 18 | PUT | `/certificate/templates/{tpl}` | `certificate.templates.update` | `CertificateTemplateController@update` | FR-002 |
| 19 | DELETE | `/certificate/templates/{tpl}` | `certificate.templates.destroy` | `CertificateTemplateController@destroy` | FR-002 |
| 20 | GET | `/certificate/templates/{tpl}/preview` | `certificate.templates.preview` | `CertificateTemplateController@preview` | FR-002 |
| 21 | GET | `/certificate/templates/{tpl}/versions` | `certificate.templates.versions` | `CertificateTemplateController@versions` | FR-002 |
| 22 | POST | `/certificate/templates/{tpl}/restore-version/{v}` | `certificate.templates.restoreVersion` | `CertificateTemplateController@restoreVersion` | FR-002 |
| 23 | GET | `/certificate/requests` | `certificate.requests.index` | `CertificateRequestController@index` | FR-003 |
| 24 | GET | `/certificate/requests/create` | `certificate.requests.create` | `CertificateRequestController@create` | FR-003 |
| 25 | POST | `/certificate/requests` | `certificate.requests.store` | `CertificateRequestController@store` | FR-003 |
| 26 | GET | `/certificate/requests/{req}` | `certificate.requests.show` | `CertificateRequestController@show` | FR-003 |
| 27 | POST | `/certificate/requests/{req}/approve` | `certificate.requests.approve` | `CertificateRequestController@approve` | FR-003, FR-004 |
| 28 | POST | `/certificate/requests/{req}/reject` | `certificate.requests.reject` | `CertificateRequestController@reject` | FR-003 |
| 29 | GET | `/certificate/issued` | `certificate.issued.index` | `CertificateIssuedController@index` | FR-004 |
| 30 | GET | `/certificate/issued/{cert}` | `certificate.issued.show` | `CertificateIssuedController@show` | FR-004 |
| 31 | GET | `/certificate/issued/{cert}/download` | `certificate.issued.download` | `CertificateIssuedController@download` | FR-004 |
| 32 | POST | `/certificate/issued/{cert}/revoke` | `certificate.issued.revoke` | `CertificateIssuedController@revoke` | FR-004 |
| 33 | GET | `/certificate/tc-register` | `certificate.tc-register` | `CertificateIssuedController@tcRegister` | FR-005 |
| 34 | GET | `/certificate/bulk-generate` | `certificate.bulk-generate.index` | `BulkGenerationController@index` | FR-006 |
| 35 | POST | `/certificate/bulk-generate` | `certificate.bulk-generate.generate` | `BulkGenerationController@generate` | FR-006 |
| 36 | GET | `/certificate/bulk-generate/{job}/status` | `certificate.bulk-generate.status` | `BulkGenerationController@status` | FR-006 |
| 37 | GET | `/certificate/bulk-generate/{job}/download` | `certificate.bulk-generate.download` | `BulkGenerationController@download` | FR-006 |
| 38 | GET | `/certificate/id-card-config` | `certificate.id-card-config.index` | `IdCardController@indexConfig` | FR-008 |
| 39 | GET | `/certificate/id-card-config/create` | `certificate.id-card-config.create` | `IdCardController@createConfig` | FR-008 |
| 40 | POST | `/certificate/id-card-config` | `certificate.id-card-config.store` | `IdCardController@storeConfig` | FR-008 |
| 41 | GET | `/certificate/id-card-config/{cfg}/edit` | `certificate.id-card-config.edit` | `IdCardController@editConfig` | FR-008 |
| 42 | PUT | `/certificate/id-card-config/{cfg}` | `certificate.id-card-config.update` | `IdCardController@updateConfig` | FR-008 |
| 43 | GET | `/certificate/id-cards/generate` | `certificate.id-cards.generateForm` | `IdCardController@generateForm` | FR-008 |
| 44 | POST | `/certificate/id-cards/generate` | `certificate.id-cards.generate` | `IdCardController@generate` | FR-008 |
| 45 | PATCH | `/certificate/id-cards/{issued}/received` | `certificate.id-cards.markReceived` | `IdCardController@markReceived` | FR-008 |
| 46 | GET | `/certificate/documents` | `certificate.documents.index` | `DocumentManagementController@index` | FR-009 |
| 47 | POST | `/certificate/documents/upload` | `certificate.documents.upload` | `DocumentManagementController@upload` | FR-009 |
| 48 | GET | `/certificate/documents/{doc}` | `certificate.documents.show` | `DocumentManagementController@show` | FR-009 |
| 49 | POST | `/certificate/documents/{doc}/verify` | `certificate.documents.verify` | `DocumentManagementController@verify` | FR-009 |
| 50 | GET | `/certificate/documents/{doc}/download` | `certificate.documents.download` | `DocumentManagementController@download` | FR-009 |
| 51 | GET | `/certificate/verification-logs` | `certificate.verification-logs` | `VerificationController@logs` | FR-007 |
| 52 | GET | `/certificate/reports/issued` | `certificate.reports.issued` | `CertificateReportController@issued` | FR-011 |
| 53 | GET | `/certificate/reports/pending` | `certificate.reports.pending` | `CertificateReportController@pending` | FR-011 |
| 54 | GET | `/certificate/reports/analytics` | `certificate.reports.analytics` | `CertificateReportController@analytics` | FR-011 |

**Web routes subtotal: 54**

### 6.2 Public Routes (no auth — `web.php`)
> Rate limited: `throttle:20,60` (20 req/IP/hour)

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 55 | GET | `/verify/{hash}` | `certificate.verify.public` | `VerificationController@verify` | FR-007 |

**⚠️ NO auth middleware on this route** — accessible by third parties without login (FR-CRT-007 AC2)

### 6.3 API Routes (`api.php` — API key auth)

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 56 | GET | `/api/v1/certificate/verify` | `api.certificate.verify` | `Api\CertificateVerifyController@verify` | FR-007 |

**Auth:** query param `api_key=` checked against hashed value in tenant config. Unauthorised → HTTP 401 (FR-CRT-007 AC5).

### 6.4 Portal Routes (`tenant.php` — student/parent only)
**Middleware:** `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Certificate', 'role:Student|Parent']`

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 57 | GET | `/portal/certificate/my-certificates` | `portal.certificate.index` | `Portal\CertificatePortalController@index` | FR-012 |
| 58 | GET | `/portal/certificate/requests/create` | `portal.certificate.requests.create` | `Portal\CertificatePortalController@create` | FR-012 |
| 59 | POST | `/portal/certificate/requests` | `portal.certificate.requests.store` | `Portal\CertificatePortalController@store` | FR-012 |
| 60 | GET | `/portal/certificate/requests/{req}` | `portal.certificate.requests.show` | `Portal\CertificatePortalController@show` | FR-012 |

**Portal routes subtotal: 4**

---

**Total routes: 54 (web) + 1 (public) + 1 (API) + 4 (portal) = 60 routes** ✅

---

## Section 6 — Implementation Phases (4 phases)

---

### Phase 1 — Foundation: Types, Templates, DDL, Seeders

**FRs covered:** FR-CRT-001, FR-CRT-002, FR-CRT-010
**Cross-module deps:** `sys_users` only (no std_*, fin_*, sch_* needed)

**Files to create:**

| Category | File(s) |
|---|---|
| DDL / Migration | `CRT_DDL_v1.sql`, `CRT_Migration.php` (from Phase 2 output) |
| Seeders | `CrtCertificateTypeSeeder`, `CrtTemplateSeeder`, `CrtSeederRunner` |
| Models | `CertificateType`, `CertificateTemplate`, `CertificateTemplateVersion`, `SerialCounter` |
| Controllers | `CertificateTypeController` (full CRUD + trashed/restore/forceDelete + toggleStatus + dashboard), `CertificateTemplateController` (full CRUD + preview + versions + restoreVersion) |
| FormRequests | `StoreCertificateTypeRequest`, `StoreCertificateTemplateRequest` |
| Services | `QrVerificationService` (generateVerificationHash, generateQrCode, incrementSerialCounter — stubs for verifyHash) |
| Views | `dashboard.blade.php`, `types/index.blade.php`, `types/form.blade.php`, `templates/index.blade.php`, `templates/form.blade.php`, `templates/preview.blade.php`, `templates/versions.blade.php` |
| Policies | `CertificateTypePolicy`, `CertificateTemplatePolicy` |
| Routes | All 12 type routes + 10 template routes in `tenant.php` |

**Tests to write:** `CertificateTypeTest` (T01, T02, duplicate code, toggleStatus), `CertificateTemplateTest` (T03, T04, T05, T06 — versioning, default toggle)

**Estimated test count:** 12–15 feature tests

---

### Phase 2 — Request Workflow + Core Generation

**FRs covered:** FR-CRT-003, FR-CRT-004, FR-CRT-007
**Cross-module deps:** `std_students`, `std_profiles`, `sch_org_academic_sessions_jnt`, `sch_school_profiles`

**Files to create:**

| Category | File(s) |
|---|---|
| Models | `CertificateRequest`, `CertificateIssued` |
| Controllers | `CertificateRequestController` (index, create, store, show, approve, reject), `CertificateIssuedController` (index, show, download, revoke, tcRegister), `VerificationController` (verify public + logs admin) |
| Services | `CertificateGenerationService` (full — all 14 steps), `QrVerificationService` (complete — verifyHash + sys_activity_logs) |
| Jobs | `BulkGenerateCertificatesJob` (stub — returns immediately; full in Phase 3) |
| FormRequests | `StoreCertificateRequestRequest`, `ApproveCertificateRequestRequest`, `RejectCertificateRequestRequest`, `RevokeCertificateRequest` |
| Policies | `CertificateRequestPolicy`, `CertificateIssuedPolicy` |
| Views | `requests/index.blade.php`, `requests/create.blade.php`, `requests/show.blade.php`, `issued/index.blade.php`, `issued/show.blade.php`, `public/verify.blade.php` |
| Routes | All 6 request routes + 5 issued routes + `/verify/{hash}` public route + API route |

**Tests to write:** `CertificateRequestWorkflowTest` (T07, T08), `CertificateGenerationTest` (T07 merge fields, T25), `QrVerificationTest` (T09, T10, T11, T23, T24, T30), `SerialCounterTest` (T27 — Unit)

**Estimated test count:** 20–25 feature tests + 3 unit tests

---

### Phase 3 — TC, Bulk Jobs, ID Cards

**FRs covered:** FR-CRT-005, FR-CRT-006, FR-CRT-008
**Cross-module deps:** `fin_*` tables (fee check — BR-CRT-001), `std_students.tc_issued` (written by migration)

**Files to create:**

| Category | File(s) |
|---|---|
| Models | `TcRegister`, `BulkJob`, `IdCardConfig` |
| Controllers | `BulkGenerationController` (full — generate + status JSON polling + ZIP download), `IdCardController` (full — 8 methods) |
| Services | `CertificateGenerationService::generateTC()` (complete — fee gate + tc_register + std_students write) |
| Jobs | `BulkGenerateCertificatesJob` (full — per-student loop, `error_log_json`, ZIP creation, `processed_count` update) |
| FormRequests | `BulkGenerateCertificatesRequest`, `StoreIdCardConfigRequest` |
| Policies | `BulkGenerationPolicy`, `IdCardPolicy` |
| Views | `bulk/generate.blade.php` (CRT-S13 — 3s polling), `id-cards/config-index.blade.php`, `id-cards/config-form.blade.php`, `id-cards/generate.blade.php`, `tc/register.blade.php` |
| Routes | 4 bulk routes + 8 ID card routes + `certificate.tc-register` |

**Tests to write:** `TcRegistrationTest` (T12, T13, T14), `BulkGenerationTest` (T15, T16, T17), `IdCardGenerationTest` (T18, T19)

**Estimated test count:** 12–15 feature tests

---

### Phase 4 — DMS, Reports, Portal, Artisan

**FRs covered:** FR-CRT-009, FR-CRT-011, FR-CRT-012
**Cross-module deps:** `sys_media`, `sys_dropdown_table`, student portal middleware

**Files to create:**

| Category | File(s) |
|---|---|
| Models | `StudentDocument` |
| Controllers | `DocumentManagementController` (full — 5 methods), `CertificateReportController` (issued + pending + analytics JSON), `Portal\CertificatePortalController` (index + create + store + show) |
| Services | `DmsService` (full — uploadDocument, verifyDocument, getDocumentsByStudent, hasVerifiedDocument) |
| Artisan | `app/Console/Commands/ExpireCertificates.php` — `certificate:expire-certificates` |
| FormRequests | `DocumentUploadRequest`, `VerifyDocumentRequest` |
| Policies | `DocumentManagementPolicy`, `CertificateReportPolicy` |
| Views | `dms/index.blade.php`, `dms/upload.blade.php`, `dms/show.blade.php`, `verification/logs.blade.php`, `reports/issued.blade.php`, `reports/pending.blade.php`, `reports/analytics.blade.php`, `portal/my-certificates.blade.php` |
| Routes | 5 document routes + 3 report routes + 4 portal routes |

**Tests to write:** `DmsTest` (T20, T21, T22), `CertificateReportTest` (T26, T28), `CertificatePortalTest` (T29)

**Estimated test count:** 10–12 feature tests

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed Certificate --class=CrtSeederRunner

  ↓ CrtCertificateTypeSeeder
    Inserts 5 certificate types (BON, TC, CHR, MRT, SPT)
    Upserts on ['code'] — safe to re-run
    No dependencies

  ↓ CrtTemplateSeeder
    Inserts 1 default template + 1 template_version per type (5 total)
    Depends on CrtCertificateTypeSeeder (looks up certificate_type_id by code)
    Skips if default template already exists for a type
```

**Minimum seeder for tests (Phase 1):**
```bash
php artisan module:seed Certificate --class=CrtCertificateTypeSeeder
```
Required for: any request, generation, serial counter, or verification test.

**Full seeder for Phase 2+ tests (PDF generation requires default template):**
```bash
php artisan module:seed Certificate --class=CrtSeederRunner
```

**Scheduled Artisan command** (register in `routes/console.php`):
```php
// routes/console.php
use Illuminate\Support\Facades\Schedule;

Schedule::command('certificate:expire-certificates')->dailyAtMidnight();
```

**`certificate:expire-certificates` behaviour:**
```
Finds all crt_issued_certificates WHERE:
  validity_date IS NOT NULL
  AND validity_date < TODAY
  AND is_revoked = 0
  AND is_active = 1
  AND deleted_at IS NULL

For each expired cert:
  → Logs expiry event to sys_activity_logs
  → Optionally: dispatch NTF event to student if cert expired today (Suggestion S05)
  → Does NOT set is_revoked — expiry is determined dynamically from validity_date
```

---

## Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

### 8.1 Feature Test Setup

```php
// All feature test files
uses(Tests\TestCase::class, RefreshDatabase::class);

// Standard fakes per test file
Queue::fake();       // BulkGenerateCertificatesJob — BulkGenerationTest
Event::fake();       // CertificateGenerated, CertificateRequestApproved — GenerationTest
Storage::fake();     // PDF file storage + DMS uploads — GenerationTest, DmsTest
Http::fake();        // (none needed — all generation is internal)

// fin_* fee check mock (for TC tests — no fin_* tables in test DB)
// Option A: Mock fin_fee_dues query in CertificateGenerationService
// Option B: Bind a stub FinFeeService that returns configurable amount
// Recommended: use Option A with partial mock or spy:
//   $this->mock(CertificateGenerationService::class)
//        ->makePartial()
//        ->shouldReceive('checkFeeDues')->andReturn(0); // or > 0
```

### 8.2 Feature Test Files (8 files, T01–T30 coverage)

| File | Path | Test Cases | T-series |
|---|---|---|---|
| `CertificateTypeTest` | `tests/Feature/Certificate/CertificateTypeTest.php` | Create type with unique code; duplicate code rejected; toggleStatus; soft delete + restore | T01, T02 |
| `CertificateTemplateTest` | `tests/Feature/Certificate/CertificateTemplateTest.php` | Create + preview renders PDF; save archives version; restore old version; default toggle (BR-CRT-012) | T03, T04, T05, T06 |
| `CertificateRequestWorkflowTest` | `tests/Feature/Certificate/CertificateRequestWorkflowTest.php` | Submit → approve → generate pipeline; duplicate pending request blocked; requires_approval=0 auto-approves; portal own-records-only | T07, T08, T29 |
| `CertificateGenerationTest` | `tests/Feature/Certificate/CertificateGenerationTest.php` | Merge fields resolved correctly; verification_hash generated; PDF stored at correct path; duplicate watermark (is_duplicate=true) | T07, T25 |
| `QrVerificationTest` | `tests/Feature/Certificate/QrVerificationTest.php` | QR resolves to valid page; revoked cert → REVOKED banner; privacy DTO (no full name/DOB/class); API valid JSON; API unauthorised 401; revoked cert download blocked | T09, T10, T11, T23, T24, T30 |
| `TcRegistrationTest` | `tests/Feature/Certificate/TcRegistrationTest.php` | Fee gate blocks TC; admin override allows TC; sl_no increments sequentially (3 concurrent); std_students.tc_issued=1 after TC; std_students.current_status_id=Withdrawn | T12, T13, T14 |
| `BulkGenerationTest` | `tests/Feature/Certificate/BulkGenerationTest.php` | 50-student batch synchronous; 201-student batch → Queue::assertPushed(); per-student failure logged; ZIP downloadable on complete | T15, T16, T17 |
| `DmsTest` | `tests/Feature/Certificate/DmsTest.php` | Upload PDF + image; category selectable; verified/rejected status update; rejected doc cannot satisfy TC eligibility (BR-CRT-008) | T20, T21, T22 |

**Additional feature test files:**
| File | Test Cases | T-series |
|---|---|---|
| `IdCardGenerationTest` | ID card with photo; blood group present/absent (BR-CRT-007); mark received | T18, T19 |
| `CertificateReportTest` | Export CSV generates valid file; analytics JSON structure correct | T26, T28 |
| `CertificatePortalTest` | Student sees only own certificates; cannot view other student's records | T29 |

### 8.3 Unit Test Files (3 files)

| File | Path | Scenarios | T-series |
|---|---|---|---|
| `SerialCounterTest` | `tests/Unit/Certificate/SerialCounterTest.php` | `SELECT FOR UPDATE` — concurrent calls produce unique sequential numbers; format token expansion (`{SEQ4}`, `{SEQ6}`, `{TYPE_CODE}`, `{YYYY}`, `{YY}`); counter resets per year (new row created for new year) | T27 |
| `QrVerificationServiceTest` | `tests/Unit/Certificate/QrVerificationServiceTest.php` | Hash generation deterministic (same inputs → same output); hash changes if any input changes; `verifyHash()` returns VALID/EXPIRED/REVOKED/NOT_FOUND correctly; QR code output is valid base64 PNG |  |
| `MergeFieldResolverTest` | `tests/Unit/Certificate/MergeFieldResolverTest.php` | All 17 merge fields resolve correctly from mock student/profile data; `{{student_name}}` = first + middle + last name concatenation; NULL `blood_group` → empty string (not null/error); `{{academic_session}}` resolves from `sch_org_academic_sessions_jnt.name` |  |

### 8.4 Policy Test

| File | Scenarios |
|---|---|
| `CertificatePolicyTest` | Student can request own cert; Student cannot view other students' certs (FR-CRT-012 privacy); Principal can approve TC; Clerk can create request but cannot revoke; Admin can revoke; Class Teacher can view own class certs only |

### 8.5 Factory Requirements

```php
// Modules/Certificate/database/factories/CertificateTypeFactory.php
CertificateTypeFactory::new()->make([
    'code' => strtoupper(Str::random(5)),  // unique alphanumeric ≤ 10
    'category' => fake()->randomElement(['administrative','legal','character','achievement','identity']),
    'requires_approval' => fake()->boolean(),
    'serial_format' => '{TYPE_CODE}-{YYYY}-{SEQ6}',
    'created_by' => 1, 'updated_by' => 1,
]);

// Modules/Certificate/database/factories/CertificateTemplateFactory.php
CertificateTemplateFactory::new()->make([
    'template_content' => '<html><body>Hello {{student_name}} from {{school_name}} on {{issue_date}} — {{certificate_no}}</body></html>',
    'variables_json' => json_encode(['student_name','school_name','issue_date','certificate_no']),
    'page_size' => 'a4', 'orientation' => 'portrait', 'is_default' => 1, 'version_no' => 1,
    'created_by' => 1, 'updated_by' => 1,
]);

// Modules/Certificate/database/factories/CertificateRequestFactory.php
CertificateRequestFactory::new()->make([
    'request_no' => 'REQ-' . date('Y') . '-' . str_pad(fake()->unique()->randomNumber(6), 6, '0', STR_PAD_LEFT),
    'requester_type' => 'admin',
    'status' => 'pending',
    'created_by' => 1, 'updated_by' => 1,
]);

// Modules/Certificate/database/factories/CertificateIssuedFactory.php
CertificateIssuedFactory::new()->make([
    'certificate_no' => 'BON-' . date('Y') . '-' . str_pad(fake()->unique()->randomNumber(6), 6, '0', STR_PAD_LEFT),
    'verification_hash' => hash('sha256', Str::random(64)),  // placeholder (not real HMAC)
    'issue_date' => today(),
    'is_revoked' => 0, 'is_duplicate' => 0,
    'created_by' => 1, 'updated_by' => 1,
]);
```

### 8.6 BR Coverage in Tests

| Business Rule | Test File | Assertion |
|---|---|---|
| BR-CRT-001 (TC fee gate) | `TcRegistrationTest` | `fin_fee_dues > 0` → `FeeOutstandingException` thrown; admin override → TC generated |
| BR-CRT-002 (TC sl_no sequential) | `TcRegistrationTest` | 3 TCs generated → `crt_tc_register.sl_no` = 1, 2, 3 with no gaps |
| BR-CRT-003 (duplicate watermark) | `CertificateGenerationTest` | Second issuance → `assertDatabaseHas('crt_issued_certificates', ['is_duplicate' => 1])` |
| BR-CRT-005 (REVOKED not 404) | `QrVerificationTest` | `$this->get('/verify/{hash}')` for revoked cert → HTTP 200, response contains 'REVOKED' |
| BR-CRT-008 (rejected DMS) | `DmsTest` | Rejected doc → `DmsService::hasVerifiedDocument()` returns false |
| BR-CRT-009 (> 200 → queue) | `BulkGenerationTest` | 201 students → `Queue::assertPushed(BulkGenerateCertificatesJob::class)` |
| BR-CRT-010 (privacy) | `QrVerificationTest` | Response text does NOT contain full `$student->last_name`, `$student->dob`, class section |
| BR-CRT-011 (TC → std_students) | `TcRegistrationTest` | `assertDatabaseHas('std_students', ['id' => $studentId, 'tc_issued' => 1])` |
| BR-CRT-015 (SELECT FOR UPDATE) | `SerialCounterTest` | Concurrent calls via async jobs → unique sequential numbers (no collisions) |

---

## Phase 3 Quality Gate — Self-Check

- [x] All 9 controllers listed with all methods
- [x] All 3 services listed with at minimum 3 key method signatures each
- [x] `CertificateGenerationService` 14-step pseudocode present
- [x] `QrVerificationService::incrementSerialCounter()` 5-step SELECT FOR UPDATE pseudocode present
- [x] All 10 FormRequests listed with key validation rules
- [x] All 12 FRs (CRT-001 to CRT-012) appear in at least one implementation phase
- [x] All 4 implementation phases have: FRs covered, files to create, test count
- [x] Seeder execution order documented with dependency note (TypeSeeder before TemplateSeeder)
- [x] Artisan command `certificate:expire-certificates` listed with daily schedule
- [x] Route list consolidated with middleware and FR reference (60 routes total) ✅
- [x] Public `/verify/{hash}` route explicitly marked with NO auth middleware
- [x] View count per sub-module totals 30 ✅
- [x] Test strategy includes `Queue::fake()` for `BulkGenerateCertificatesJob`
- [x] Test strategy includes `Storage::fake()` for PDF + DMS file tests
- [x] BR-CRT-001 (TC fee gate) test explicitly referenced
- [x] BR-CRT-010 (public verification privacy) test explicitly referenced
- [x] BR-CRT-015 (SELECT FOR UPDATE serial counter) test explicitly referenced
