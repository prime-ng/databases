# ParentPortal — Document Vault & Requests (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Document Vault & Requests |
| **Alias** | ppt_document_requests |
| **Module** | ParentPortal (PPT) |
| **Route Prefix** | `/parent-portal/documents` |
| **Primary Controller** | `ParentDocumentController` |
| **Primary Model** | `ParentDocumentRequest` |
| **Base Table** | `ppt_document_requests` |
| **FRD Reference** | REQ-PPT-016 |
| **Priority** | P1 (Should Have) |
| **Type** | Write (Parent submits requests; Admin processes) |

## 2. Purpose

Provide parents with a unified **Document Vault** where they can view their child's published official documents (report cards, certificates) and make online **Duplicate Certificate Requests** for commonly required school documents. The feature supports fee-based requests (via Razorpay) and tracks the request through a five-state lifecycle.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-011 | Fulfilled document download requires Razorpay payment when `fee_required > 0` | `ParentDocumentController::download()` — checks `isDownloadable()` |
| BR-PPT-022 | Document download link generates on-demand; 24-hour expiry enforced via `response()->download()` (no signed URL in current implementation) | `ParentDocumentController::download()` |
| BR-PPT-001 | All documents and requests scoped to parent's linked active child | `ParentContextService::resolveChild()` + `abort_unless()` checks |
| — | Request reason must be minimum 20 characters | `StoreParentDocumentRequest::rules()` — `min:20` |
| — | Only Pending requests may be withdrawn | `ParentDocumentRequest::isWithdrawable()` — checks status == Pending |
| — | Download only allowed when status is Ready/Completed AND fee paid (if applicable) | `ParentDocumentRequest::isDownloadable()` |
| — | Request number auto-generated: `PPT-DR-YYYY-XXXXXXXX` | `ParentDocumentController::store()` |

## 4. Status Workflow (FSM)

```
[Submitted] → Pending → Processing → Ready (if fee_required > 0 → requires payment)
                                    → Completed (fee_required = 0 auto-completes)
           → Rejected (from any active state)
           → Withdrawn (from Pending only)
```

**Terminal states:** Completed, Rejected, Withdrawn

| Transition | From | To | Guard | Action |
|-----------|------|-----|-------|--------|
| Submit | — | Pending | reason >= 20 chars; child ownership | Request number generated; admin notified |
| Process | Pending | Processing | Admin action | Status updated |
| Fulfill (free) | Processing | Completed | fee_required = 0 | Upload document; parent notified |
| Fulfill (fee) | Processing | Ready | fee_required > 0 | Parent notified to pay |
| Pay | Ready | Completed | Payment verified | Download URL generated |
| Reject | Any active | Rejected | admin_notes required | Parent notified with reason |
| Withdraw | Pending | Withdrawn | Status = Pending | Soft-delete; is_active = false |

## 5. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Document Vault + Request List | `parent-portal.documents.index` | `index()` | `documents/index` | Tabbed view: vault docs + request history |
| New Document Request Form | `parent-portal.documents.create` | `create()` | `documents/create` | Document type, reason, urgency |
| Store Request | `parent-portal.documents.store` | `store()` | — (redirect) | POST handler |
| Request Status | `parent-portal.documents.show` | `show()` | `documents/show` | Single request detail with timeline |
| Withdraw Request | `parent-portal.documents.withdraw` | `withdraw()` | — (redirect) | POST — soft-deletes |
| Pay Initiate | `parent-portal.documents.pay.initiate` | `payInitiate()` | — (JSON) | Creates Razorpay order |
| Pay Callback | `parent-portal.documents.pay.callback` | `payCallback()` | — (JSON) | Verifies signature; marks fee paid |
| Download Document | `parent-portal.documents.download` | `download()` | — (file response) | Streams file if downloadable |

## 6. Validation Rules

### StoreParentDocumentRequest

| Field | Rule | Note |
|-------|------|------|
| `document_type` | `required`, `string`, `in:TC,MarkSheet,Bonafide,Character,Migration,MedicalFitness,Other` | Must match `DOCUMENT_TYPES` keys |
| `reason` | `required`, `string`, `min:20`, `max:2000` | Minimum 20 chars |
| `urgency` | `required`, `in:Normal,Urgent` | Default: Normal |

### PayCallbackParentDocumentRequest

| Field | Rule |
|-------|------|
| `payment_ulid` | `required`, `string` |
| `razorpay_payment_id` | `required`, `string` |
| `razorpay_order_id` | `required`, `string` |
| `razorpay_signature` | `required`, `string` |

## 7. Technical Implementation

### 7.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\StudentProfile\Models\Student` | Model | FK — student_id |
| `Modules\StudentProfile\Models\Guardian` | Model | FK — guardian_id |
| `Modules\Prime\Models\Media` | Model | FK — fulfilled_media_id |
| `Modules\Payment\Services\PaymentService` | Service | Razorpay order initiation + verification |
| `Modules\Payment\Services\GatewayManager` | Service | Gateway resolution |
| `Modules\Payment\Contracts\Payable` | Contract | Enables PaymentService integration |
| `ParentContextService` | Service | Resolves active child |
| `Spatie\MediaLibrary\HasMedia` | Package | Media file handling |

### 7.2 Key Implementation Details

