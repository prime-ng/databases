# Verification Logs & Public Portal — Requirement Document

## 1. Screen Purpose & Overview

The **Digital Verification** system allows third parties (such as employers, universities, or embassies) to verify the authenticity of issued certificates. 

Every printed certificate features a unique QR code. Scanning it opens a public, no-login verification endpoint `/verify/{hash}` showing if the document is VALID, EXPIRED, or REVOKED. 

Administrators audit these scans via the **Verification Logs** screen to monitor verification activity and identify fraudulent validation attempts.

---

## 2. Common Business Use Cases

1. **Third-Party Verification Scan**: A university admission office scans the QR code on a student's study certificate. The system displays a confirmation screen showing the matching issue date and validity status without requesting login.
2. **Flagging Fake Verification**: A bad actor tries to guess a hash or scans a modified QR code. The verification fails with `NOT_FOUND` and logs their IP address for analysis.
3. **Auditing API Checks**: An automated background check company queries the certificate database via REST API. The system verifies their API key, confirms validity, and logs the API event.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `crt_issued_certificates` (to read data) and `sys_activity_logs` (to write audit logs)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).
*   **Audit Logger Entry Structure (`sys_activity_logs`)**:
    *   `action` = `'certificate_verification'` or `'certificate_verify'`
    *   `model_type` = `Modules\Certificate\app\Models\CrtIssuedCertificate`
    *   `model_id` = ID of the target certificate (or `NULL` if not found)
    *   `properties` = JSON content mapping:
        *   `method`: `'qr'` or `'api'`
        *   `result`: `'VALID'`, `'EXPIRED'`, `'REVOKED'`, or `'NOT_FOUND'`
        *   `ip`: IP address of the requester
        *   `user_agent`: Browser header signature

---

## 4. Screen Fields & Input Rules

### Public Page `/verify/{hash}` (No auth required)
*   **Input**: URL variable `{hash}` (64-character HMAC-SHA256 hex string).
*   **Privacy DTO Constraint (BR-CRT-010)**:
    *   **Allowed Fields**: Certificate type, issued-to display name (concatenated `first_name` + last initial only e.g. `Aarav M.`), school name, issue date, validity status.
    *   **Prohibited Fields**: Full last name, date of birth, class/section, address, parent's names, or contact numbers must NOT be exposed.

### Admin Logs `/certificate/verification-logs`
*   **Filter Date Range**: Start Date and End Date.
*   **Filter Method**: Dropdown: All, QR Scan, API Call.
*   **Filter Status**: Dropdown: All, Valid, Expired, Revoked, Not Found.

---

## 5. Business Logic & Validation Policies

1. **Public Rate Limiting**:
   * To prevent brute-force hash scanning, the public `/verify/{hash}` route must use rate-limiting middleware: `throttle:20,60` (limiting to 20 request checks per IP address per hour).
2. **API Verification Authentication (BR-CRT-007)**:
   * REST endpoint `GET /api/v1/certificate/verify` requires query parameter `api_key`.
   * The API key must match the hashed key configured in the tenant setup.
   * If key is missing or invalid, returns HTTP 401: `{"error": "Unauthorized API access"}`.
3. **Revocation vs. Expiry Check Order**:
   * When lookup executes:
     * Check if certificate is not found $\to$ result = `'NOT_FOUND'`.
     * Check if `is_revoked = 1` $\to$ result = `'REVOKED'` (BR-CRT-005 — return HTTP 200, do NOT throw 404).
     * Check if `validity_date` is in past $\to$ result = `'EXPIRED'`.
     * Else $\to$ result = `'VALID'`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Scan the QR code on a generated certificate, or copy its verification hash from database.
* Log in as Administrator to view admin logs.

### Scenario A: Public Verification Success (Happy Path)
1. Navigate to `/verify/d6f932ab18b871c89012a873891d1e43e2e...` (valid hash).
2. **Expected Result**: 
   * Page loads. Banner displays: **VALID CERTIFICATE** (Green background).
   * Details shown: Bonafide Certificate, issued to `Rahul S.`, Delhi Public School, issued on `27 Mar 2026`.
   * Verify that full name `Rahul Sharma` or DOB are not exposed.
   * Database check: `sys_activity_logs` logs action `certificate_verification`, status `VALID`, method `qr`.

### Scenario B: Public Verification Revoked
1. Navigate to verification URL of a certificate that has been revoked.
2. **Expected Result**:
   * Banner displays: **REVOKED CERTIFICATE** (Red background).
   * Status lists date and reason of revocation.

### Scenario C: Admin Logs View
1. Navigate to `/certificate/verification-logs`.
2. Filter status: `VALID`. Click Filter.
3. **Expected Result**:
   * Listing table displays the scan event from Scenario A, showing IP, user-agent, date, and method `QR`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **Public URL/Route**: `/verify/{hash}`
* **Logs URL/Route**: `/certificate/verification-logs`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->visit('/verify/'.$this->testHash)
            ->assertSee('VALID CERTIFICATE')
            ->assertSee('Rahul S.')
            ->assertDontSee('Rahul Sharma') // Privacy check
            ->assertDontSee('2015-08-12'); // DOB hidden check
});
```

### 3. API Unauthorized Dusk Test Flow
```php
// Requesting verification endpoint without API Key
$response = $this->getJson('/api/v1/certificate/verify?hash='.$this->testHash);
$response->assertStatus(401)
         ->assertJsonFragment(['error' => 'Unauthorized API access']);
```