- **Request Number Generation:** `PPT-DR-{YYYY}-{XXXXXXXX}` — sequence resets yearly. Uses `LOCK FOR UPDATE` on the last request number to prevent race conditions.
- **Payment Flow:** `PaymentService::initiate()` creates a Payment record with payable_type=`ParentDocumentRequest`. On callback, `GatewayManager::resolve('razorpay')` verifies the signature. If verified, `PaymentService::markSuccess()` updates payment status and `fee_paid=true` is set.
- **Download Guard:** `isDownloadable()` checks three conditions: status in [Ready, Completed], fulfilled_media_id not null, and not requiresPayment(). If status is Ready on download, it transitions to Completed.
- **Cross-DB Media:** Uses `Modules\Prime\Models\Media::find()` (cross-database) to locate the fulfilled document file. Returns `response()->download()` directly (not temporary signed URL).
- **Child Ownership:** Verified via `abort_unless($documentRequest->student_id === $child->id, 403)` on show, withdraw, payInitiate, payCallback, and download methods.

### 7.3 Document Types Available

| Value | Label |
|-------|-------|
| TC | Transfer Certificate |
| MarkSheet | Mark Sheet |
| Bonafide | Bonafide Certificate |
| Character | Character Certificate |
| Migration | Migration Certificate |
| MedicalFitness | Medical Fitness Certificate |
| Other | Other |

## 8. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| Request submitted without child session | `ParentPortalBaseRequest::authorize()` returns false → 403 |
| Withdraw an already processed request | `abort(422)` — "This request can no longer be withdrawn." |
| Download before payment | `abort(422)` — "Document is not yet available for download." |
| Payment callback for already paid request | Returns 422 — "Fee already paid." |
| Duplicate Razorpay payment_id | Unique constraint on `payment_reference` (DB-level idempotency) |
| Fulfilled media deleted from sys_media | `abort(404)` — "Fulfilled document not found." |
| Year rollover (December → January) | Sequence resets to 1 for new year |
| Concurrent request number race | `lockForUpdate()` prevents duplicate request numbers |

## 9. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | FRD mentions 24-hour signed temporary URL (`Storage::temporaryUrl`), but controller uses `response()->download()` directly — no expiry enforcement | Medium | ⬜ |
| 2 | Download link expiry not implemented — once user downloads, file remains accessible indefinitely | Medium | ⬜ |
| 3 | No explicit Gate/Policy for document ownership — uses inline `abort_unless()` checks | Low | ⬜ |
| 4 | HPC report cards shown in vault; these belong to HPC module, not directly to Document Vault feature | Low | ⬜ |
| 5 | PaymentService dependency: actual fee_amount set to 0.00 always in store(); admin must update fee_required via admin panel | Medium | ⬜ |
| 6 | No notification dispatch on status change (FRD says parent notified at each status change) | Medium | ⬜ |

## 10. Cross-Module Impact

| Module | Impact |
|--------|--------|
| Payment | Document fee payments use PaymentService and Razorpay Gateway |
| Hpc | HPC report cards displayed in vault section |
| StudentProfile | Guardian and Student FK dependencies |
| Prime (System) | Media storage for fulfilled documents |
| Notification | Should dispatch status change notifications (not yet implemented) |

## 11. Route Reference

```php
Route::prefix('documents')->name('documents.')->group(function () {
    Route::get('/', [ParentDocumentController::class, 'index'])->name('index');
    Route::get('/create', [ParentDocumentController::class, 'create'])->name('create');
    Route::post('/', [ParentDocumentController::class, 'store'])->name('store');
    Route::get('/{documentRequest}', [ParentDocumentController::class, 'show'])->name('show');
    Route::post('/{documentRequest}/withdraw', [ParentDocumentController::class, 'withdraw'])->name('withdraw');
    Route::post('/{documentRequest}/pay/initiate', [ParentDocumentController::class, 'payInitiate'])->name('pay.initiate');
    Route::post('/{documentRequest}/pay/callback', [ParentDocumentController::class, 'payCallback'])->name('pay.callback');
    Route::get('/{documentRequest}/download', [ParentDocumentController::class, 'download'])->name('download');
});
```

## 12. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
→ EnsureTenantHasModule (for parent-portal routes)
```

## 13. Controller Constructor Dependencies

```php
public function __construct(
    private readonly ParentContextService $context,
    private readonly PaymentService $paymentService,
    private readonly GatewayManager $gatewayManager,
) {}
```

## 14. Audit Logging

Every controller method logs an activity via `activityLog()` with:
- Event type: `Viewed`, `Requested`, `Withdrawn`, `PaymentInitiated`, `PaymentFailed`, `Paid`, `Downloaded`
- Context: student_id, student_name, module, route
- Entity reference: document_request_id, request_number, document_type

## 15. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (access another child's request) | `abort_unless($documentRequest->student_id === $child->id, 403)` on every sensitive action |
| CSRF | Laravel CSRF middleware on all POST routes |
| Payment signature forgery | Razorpay signature verified server-side via GatewayManager |
| Payment idempotency | DB unique constraint on `payment_reference` |
| Unauthenticated download | Route behind `auth` middleware |

## 16. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "Download link expires after 24 hours" | Uses `response()->download()` — no expiry | No temporary URL mechanism |
| "Parent notified at each status change" | No notification dispatch in controller | Missing Notification integration |
| "Fee-required documents blocked for download until payment confirmed" | Implemented via `isDownloadable()` | Partially met |
| "Parent can download report cards from vault" | HPC report cards shown; not certificate module docs | Partial vault |
